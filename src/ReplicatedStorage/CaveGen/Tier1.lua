--[[
====================================================================================================
                                        CaveGen Tier 1
                            Foundation Features: Chambers, Passages, Shafts
====================================================================================================
]]

local Tier1 = {}

-- Dependencies
local Core = require(script.Parent.Core)

-- ================================================================================================
--                                    MAIN CHAMBERS
-- ================================================================================================

local function generateMainChambers(region, config)
	if not config.Tier1.mainChambers.enabled then
		print("🏛️ Main chambers disabled, skipping...")
		return {}
	end

	print("🏛️ Generating main chambers...")
	local chambers = {}
	local chamberConfig = config.Tier1.mainChambers
	local noiseConfig = config.Noise.chambers

	-- Calculate region bounds with validation
	local success, bounds = pcall(function()
		local minPoint = region.CFrame.Position - region.Size/2
		local maxPoint = region.CFrame.Position + region.Size/2
		
		-- Validate bounds
		if minPoint.X >= maxPoint.X or minPoint.Y >= maxPoint.Y or minPoint.Z >= maxPoint.Z then
			error("Invalid region bounds")
		end
		
		return {min = minPoint, max = maxPoint}
	end)
	
	if not success then
		print("⚠️ Failed to calculate region bounds:", bounds)
		return {}
	end
	
	local minPoint, maxPoint = bounds.min, bounds.max
	
	print("🔍 Region bounds - Min:", minPoint, "Max:", maxPoint)

	-- Optimized sampling with adaptive step size based on region size
	local regionVolume = region.Size.X * region.Size.Y * region.Size.Z
	local adaptiveSampleStep = math.max(12, math.min(24, regionVolume / 50000)) -- Adaptive based on volume
	
	print("🔍 Using adaptive sample step:", adaptiveSampleStep)

	local chamberCount = 0
	local sampleCount = 0
	local failedSamples = 0
	
	-- Calculate expected samples for progress tracking
	local totalExpectedSamples = math.ceil((maxPoint.X - minPoint.X) / adaptiveSampleStep) * 
								math.ceil((maxPoint.Y - minPoint.Y) / adaptiveSampleStep) * 
								math.ceil((maxPoint.Z - minPoint.Z) / adaptiveSampleStep)
	print("🔍 Total expected samples:", totalExpectedSamples)
	
	-- Add early termination for excessive sample counts
	if totalExpectedSamples > 10000 then
		print("⚠️ Sample count too high, increasing step size")
		adaptiveSampleStep = adaptiveSampleStep * 1.5
		totalExpectedSamples = math.ceil((maxPoint.X - minPoint.X) / adaptiveSampleStep) * 
							 math.ceil((maxPoint.Y - minPoint.Y) / adaptiveSampleStep) * 
							 math.ceil((maxPoint.Z - minPoint.Z) / adaptiveSampleStep)
		print("🔍 Adjusted samples:", totalExpectedSamples)
	end
	
	for x = minPoint.X, maxPoint.X, adaptiveSampleStep do
		for y = minPoint.Y, maxPoint.Y, adaptiveSampleStep do
			for z = minPoint.Z, maxPoint.Z, adaptiveSampleStep do
				sampleCount = sampleCount + 1
				
				-- More frequent yielding for stability
				if sampleCount % 5 == 0 then
					task.wait()
				end
				
				-- Progress reporting every 25 samples
				if sampleCount % 25 == 0 then
					print("🔍 Chamber sampling progress:", string.format("%.1f%% (%d/%d)", 
						(sampleCount / totalExpectedSamples) * 100, sampleCount, totalExpectedSamples))
				end
				
				-- Early termination if too many chambers already
				if chamberCount >= 50 then
					print("🔍 Chamber limit reached, stopping sampling")
					break
				end
				
				-- Use Worley noise to identify chamber locations with error handling
				local chamberNoise = 0
				local noiseSuccess = pcall(function()
					chamberNoise = Core.getNoise3D(
						x * noiseConfig.scale,
						y * noiseConfig.scale,
						z * noiseConfig.scale,
						"worley"
					)
				end)
				
				if not noiseSuccess then
					failedSamples = failedSamples + 1
					-- Use fallback noise calculation
					chamberNoise = (math.sin(x * 0.1) + math.cos(y * 0.1) + math.sin(z * 0.1)) / 3
					if failedSamples % 10 == 0 then
						print("⚠️ Using fallback noise, failed samples:", failedSamples)
					end
				end

				-- Chamber appears where Worley noise is low (cell centers)
				if chamberNoise < chamberConfig.densityThreshold then
					local chamberSuccess, chamber = pcall(function()
						local position = Vector3.new(x, y, z)

						-- Determine chamber size with variation and error handling
						local sizeNoise = 0
						pcall(function()
							sizeNoise = Core.getNoise3D(x * 0.05, y * 0.05, z * 0.05)
						end)
						
						local baseSize = chamberConfig.minSize + 
							(chamberConfig.maxSize - chamberConfig.minSize) * math.max(0, math.min(1, (sizeNoise + 1) / 2))

						-- Apply asymmetry with error handling and bounds checking
						local asymmetryX, asymmetryY, asymmetryZ = 1, 1, 1
						pcall(function()
							asymmetryX = math.max(0.5, math.min(2.0, 1 + (Core.getNoise3D(x * 0.1, y, z) * chamberConfig.asymmetryFactor)))
							asymmetryY = math.max(0.5, math.min(2.0, 1 + (Core.getNoise3D(x, y * 0.1, z) * chamberConfig.heightVariation)))
							asymmetryZ = math.max(0.5, math.min(2.0, 1 + (Core.getNoise3D(x, y, z * 0.1) * chamberConfig.asymmetryFactor)))
						end)

						local size = Vector3.new(
							baseSize * asymmetryX,
							baseSize * asymmetryY,
							baseSize * asymmetryZ
						)
						
						-- Validate chamber size
						if size.X < chamberConfig.minSize or size.Y < chamberConfig.minSize or size.Z < chamberConfig.minSize then
							error("Chamber too small")
						end
						if size.X > chamberConfig.maxSize * 2 or size.Y > chamberConfig.maxSize * 2 or size.Z > chamberConfig.maxSize * 2 then
							error("Chamber too large")
						end

						return {
							id = Core.generateId("chamber"),
							position = position,
							size = size,
							shape = "ellipsoid",
							connections = {},
							material = Enum.Material.Air,
							isMainChamber = true
						}
					end)
					
					if chamberSuccess and chamber then
						table.insert(chambers, chamber)
						Core.addChamber(chamber)
						chamberCount = chamberCount + 1
						
						-- Carve the chamber with error handling
						local carveSuccess = pcall(function()
							local chamberPos = chamber.position
							local chamberSize = chamber.size
							
							-- Optimized ellipsoid carving with better yielding
							local sampleStep = 2
							local operationCount = 0
							
							for dx = -chamberSize.X/2, chamberSize.X/2, sampleStep do
								for dy = -chamberSize.Y/2, chamberSize.Y/2, sampleStep do
									for dz = -chamberSize.Z/2, chamberSize.Z/2, sampleStep do
										-- Ellipsoid equation with bounds checking
										local normalizedX = dx / (chamberSize.X/2)
										local normalizedY = dy / (chamberSize.Y/2)
										local normalizedZ = dz / (chamberSize.Z/2)
										
										if normalizedX*normalizedX + normalizedY*normalizedY + normalizedZ*normalizedZ <= 1 then
											local voxelPos = chamberPos + Vector3.new(dx, dy, dz)
											Core.setVoxel(voxelPos, true, Enum.Material.Air)
											operationCount = operationCount + 1
											
											-- Yield more frequently during carving
											if operationCount % 100 == 0 then
												task.wait()
											end
										end
									end
								end
							end
						end)
						
						if not carveSuccess then
							print("⚠️ Failed to carve chamber at", chamber.position)
						end
						
						print("🏛️ Created chamber", chamberCount, "at", chamber.position, "size", chamber.size)
					end
				end
			end
		end
	end

	print("🏛️ Main chamber generation complete:", {
		chambersGenerated = chamberCount,
		samplesProcessed = sampleCount,
		failedSamples = failedSamples,
		successRate = string.format("%.1f%%", (sampleCount - failedSamples) / sampleCount * 100)
	})

	return chambers
