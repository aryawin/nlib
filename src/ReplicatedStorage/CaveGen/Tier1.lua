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
	local timeoutPerPassage = passageConfig.timeoutPerPassage or 5

	-- Validate chambers first
	if not chambers or #chambers < 2 then
		print("⚠️ Not enough chambers for passage generation")
		return {}
	end

	local startTime = tick()
	local totalTimeout = 120 -- 2 minutes max for all passages
	print("🔍 Attempting to connect", #chambers, "chambers with max", maxConnections, "connections each")

	-- Track connections to avoid duplicates
	local existingConnections = {}
	local connectionCounts = {}
	for _, chamber in ipairs(chambers) do
		connectionCounts[chamber.id] = 0
	end

	for i, chamber1 in ipairs(chambers) do
		if passageCount >= 100 then -- Reasonable limit
			print("⚠️ Reached maximum passages limit:", passageCount)
			break
		end

		if tick() - startTime > totalTimeout then
			print("⚠️ Passage generation timeout after", totalTimeout, "seconds")
			break
		end

		-- Skip if this chamber already has enough connections
		if connectionCounts[chamber1.id] >= maxConnections then
			continue
		end

		-- Find suitable connection targets
		for j, chamber2 in ipairs(chambers) do
			if i ~= j and connectionCounts[chamber1.id] < maxConnections and connectionCounts[chamber2.id] < maxConnections then
				
				-- Create unique connection key
				local connectionKey = i < j and (chamber1.id .. "_" .. chamber2.id) or (chamber2.id .. "_" .. chamber1.id)
				if existingConnections[connectionKey] then
					continue
				end

				local distance = (chamber1.position - chamber2.position).Magnitude

				-- Only connect chambers within reasonable distance
				if distance >= 10 and distance <= 100 then
					local passageStartTime = tick()
					
					local passageSuccess, passage = pcall(function()
						-- Generate passage with error handling
						local passageId = Core.generateId("passage")
						local width = math.max(passageConfig.minWidth, 
							math.min(passageConfig.maxWidth, 
								passageConfig.minWidth + math.random() * (passageConfig.maxWidth - passageConfig.minWidth)))

						-- Create path using Core.findPath with limited steps
						local maxPathSteps = math.min(30, math.max(10, math.floor(distance / 4)))
						local path = Core.findPath(chamber1.position, chamber2.position, maxPathSteps)
						
						if not path or #path < 2 then
							error("Path generation failed")
						end

						local passageData = {
							id = passageId,
							startPos = chamber1.position,
							endPos = chamber2.position,
							path = path,
							width = width,
							connections = {chamber1.id, chamber2.id}
						}

						-- Carve the passage with optimized algorithm
						local operationCount = 0
						for pathIndex, pos in ipairs(path) do
							if tick() - passageStartTime > timeoutPerPassage then
								print("⚠️ Passage carving timeout, continuing with partial passage")
								break
							end
							
							-- Skip some points for performance
							if pathIndex % 2 == 0 or pathIndex == 1 or pathIndex == #path then
								local radius = width / 2
								
								-- Simplified cylindrical carving
								local step = math.max(1, radius / 3) -- Adaptive step based on radius
								for r = 0, radius, step do
									for angle = 0, 2*math.pi, math.pi/4 do -- 8 angles
										local offset = Vector3.new(
											math.cos(angle) * r,
											0,
											math.sin(angle) * r
										)

										-- Carve cylindrical cross-section
										for h = -radius, radius, step do
											local voxelPos = pos + offset + Vector3.new(0, h, 0)
											Core.setVoxel(voxelPos, true, Enum.Material.Air)
											operationCount = operationCount + 1
											
											-- Yield periodically during carving
											if operationCount % 200 == 0 then
												task.wait()
											end
										end
									end
								end
							end
						end

						return passageData
					end)

					if passageSuccess and passage then
						table.insert(passages, passage)
						Core.addPassage(passage)
						passageCount = passageCount + 1
						
						-- Mark connection as existing
						existingConnections[connectionKey] = true
						connectionCounts[chamber1.id] = connectionCounts[chamber1.id] + 1
						connectionCounts[chamber2.id] = connectionCounts[chamber2.id] + 1
						
						-- Update chamber connections
						table.insert(chamber1.connections, chamber2.id)
						table.insert(chamber2.connections, chamber1.id)

						print("🌉 Created passage", passageCount, "connecting", chamber1.id, "to", chamber2.id, 
							"(distance:", string.format("%.1f", distance), "width:", string.format("%.1f", passage.width), ")")
					else
						print("⚠️ Failed to create passage between", chamber1.id, "and", chamber2.id, ":", tostring(passage))
					end
				end
			end
			
			-- Yield between chamber pairs
			if j % 5 == 0 then
				task.wait()
			end
		end
	end

	print("🌉 Passage generation complete:", {
		passagesGenerated = passageCount,
		timeElapsed = string.format("%.1f seconds", tick() - startTime),
		averageConnectionsPerChamber = #chambers > 0 and string.format("%.1f", passageCount * 2 / #chambers) or "0"
	})

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

	-- Validate input chambers
	if not chambers or #chambers == 0 then
		print("⚠️ No chambers available for shaft generation")
		return {}
	end

	for _, chamber in ipairs(chambers) do
		-- Probability check for shaft generation with error handling
		local shouldGenerateShaft = false
		pcall(function()
			shouldGenerateShaft = math.random() < shaftConfig.density
		end)
		
		if shouldGenerateShaft then
			local shaftSuccess, shaft = pcall(function()
				-- Determine shaft properties with fallback values
				local heightNoise = 0
				pcall(function()
					heightNoise = Core.getNoise3D(
						chamber.position.X * 0.05,
						chamber.position.Y * 0.05,
						chamber.position.Z * 0.05
					)
				end)
				
				local height = math.max(shaftConfig.minHeight, 
					math.min(shaftConfig.maxHeight,
						shaftConfig.minHeight + (shaftConfig.maxHeight - shaftConfig.minHeight) * 
						math.max(0, math.min(1, (heightNoise + 1) / 2))))

				-- Random angle variation from vertical with bounds checking
				local maxAngle = math.min(45, shaftConfig.angleVariation or 15) -- Clamp to reasonable range
				local angle = (math.random() - 0.5) * 2 * maxAngle

				-- Calculate shaft direction with validation
				local direction = Vector3.new(
					math.sin(math.rad(angle)),
					1, -- Mostly vertical
					0
				).Unit

				-- Calculate radius proportional to chamber size with validation
				local baseRadius = math.max(2, math.min(10, (chamber.size.X + chamber.size.Z) / 12))
				local radiusVariation = math.max(0.5, math.min(2.0, 1 + (math.random() - 0.5) * (shaftConfig.radiusVariation or 0.3)))
				local radius = baseRadius * radiusVariation

				local shaftData = {
					id = Core.generateId("shaft"),
					position = chamber.position,
					height = height,
					radius = radius,
					angle = angle,
					direction = direction
				}

				-- Carve the shaft with optimized algorithm and error handling
				local operationCount = 0
				local stepSize = math.max(1, radius / 4) -- Adaptive step size
				
				for h = 0, height, stepSize do
					local currentPos = chamber.position + direction * h

					-- Simplified cylindrical carving
					local radiusStep = math.max(1, radius / 5)
					for r = 0, radius, radiusStep do
						for angleStep = 0, 2*math.pi, math.pi/4 do -- 8 angles for circle
							local offset = Vector3.new(
								math.cos(angleStep) * r,
								0,
								math.sin(angleStep) * r
							)

							local voxelPos = currentPos + offset

							-- Add subtle wall roughness with error handling
							local roughness = 0
							pcall(function()
								roughness = Core.getNoise3D(
									voxelPos.X * 0.15,
									voxelPos.Y * 0.15,
									voxelPos.Z * 0.15
								) * 0.5
							end)

							if r <= radius + roughness then
								Core.setVoxel(voxelPos, true, Enum.Material.Air)
								operationCount = operationCount + 1
								
								-- Yield periodically
								if operationCount % 150 == 0 then
									task.wait()
								end
							end
						end
					end

					-- Yield after each height level
					if h % (stepSize * 5) == 0 then
						task.wait()
					end
				end

				return shaftData
			end)
			
			if shaftSuccess and shaft then
				table.insert(shafts, shaft)
				Core.addVerticalShaft(shaft)
				shaftCount = shaftCount + 1
				
				print("⬆️ Created vertical shaft", shaftCount, "at", chamber.position, 
					"height:", string.format("%.1f", shaft.height), "radius:", string.format("%.1f", shaft.radius))
			else
				print("⚠️ Failed to create vertical shaft for chamber at", chamber.position, ":", tostring(shaft))
			end
		end
	end

	print("⬆️ Vertical shaft generation complete:", {
		shaftsGenerated = shaftCount,
		totalChambers = #chambers,
		generationRate = string.format("%.1f%%", shaftCount / #chambers * 100)
	})

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
	local results = {
		chambers = {},
		passages = {},
		verticalShafts = {},
		generationTime = 0
	}

	-- Generate main chambers first with error handling
	local chamberSuccess, chambers = pcall(function()
		print("🏛️ Starting main chamber generation...")
		return generateMainChambers(region, config)
	end)
	
	if chamberSuccess and chambers then
		results.chambers = chambers
		print("🏛️ Main chambers generated successfully:", #chambers)
	else
		print("⚠️ Main chamber generation failed:", tostring(chambers))
		chambers = {}
		results.chambers = {}
	end

	-- Connect chambers with passages
	local passageSuccess, passages = pcall(function()
		print("🛤️ Starting passage generation...")
		return generatePassages(chambers, config)
	end)
	
	if passageSuccess and passages then
		results.passages = passages
		print("🛤️ Passages generated successfully:", #passages)
	else
		print("⚠️ Passage generation failed:", tostring(passages))
		results.passages = {}
	end

	-- Add vertical shafts to chambers
	local shaftSuccess, shafts = pcall(function()
		print("⬆️ Starting vertical shaft generation...")
		return generateVerticalShafts(chambers, config)
	end)
	
	if shaftSuccess and shafts then
		results.verticalShafts = shafts
		print("⬆️ Vertical shafts generated successfully:", #shafts)
	else
		print("⚠️ Vertical shaft generation failed:", tostring(shafts))
		results.verticalShafts = {}
	end

	local endTime = tick()
	results.generationTime = endTime - startTime

	print(string.format("✅ Tier 1 generation complete in %.3f seconds", results.generationTime))
	print(string.format("📊 Final results: %d chambers, %d passages, %d shafts", 
		#results.chambers, #results.passages, #results.verticalShafts))

	return results
end

return Tier1