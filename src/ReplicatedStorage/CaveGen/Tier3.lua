--[[
====================================================================================================
                                        CaveGen Tier 3
                    Micro-Features: Fracture Veins, Pinch Points, Seam Layers, etc.
====================================================================================================
]]

local Tier3 = {}

-- Dependencies
local Core = require(script.Parent.Core)

-- ================================================================================================
--                                    FRACTURE VEINS
-- ================================================================================================

local function generateFractureVeins(region, config)
	if not config.Tier3.fractureVeins.enabled then
		print("⚡ Fracture veins disabled, skipping...")
		return {}
	end

	print("⚡ Generating fracture veins...")
	local fractureVeins = {}
	local veinConfig = config.Tier3.fractureVeins
	local veinCount = 0

	-- Validate region
	if not region or not region.Size then
		print("⚠️ Invalid region for fracture vein generation")
		return {}
	end

	local success, bounds = pcall(function()
		local minPoint = region.CFrame.Position - region.Size/2
		local maxPoint = region.CFrame.Position + region.Size/2
		return {min = minPoint, max = maxPoint}
	end)
	
	if not success then
		print("⚠️ Failed to calculate region bounds:", bounds)
		return {}
	end

	local minPoint, maxPoint = bounds.min, bounds.max
	local startTime = tick()
	local maxVeins = 200 -- Reasonable limit
	local timeoutTotal = 60 -- 1 minute timeout

	-- Adaptive sampling based on region size
	local regionVolume = region.Size.X * region.Size.Y * region.Size.Z
	local adaptiveSampleStep = math.max(8, math.min(20, regionVolume / 100000))
	
	print("🔍 Using adaptive sample step for fracture veins:", adaptiveSampleStep)

	for x = minPoint.X, maxPoint.X, adaptiveSampleStep do
		if veinCount >= maxVeins then
			print("⚠️ Reached maximum fracture veins limit:", maxVeins)
			break
		end

		if tick() - startTime > timeoutTotal then
			print("⚠️ Fracture vein generation timeout")
			break
		end

		for y = minPoint.Y, maxPoint.Y, adaptiveSampleStep do
			for z = minPoint.Z, maxPoint.Z, adaptiveSampleStep do
				if veinCount >= maxVeins then
					break
				end

				local shouldGenerateVein = false
				pcall(function()
					shouldGenerateVein = math.random() < veinConfig.density
				end)

				if shouldGenerateVein then
					local veinSuccess, vein = pcall(function()
						local startPos = Vector3.new(x, y, z)

						-- Generate random direction with bias toward horizontal/vertical
						local directionType = math.random()
						local direction
						if directionType < 0.4 then
							-- Horizontal vein
							direction = Vector3.new(
								(math.random() - 0.5) * 2,
								0,
								(math.random() - 0.5) * 2
							).Unit
						elseif directionType < 0.8 then
							-- Vertical vein
							direction = Vector3.new(
								(math.random() - 0.5) * 0.3,
								(math.random() > 0.5) and 1 or -1,
								(math.random() - 0.5) * 0.3
							).Unit
						else
							-- Diagonal vein
							direction = Vector3.new(
								(math.random() - 0.5) * 2,
								(math.random() - 0.5) * 2,
								(math.random() - 0.5) * 2
							).Unit
						end

						-- Calculate perpendicular vector for zigzag motion with validation
						local perpendicular = Vector3.new(-direction.Z, 0, direction.X)
						if perpendicular.Magnitude < 0.1 then
							-- Fallback perpendicular for vertical directions
							perpendicular = Vector3.new(1, 0, 0)
						else
							perpendicular = perpendicular.Unit
						end

						-- Determine vein length with error handling
						local lengthNoise = 0
						pcall(function()
							lengthNoise = Core.getNoise3D(x * 0.1, y * 0.1, z * 0.1)
						end)
						
						local length = math.max(veinConfig.minLength,
							math.min(veinConfig.maxLength,
								veinConfig.minLength + (veinConfig.maxLength - veinConfig.minLength) * 
								math.max(0, math.min(1, (lengthNoise + 1) / 2))))

						-- Create zigzag path with validation
						local veinPath = {startPos}
						local currentPos = startPos
						local stepSize = math.max(0.5, length / 30) -- Adaptive step size

						for d = stepSize, length, stepSize do
							-- Add controlled zigzag motion
							local zigzagNoise = 0
							pcall(function()
								zigzagNoise = Core.getNoise3D(
									(startPos.X + d) * 0.2,
									(startPos.Y + d) * 0.2,
									(startPos.Z + d) * 0.2
								)
							end)

							-- Create perpendicular zigzag with bounds checking
							local zigzagIntensity = math.min(veinConfig.zigzagIntensity or 0.4, 2.0)
							local zigzagOffset = perpendicular * zigzagNoise * zigzagIntensity * 0.5 -- Reduced intensity

							local nextPos = currentPos + direction * stepSize + zigzagOffset
							table.insert(veinPath, nextPos)
							currentPos = nextPos

							-- Yield periodically
							if #veinPath % 10 == 0 then
								task.wait()
							end
						end

						-- Validate path was created
						if #veinPath < 2 then
							error("Vein path too short")
						end

						local veinData = {
							id = Core.generateId("vein"),
							startPos = startPos,
							path = veinPath,
							width = math.max(0.3, math.min(2.0, veinConfig.width or 0.5)),
							length = length,
							perpendicular = perpendicular
						}

						-- Carve the vein with optimized algorithm
						local operationCount = 0
						for pathIndex, pos in ipairs(veinPath) do
							-- Skip some path points for performance
							if pathIndex % 2 == 0 or pathIndex == 1 or pathIndex == #veinPath then
								local width = veinData.width
								
								-- Create thin crack with simplified algorithm
								local step = math.max(0.3, width / 4)
								for w = -width/2, width/2, step do
									for h = -width, width, step do
										local offset = veinData.perpendicular * w + Vector3.new(0, h, 0)
										Core.setVoxel(pos + offset, true, Enum.Material.Air)
										operationCount = operationCount + 1
										
										-- Yield periodically
										if operationCount % 50 == 0 then
											task.wait()
										end
									end
								end
							end
						end

						return veinData
					end)

					if veinSuccess and vein then
						table.insert(fractureVeins, vein)
						Core.addFeature({
							id = vein.id,
							type = "fracture_vein",
							position = vein.startPos,
							properties = vein
						})
						veinCount = veinCount + 1
						
						if veinCount % 10 == 0 then
							print("⚡ Generated", veinCount, "fracture veins...")
						end
					else
						print("⚠️ Failed to create fracture vein at", x, y, z, ":", tostring(vein))
					end
				end
			end
		end

		-- Yield between X slices
		if math.floor(x) % (adaptiveSampleStep * 3) == 0 then
			task.wait()
		end
	end

	print("⚡ Fracture vein generation complete:", {
		veinsGenerated = veinCount,
		timeElapsed = string.format("%.1f seconds", tick() - startTime),
		sampleStep = adaptiveSampleStep
	})

	return fractureVeins