end
						baseSize * asymmetryZ
					)

					local chamber = {
						id = Core.generateId("chamber"),
						position = position,
						size = size,
						shape = "ellipsoid",
						connections = {},
						material = Enum.Material.Air,
						isMainChamber = true
					}

					print("🏛️ Generated chamber at", position, "with size", size)
					table.insert(chambers, chamber)
					
					-- Add to Core with error handling
					pcall(function()
						Core.addChamber(chamber)
					end)
					
					chamberCount = chamberCount + 1

					-- Carve the chamber in terrain with error handling
					local radiusX = size.X / 2
					local radiusY = size.Y / 2
					local radiusZ = size.Z / 2

					print("🔨 Carving chamber at", position, "radii:", radiusX, radiusY, radiusZ)
					
					-- Sample points within the chamber (optimized step size)
					local step = math.max(2, math.min(radiusX, radiusY, radiusZ) / 8) -- adaptive step size
					local voxelCount = 0
					for cx = position.X - radiusX, position.X + radiusX, step do
						for cy = position.Y - radiusY, position.Y + radiusY, step do
							for cz = position.Z - radiusZ, position.Z + radiusZ, step do
								voxelCount = voxelCount + 1
								
								-- Yield every 25 voxels to prevent hanging (more frequent)
								if voxelCount % 25 == 0 then
									task.wait()
								end
								
								-- Ellipsoid equation
								local dx = (cx - position.X) / radiusX
								local dy = (cy - position.Y) / radiusY
								local dz = (cz - position.Z) / radiusZ

								if dx*dx + dy*dy + dz*dz <= 1 then
									-- Add some roughness with error handling
									local roughness = 0
									pcall(function()
										roughness = Core.getNoise3D(cx * 0.2, cy * 0.2, cz * 0.2) * 0.3
									end)
									
									if dx*dx + dy*dy + dz*dz <= 1 + roughness then
										-- Set voxel with error handling
										pcall(function()
											Core.setVoxel(Vector3.new(cx, cy, cz), true, Enum.Material.Air)
										end)
									end
								end
							end
						end

						-- Yield after each slice
						task.wait()
						
						if Core.recordVoxelProcessed then
							pcall(function()
								Core.recordVoxelProcessed()
							end)
						end
					end
					
					print("✅ Carved chamber", chamberCount, "with", voxelCount, "voxels processed")
				end
			end
		end
	end

	print("✅ Generated", chamberCount, "main chambers")
	return chambers
