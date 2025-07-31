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

	-- Calculate region bounds
	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2
	
	print("🔍 Region bounds - Min:", minPoint, "Max:", maxPoint)
	print("🔍 Expected iterations - X:", math.ceil((maxPoint.X - minPoint.X) / 12), 
		"Y:", math.ceil((maxPoint.Y - minPoint.Y) / 12), 
		"Z:", math.ceil((maxPoint.Z - minPoint.Z) / 12))

	-- Sample points for potential chambers
	local sampleStep = 12 -- studs between samples
	local chamberCount = 0

	local sampleCount = 0
	local totalExpectedSamples = math.ceil((maxPoint.X - minPoint.X) / sampleStep) * 
								math.ceil((maxPoint.Y - minPoint.Y) / sampleStep) * 
								math.ceil((maxPoint.Z - minPoint.Z) / sampleStep)
	print("🔍 Total expected samples:", totalExpectedSamples)
	
	for x = minPoint.X, maxPoint.X, sampleStep do
		for y = minPoint.Y, maxPoint.Y, sampleStep do
			for z = minPoint.Z, maxPoint.Z, sampleStep do
				sampleCount = sampleCount + 1
				
				-- Yield periodically to prevent hanging
				if sampleCount % 20 == 0 then
					task.wait()
					print("🔍 Sampled", sampleCount, "/", totalExpectedSamples, "locations for chambers...")
				end
				
				-- Use Worley noise to identify chamber locations
				local success, chamberNoise = pcall(function()
					return Core.getNoise3D(
						x * noiseConfig.scale,
						y * noiseConfig.scale,
						z * noiseConfig.scale,
						"worley"
					)
				end)
				
				if not success then
					print("⚠️ Failed to get noise at position", x, y, z, ":", chamberNoise)
					continue
				end

				-- Chamber appears where Worley noise is low (cell centers)
				if chamberNoise < chamberConfig.densityThreshold then
					local position = Vector3.new(x, y, z)

					-- Determine chamber size with variation
					local success2, sizeNoise = pcall(function()
						return Core.getNoise3D(x * 0.05, y * 0.05, z * 0.05)
					end)
					
					if not success2 then
						print("⚠️ Failed to get size noise:", sizeNoise)
						continue
					end
					
					local baseSize = chamberConfig.minSize + 
						(chamberConfig.maxSize - chamberConfig.minSize) * (sizeNoise + 1) / 2

					-- Apply asymmetry with error handling
					local asymmetryX, asymmetryY, asymmetryZ = 1, 1, 1
					pcall(function()
						asymmetryX = 1 + (Core.getNoise3D(x * 0.1, y, z) * chamberConfig.asymmetryFactor)
						asymmetryY = 1 + (Core.getNoise3D(x, y * 0.1, z) * chamberConfig.heightVariation)
						asymmetryZ = 1 + (Core.getNoise3D(x, y, z * 0.1) * chamberConfig.asymmetryFactor)
					end)

					local size = Vector3.new(
						baseSize * asymmetryX,
						baseSize * asymmetryY,
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
					
					-- Sample points within the chamber
					local step = 2
					local voxelCount = 0
					for cx = position.X - radiusX, position.X + radiusX, step do
						for cy = position.Y - radiusY, position.Y + radiusY, step do
							for cz = position.Z - radiusZ, position.Z + radiusZ, step do
								voxelCount = voxelCount + 1
								
								-- Yield every 50 voxels to prevent hanging
								if voxelCount % 50 == 0 then
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
	local maxConnections = config.Tier1.passages.maxConnections or 3
	local timeoutPerPassage = config.Tier1.passages.timeoutPerPassage or 5

	local startTime = tick()

	for i, chamber1 in ipairs(chambers) do
		if passageCount >= 200 then -- Hard limit
			print("⚠️ Reached maximum passages limit")
			break
		end

		if tick() - startTime > 120 then -- 2 minute timeout for all passages
			print("⚠️ Passage generation timeout")
			break
		end

		local connections = 0

		for j, chamber2 in ipairs(chambers) do
			if i ~= j and connections < maxConnections then
				local distance = (chamber1.position - chamber2.position).Magnitude

				-- Only connect nearby chambers
				if distance < 50 and distance > 10 then
					local passageStart = tick()

					-- Simple straight-line passage with timeout
					local success, passage = pcall(function()
						local passageId = Core.generateId("passage")
						local width = config.Tier1.passages.width or 4

						-- Create simple straight path
						local direction = (chamber2.position - chamber1.position).Unit
						local pathLength = distance
						local stepSize = 2
						local path = {}

						for step = 0, pathLength, stepSize do
							if tick() - passageStart > timeoutPerPassage then
								error("Passage timeout")
							end

							local pathPos = chamber1.position + direction * step
							table.insert(path, pathPos)

							-- Yield occasionally
							if #path % 10 == 0 then
								wait()
							end
						end

						local passageData = {
							id = passageId,
							path = path,
							width = width,
							chamber1 = chamber1.id,
							chamber2 = chamber2.id,
							length = pathLength
						}

						-- Carve the passage
						for _, pos in ipairs(path) do
							for r = 0, width/2, 1 do
								for angle = 0, 2*math.pi, math.pi/4 do
									local offset = Vector3.new(
										math.cos(angle) * r,
										0,
										math.sin(angle) * r
									)

									for h = -width/2, width/2, 1 do
										local voxelPos = pos + offset + Vector3.new(0, h, 0)
										Core.setVoxel(voxelPos, true, Enum.Material.Air)
									end
								end
							end

							-- Yield more often during carving
							wait()
						end

						Core.addFeature({
							id = passageId,
							type = "passage",
							position = chamber1.position,
							properties = passageData
						})

						return passageData
					end)

					if success and passage then
						table.insert(passages, passage)
						passageCount = passageCount + 1
						connections = connections + 1

						if passageCount % 10 == 0 then
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