end

-- ================================================================================================
--                                    PINCH POINTS
-- ================================================================================================

local function generatePinchPoints(passages, config)
	if not config.Tier3.pinchPoints.enabled then
		print("🔒 Pinch points disabled, skipping...")
		return {}
	end

	print("🔒 Generating pinch points...")
	local pinchPoints = {}
	local pinchConfig = config.Tier3.pinchPoints
	local pinchCount = 0

	for _, passage in ipairs(passages) do
		-- Check if passage has enough path points
		if #passage.path < 3 then
			continue -- Skip passages that are too short
		end

		if math.random() < pinchConfig.probability then
			-- Determine number of pinch points in this passage
			local numPinches = math.random(1, 3)

			for i = 1, numPinches do
				-- Select random position along passage (FIX: Ensure valid range)
				local minIndex = 2
				local maxIndex = #passage.path - 1

				if maxIndex <= minIndex then
					break -- Skip if passage is too short
				end

				local pathIndex = math.random(minIndex, maxIndex) -- FIXED LINE 153
				local pinchPos = passage.path[pathIndex]

				local pinchPoint = {
					id = Core.generateId("pinch"),
					position = pinchPos,
					passageId = passage.id,
					minWidth = pinchConfig.minWidth,
					transitionLength = pinchConfig.transitionLength,
					originalWidth = passage.width
				}

				table.insert(pinchPoints, pinchPoint)
				Core.addFeature({
					id = pinchPoint.id,
					type = "pinch_point",
					position = pinchPos,
					properties = pinchPoint
				})
				pinchCount = pinchCount + 1

				-- Modify the passage geometry at this point
				local transitionHalf = pinchConfig.transitionLength / 2

				-- Find affected path segments
				local startIndex = math.max(1, pathIndex - math.ceil(transitionHalf))
				local endIndex = math.min(#passage.path, pathIndex + math.ceil(transitionHalf))

				-- Create narrowing effect
				for j = startIndex, endIndex do
					local distanceFromPinch = math.abs(j - pathIndex)
					local widthMultiplier

					if distanceFromPinch <= transitionHalf then
						-- Smooth transition to minimum width
						local t = distanceFromPinch / transitionHalf
						widthMultiplier = pinchConfig.minWidth / passage.width + 
							(1 - pinchConfig.minWidth / passage.width) * t
					else
						widthMultiplier = 1
					end

					local pos = passage.path[j]
					local currentWidth = passage.width * widthMultiplier

					-- Re-carve this section with new width
					for r = 0, currentWidth/2, 0.5 do
						for angle = 0, 2*math.pi, math.pi/8 do
							local offset = Vector3.new(
								math.cos(angle) * r,
								0,
								math.sin(angle) * r
							)

							for h = -currentWidth/4, currentWidth/4, 0.5 do
								local finalPos = pos + offset + Vector3.new(0, h, 0)
								Core.setVoxel(finalPos, true, Enum.Material.Air)
							end
						end
					end
				end

				if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
			end
		end
	end

	print("✅ Generated", pinchCount, "pinch points")
	return pinchPoints
end

-- ================================================================================================
--                                    SEAM LAYERS
-- ================================================================================================

local function generateSeamLayers(region, config)
	if not config.Tier3.seamLayers.enabled then
		print("📚 Seam layers disabled, skipping...")
		return {}
	end

	print("📚 Generating seam layers...")
	local seamLayers = {}
	local seamConfig = config.Tier3.seamLayers
	local seamCount = 0

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	-- Generate horizontal seam layers
	for y = minPoint.Y, maxPoint.Y, seamConfig.layerSpacing do
		if math.random() < seamConfig.density then
			local baseY = y

			local seamLayer = {
				id = Core.generateId("seam"),
				baseY = baseY,
				thickness = seamConfig.thickness,
				region = region
			}

			table.insert(seamLayers, seamLayer)
			Core.addFeature({
				id = seamLayer.id,
				type = "seam_layer",
				position = Vector3.new(region.CFrame.Position.X, baseY, region.CFrame.Position.Z),
				properties = seamLayer
			})
			seamCount = seamCount + 1

			-- Carve thin horizontal cracks
			local step = 3
			for x = minPoint.X, maxPoint.X, step do
				for z = minPoint.Z, maxPoint.Z, step do
					-- Add horizontal variation
					local horizontalNoise = Core.getNoise3D(x * 0.05, baseY * 0.05, z * 0.05)
					local actualY = baseY + horizontalNoise * seamConfig.horizontalVariation

					-- Create thin horizontal crack
					for thickness = 0, seamConfig.thickness, 0.5 do
						local pos = Vector3.new(x, actualY + thickness - seamConfig.thickness/2, z)
						Core.setVoxel(pos, true, Enum.Material.Air)
					end

					if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
				end
			end
		end
	end

	print("✅ Generated", seamCount, "seam layers")
	return seamLayers
end

-- ================================================================================================
--                                    SHELF LAYERS
-- ================================================================================================

local function generateShelfLayers(chambers, config)
	if not config.Tier3.shelfLayers.enabled then
		print("📏 Shelf layers disabled, skipping...")
		return {}
	end

	print("📏 Generating shelf layers...")
	local shelfLayers = {}
	local shelfConfig = config.Tier3.shelfLayers
	local shelfCount = 0

	for _, chamber in ipairs(chambers) do
		if math.random() < shelfConfig.probability then
			-- Generate multiple shelf levels in the chamber
			local numShelves = math.random(2, 5)
			local chamberBottom = chamber.position.Y - chamber.size.Y/2
			local chamberTop = chamber.position.Y + chamber.size.Y/2

			for i = 1, numShelves do
				local shelfY = chamberBottom + (i / (numShelves + 1)) * chamber.size.Y

				local shelf = {
					id = Core.generateId("shelf"),
					chamberId = chamber.id,
					position = Vector3.new(chamber.position.X, shelfY, chamber.position.Z),
					depth = shelfConfig.shelfDepth,
					chamberSize = chamber.size
				}

				table.insert(shelfLayers, shelf)
				Core.addFeature({
					id = shelf.id,
					type = "shelf_layer",
					position = shelf.position,
					properties = shelf
				})
				shelfCount = shelfCount + 1

				-- Carve shelf around chamber perimeter
				local radiusX = chamber.size.X / 2
				local radiusZ = chamber.size.Z / 2

				for angle = 0, 2*math.pi, math.pi/16 do
					-- Variable shelf width
					local widthNoise = Core.getNoise3D(
						chamber.position.X + math.cos(angle) * radiusX,
						shelfY,
						chamber.position.Z + math.sin(angle) * radiusZ
					)
					local actualDepth = shelfConfig.shelfDepth * (1 + widthNoise * shelfConfig.widthVariation)

					for depth = 0, actualDepth, 1 do
						local shelfPos = Vector3.new(
							chamber.position.X + math.cos(angle) * (radiusX - depth),
							shelfY,
							chamber.position.Z + math.sin(angle) * (radiusZ - depth)
						)

						-- Create shelf platform
						for h = 0, 1, 0.5 do
							Core.setVoxel(shelfPos + Vector3.new(0, h, 0), true, Enum.Material.Air)
						end
					end
				end

				if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
			end
		end
	end

	print("✅ Generated", shelfCount, "shelf layers")
	return shelfLayers
end

-- ================================================================================================
--                                    PLATE GAPS
-- ================================================================================================

local function generatePlateGaps(region, config)
	if not config.Tier3.plateGaps.enabled then
		print("📏 Plate gaps disabled, skipping...")
		return {}
	end

	print("📏 Generating plate gaps...")
	local plateGaps = {}
	local gapConfig = config.Tier3.plateGaps
	local gapCount = 0

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	local sampleStep = 20
	for x = minPoint.X, maxPoint.X, sampleStep do
		for z = minPoint.Z, maxPoint.Z, sampleStep do
			if math.random() < gapConfig.density then
				local startPos = Vector3.new(x, maxPoint.Y, z)

				-- Determine gap depth
				local depthNoise = Core.getNoise3D(x * 0.08, 0, z * 0.08)
				local depth = gapConfig.minDepth + 
					(gapConfig.maxDepth - gapConfig.minDepth) * (depthNoise + 1) / 2

				local gap = {
					id = Core.generateId("gap"),
					startPos = startPos,
					depth = depth,
					width = gapConfig.width
				}

				table.insert(plateGaps, gap)
				Core.addFeature({
					id = gap.id,
					type = "plate_gap",
					position = startPos,
					properties = gap
				})
				gapCount = gapCount + 1

				-- Carve narrow vertical gap
				for d = 0, depth, 1 do
					-- Apply vertical bias - gaps tend to be more vertical than horizontal
					local horizontalDrift = (1 - gapConfig.verticalBias) * 
						Core.getNoise3D(x, startPos.Y - d, z) * 2

					local gapPos = Vector3.new(
						startPos.X + horizontalDrift,
						startPos.Y - d,
						startPos.Z
					)

					-- Create narrow slit
					for w = -gapConfig.width/2, gapConfig.width/2, 0.5 do
						Core.setVoxel(gapPos + Vector3.new(w, 0, 0), true, Enum.Material.Air)
						Core.setVoxel(gapPos + Vector3.new(0, 0, w), true, Enum.Material.Air)
					end

					if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
				end
			end
		end
	end

	print("✅ Generated", gapCount, "plate gaps")
	return plateGaps
end

-- ================================================================================================
--                                    PRESSURE FUNNELS
-- ================================================================================================

local function generatePressureFunnels(chambers, config)
	if not config.Tier3.pressureFunnels.enabled then
		print("🌀 Pressure funnels disabled, skipping...")
		return {}
	end

	print("🌀 Generating pressure funnels...")
	local pressureFunnels = {}
	local funnelConfig = config.Tier3.pressureFunnels
	local funnelCount = 0

	for _, chamber in ipairs(chambers) do
		if math.random() < funnelConfig.probability then
			local funnel = {
				id = Core.generateId("funnel"),
				chamberId = chamber.id,
				position = chamber.position,
				funnelRatio = funnelConfig.funnelRatio,
				chamberSize = chamber.size
			}

			table.insert(pressureFunnels, funnel)
			Core.addFeature({
				id = funnel.id,
				type = "pressure_funnel",
				position = chamber.position,
				properties = funnel
			})
			funnelCount = funnelCount + 1

			-- Modify chamber to create funnel/hourglass shape
			local radiusX = chamber.size.X / 2
			local radiusY = chamber.size.Y / 2
			local radiusZ = chamber.size.Z / 2

			for y = chamber.position.Y - radiusY, chamber.position.Y + radiusY, 2 do
				-- Calculate funnel factor based on Y position
				local yNormalized = math.abs(y - chamber.position.Y) / radiusY
				local funnelFactor = 1 - (1 - funnelConfig.funnelRatio) * 
					math.sin(yNormalized * math.pi) * funnelConfig.transitionSmoothness

				local currentRadiusX = radiusX * funnelFactor
				local currentRadiusZ = radiusZ * funnelFactor

				-- Carve modified chamber cross-section
				for x = chamber.position.X - currentRadiusX, chamber.position.X + currentRadiusX, 2 do
					for z = chamber.position.Z - currentRadiusZ, chamber.position.Z + currentRadiusZ, 2 do
						local dx = (x - chamber.position.X) / currentRadiusX
						local dz = (z - chamber.position.Z) / currentRadiusZ

						if dx*dx + dz*dz <= 1 then
							Core.setVoxel(Vector3.new(x, y, z), true, Enum.Material.Air)
						end
					end
				end

				if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
			end
		end
	end

	print("✅ Generated", funnelCount, "pressure funnels")
	return pressureFunnels
end

-- ================================================================================================
--                                    CONCRETION DOMES
-- ================================================================================================

local function generateConcretionDomes(chambers, config)
	if not config.Tier3.concretionDomes.enabled then
		print("🔘 Concretion domes disabled, skipping...")
		return {}
	end

	print("🔘 Generating concretion domes...")
	local concretionDomes = {}
	local domeConfig = config.Tier3.concretionDomes
	local domeCount = 0

	for _, chamber in ipairs(chambers) do
		if math.random() < domeConfig.probability then
			-- Generate multiple domes on the ceiling
			local numDomes = math.random(1, 4)

			for i = 1, numDomes do
				-- Random position on chamber ceiling
				local ceilingY = chamber.position.Y + chamber.size.Y/2
				local angle = math.random() * 2 * math.pi
				local distance = math.random() * chamber.size.X/3

				local domePos = Vector3.new(
					chamber.position.X + math.cos(angle) * distance,
					ceilingY,
					chamber.position.Z + math.sin(angle) * distance
				)

				local dome = {
					id = Core.generateId("dome"),
					chamberId = chamber.id,
					position = domePos,
					radius = domeConfig.radius,
					height = domeConfig.height
				}

				table.insert(concretionDomes, dome)
				Core.addFeature({
					id = dome.id,
					type = "concretion_dome",
					position = domePos,
					properties = dome
				})
				domeCount = domeCount + 1

				-- Carve dome-shaped bulge in ceiling
				for x = domePos.X - domeConfig.radius, domePos.X + domeConfig.radius, 1 do
					for z = domePos.Z - domeConfig.radius, domePos.Z + domeConfig.radius, 1 do
						for y = domePos.Y, domePos.Y + domeConfig.height, 1 do
							local dx = x - domePos.X
							local dz = z - domePos.Z
							local dy = y - domePos.Y

							-- Dome equation (half-ellipsoid)
							local distance = math.sqrt(
								(dx/domeConfig.radius)^2 + 
									(dz/domeConfig.radius)^2 + 
									(dy/domeConfig.height)^2
							)

							if distance <= 1 then
								-- Smooth the dome surface
								local smoothness = domeConfig.smoothness
								local roughness = Core.getNoise3D(x * 0.3, y * 0.3, z * 0.3) * (1 - smoothness)

								if distance <= 1 + roughness * 0.2 then
									Core.setVoxel(Vector3.new(x, y, z), true, Enum.Material.Air)
								end
							end
						end
					end
				end

				if Core.recordVoxelProcessed then Core.recordVoxelProcessed() end
			end
		end
	end

	print("✅ Generated", domeCount, "concretion domes")
	return concretionDomes
end

-- ================================================================================================
--                                    MAIN GENERATION FUNCTION
-- ================================================================================================

function Tier3.generate(region, config)
	print("🥉 === TIER 3: MICRO-FEATURES GENERATION ===")

	local startTime = tick()
	local results = {
		fractureVeins = {},
		pinchPoints = {},
		seamLayers = {},
		shelfLayers = {},
		plateGaps = {},
		pressureFunnels = {},
		concretionDomes = {},
		generationTime = 0,
		featureCount = 0
	}

	local caveData = Core.getCaveData()
	local totalFeatures = 0

	-- Generate fracture veins throughout the region with error handling
	local fractureSuccess, fractureVeins = pcall(function()
		print("⚡ Starting fracture vein generation...")
		return generateFractureVeins(region, config)
	end)
	
	if fractureSuccess and fractureVeins then
		results.fractureVeins = fractureVeins
		totalFeatures = totalFeatures + #fractureVeins
		print("⚡ Fracture veins generated successfully:", #fractureVeins)
	else
		print("⚠️ Fracture vein generation failed:", tostring(fractureVeins))
	end

	-- Add pinch points to existing passages
	local pinchSuccess, pinchPoints = pcall(function()
		print("🔒 Starting pinch point generation...")
		return generatePinchPoints(caveData.passages, config)
	end)
	
	if pinchSuccess and pinchPoints then
		results.pinchPoints = pinchPoints
		totalFeatures = totalFeatures + #pinchPoints
		print("🔒 Pinch points generated successfully:", #pinchPoints)
	else
		print("⚠️ Pinch point generation failed:", tostring(pinchPoints))
	end

	-- Generate horizontal seam layers
	local seamSuccess, seamLayers = pcall(function()
		print("📚 Starting seam layer generation...")
		return generateSeamLayers(region, config)
	end)
	
	if seamSuccess and seamLayers then
		results.seamLayers = seamLayers
		totalFeatures = totalFeatures + #seamLayers
		print("📚 Seam layers generated successfully:", #seamLayers)
	else
		print("⚠️ Seam layer generation failed:", tostring(seamLayers))
	end

	-- Add shelf layers to chambers
	local shelfSuccess, shelfLayers = pcall(function()
		print("📏 Starting shelf layer generation...")
		return generateShelfLayers(caveData.chambers, config)
	end)
	
	if shelfSuccess and shelfLayers then
		results.shelfLayers = shelfLayers
		totalFeatures = totalFeatures + #shelfLayers
		print("📏 Shelf layers generated successfully:", #shelfLayers)
	else
		print("⚠️ Shelf layer generation failed:", tostring(shelfLayers))
	end

	-- Generate vertical plate gaps
	local plateSuccess, plateGaps = pcall(function()
		print("🕳️ Starting plate gap generation...")
		return generatePlateGaps(region, config)
	end)
	
	if plateSuccess and plateGaps then
		results.plateGaps = plateGaps
		totalFeatures = totalFeatures + #plateGaps
		print("🕳️ Plate gaps generated successfully:", #plateGaps)
	else
		print("⚠️ Plate gap generation failed:", tostring(plateGaps))
	end

	-- Modify chambers to create pressure funnels
	local funnelSuccess, pressureFunnels = pcall(function()
		print("🌀 Starting pressure funnel generation...")
		return generatePressureFunnels(caveData.chambers, config)
	end)
	
	if funnelSuccess and pressureFunnels then
		results.pressureFunnels = pressureFunnels
		totalFeatures = totalFeatures + #pressureFunnels
		print("🌀 Pressure funnels generated successfully:", #pressureFunnels)
	else
		print("⚠️ Pressure funnel generation failed:", tostring(pressureFunnels))
	end

	-- Add concretion domes to chamber ceilings
	local domeSuccess, concretionDomes = pcall(function()
		print("🔘 Starting concretion dome generation...")
		return generateConcretionDomes(caveData.chambers, config)
	end)
	
	if domeSuccess and concretionDomes then
		results.concretionDomes = concretionDomes
		totalFeatures = totalFeatures + #concretionDomes
		print("🔘 Concretion domes generated successfully:", #concretionDomes)
	else
		print("⚠️ Concretion dome generation failed:", tostring(concretionDomes))
	end

	local endTime = tick()
	results.generationTime = endTime - startTime
	results.featureCount = totalFeatures

	print(string.format("✅ Tier 3 micro-features generation complete in %.3f seconds", results.generationTime))
	print(string.format("📊 Total features generated: %d (%d fracture veins, %d pinch points, %d seam layers, %d shelf layers, %d plate gaps, %d pressure funnels, %d concretion domes)", 
		totalFeatures, #results.fractureVeins, #results.pinchPoints, #results.seamLayers, 
		#results.shelfLayers, #results.plateGaps, #results.pressureFunnels, #results.concretionDomes))

	return results
end

return Tier3