end

-- ================================================================================================
--                                    PASSAGES
-- ================================================================================================

local function generatePassages(chambers, config)
	if not config.Tier1.passages.enabled then
		print("🌉 Passages disabled, skipping...")
		return {}
	end

	print("🌉 Generating passages between chambers...")
	local passages = {}
	local passageCount = 0
	local passageConfig = config.Tier1.passages
	local maxConnections = passageConfig.maxConnections or 3
	local timeoutPerPassage = passageConfig.timeoutPerPassage or 3

	local startTime = tick()

	for i, chamber1 in ipairs(chambers) do
		if passageCount >= 50 then -- Reduced limit for better performance
			print("⚠️ Reached maximum passages limit")
			break
		end

		if tick() - startTime > 60 then -- 1 minute timeout for all passages
			print("⚠️ Passage generation timeout")
			break
		end

		local connections = 0

		for j, chamber2 in ipairs(chambers) do
			if i ~= j and connections < maxConnections then
				local distance = (chamber1.position - chamber2.position).Magnitude

				-- Only connect nearby chambers
				if distance < 80 and distance > 15 then -- increased range for better connectivity
					local passageStart = tick()

					-- Simple straight-line passage with timeout
					local success, passage = pcall(function()
						local passageId = Core.generateId("passage")
						local width = passageConfig.minWidth + math.random() * (passageConfig.maxWidth - passageConfig.minWidth)

						-- Create optimized straight path
						local direction = (chamber2.position - chamber1.position).Unit
						local pathLength = distance
						local stepSize = 4 -- increased step size for performance
						local path = {}

						for step = 0, pathLength, stepSize do
							if tick() - passageStart > timeoutPerPassage then
								error("Passage timeout")
							end

							local pathPos = chamber1.position + direction * step
							table.insert(path, pathPos)

							-- Less frequent yielding for performance
							if #path % 20 == 0 then
								wait()
							end
						end

						local passageData = {
							id = passageId,
							startPos = chamber1.position,
							endPos = chamber2.position,
							path = path,
							width = width,
							connections = {chamber1.id, chamber2.id}
						}

						-- Optimized passage carving with larger steps
						for i, pos in ipairs(path) do
							if i % 2 == 0 then -- Skip every other path point for performance
								local radius = width / 2
								
								-- Simpler cylindrical carving
								for r = 0, radius, 2 do -- larger step for radius
									for angle = 0, 2*math.pi, math.pi/3 do -- fewer angles
										local offset = Vector3.new(
											math.cos(angle) * r,
											0,
											math.sin(angle) * r
										)

										for h = -radius, radius, 2 do -- larger step for height
											local voxelPos = pos + offset + Vector3.new(0, h, 0)
											Core.setVoxel(voxelPos, true, Enum.Material.Air)
										end
									end
								end
							end

							-- Yield less frequently for performance
							if i % 10 == 0 then
								wait()
							end
						end

						Core.addPassage(passageData)

						return passageData
					end)

					if success and passage then
						table.insert(passages, passage)
						passageCount = passageCount + 1
						connections = connections + 1

						if passageCount % 5 == 0 then
							print("📊 Generated", passageCount, "passages...")
						end
					else
						-- Skip failed passages and continue
						print("⚠️ Skipped passage", i, "->", j, "(failed or timeout)")
					end
				end
			end
		end

		-- Yield after each chamber
		wait()
	end

	print("✅ Generated", passageCount, "passages in", tick() - startTime, "seconds")
	return passages
end

-- ================================================================================================
--                                    VERTICAL SHAFTS
-- ================================================================================================

local function generateVerticalShafts(chambers, config)
	if not config.Tier1.verticalShafts.enabled then
		print("⬆️ Vertical shafts disabled, skipping...")
		return {}
	end

	print("⬆️ Generating vertical shafts...")
	local shafts = {}
	local shaftConfig = config.Tier1.verticalShafts
	local shaftCount = 0

	for _, chamber in ipairs(chambers) do
		-- Probability check for shaft generation
		if math.random() < shaftConfig.density then
			-- Determine shaft properties
			local heightNoise = Core.getNoise3D(
				chamber.position.X * 0.05,
				chamber.position.Y * 0.05,
				chamber.position.Z * 0.05
			)
			local height = shaftConfig.minHeight + 
				(shaftConfig.maxHeight - shaftConfig.minHeight) * (heightNoise + 1) / 2

			-- Random angle variation from vertical
			local angle = (math.random() - 0.5) * 2 * shaftConfig.angleVariation

			-- Calculate shaft direction
			local direction = Vector3.new(
				math.sin(math.rad(angle)),
				1, -- Mostly vertical
				0
			).Unit

			local baseRadius = chamber.size.X / 6 -- Proportional to chamber size
			local radiusVariation = 1 + (math.random() - 0.5) * shaftConfig.radiusVariation
			local radius = baseRadius * radiusVariation

			local shaft = {
				id = Core.generateId("shaft"),
				position = chamber.position,
				height = height,
				radius = radius,
				angle = angle
			}

			table.insert(shafts, shaft)
			Core.addVerticalShaft(shaft)
			shaftCount = shaftCount + 1

			-- Carve the shaft
			local step = 2
			for h = 0, height, step do
				local currentPos = chamber.position + direction * h

				-- Carve cylindrical section
				for r = 0, radius, 1 do
					for a = 0, 2*math.pi, math.pi/6 do
						local offset = Vector3.new(
							math.cos(a) * r,
							0,
							math.sin(a) * r
						)

						local voxelPos = currentPos + offset

						-- Add wall roughness
						local roughness = Core.getNoise3D(
							voxelPos.X * 0.2,
							voxelPos.Y * 0.2,
							voxelPos.Z * 0.2
						) * 0.8

						if r <= radius + roughness then
							Core.setVoxel(voxelPos, true, Enum.Material.Air)
						end
					end
				end

				Core.recordVoxelProcessed()
			end
		end
	end

	print("✅ Generated", shaftCount, "vertical shafts")
	return shafts
end

-- ================================================================================================
--                                    MAIN GENERATION FUNCTION
-- ================================================================================================

function Tier1.generate(region, config)
	print("🥇 === TIER 1: FOUNDATION GENERATION ===")
	print("🔍 Region:", region.CFrame.Position, "Size:", region.Size)
	print("🔍 Config enabled - Chambers:", config.Tier1.mainChambers.enabled, 
		"Passages:", config.Tier1.passages.enabled, 
		"Shafts:", config.Tier1.verticalShafts.enabled)

	local startTime = tick()

	-- Generate main chambers first
	print("🏛️ About to generate main chambers...")
	local chambers = generateMainChambers(region, config)
	print("🏛️ Main chambers generated:", #chambers)

	-- Connect chambers with passages
	print("🛤️ About to generate passages...")
	local passages = generatePassages(chambers, config)
	print("🛤️ Passages generated:", #passages)

	-- Add vertical shafts to chambers
	print("⬆️ About to generate vertical shafts...")
	local shafts = generateVerticalShafts(chambers, config)
	print("⬆️ Vertical shafts generated:", #shafts)

	local endTime = tick()
	local generationTime = endTime - startTime

	print(string.format("✅ Tier 1 complete in %.3f seconds", generationTime))
	print(string.format("📊 Generated: %d chambers, %d passages, %d shafts", 
		#chambers, #passages, #shafts))

	return {
		chambers = chambers,
		passages = passages,
		verticalShafts = shafts,
		generationTime = generationTime
	}
end

return Tier1