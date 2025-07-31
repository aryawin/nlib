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

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	local sampleStep = 15
	for x = minPoint.X, maxPoint.X, sampleStep do
		for y = minPoint.Y, maxPoint.Y, sampleStep do
			for z = minPoint.Z, maxPoint.Z, sampleStep do
				if math.random() < veinConfig.density then
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

					-- Calculate perpendicular vector for zigzag motion (MOVED HERE)
					local perpendicular = Vector3.new(-direction.Z, 0, direction.X)

					-- Determine vein length
					local lengthNoise = Core.getNoise3D(x * 0.1, y * 0.1, z * 0.1)
					local length = veinConfig.minLength + 
						(veinConfig.maxLength - veinConfig.minLength) * (lengthNoise + 1) / 2

					-- Create zigzag path
					local veinPath = {startPos}
					local currentPos = startPos
					local currentDir = direction

					local step = 1
					for d = step, length, step do
						-- Add zigzag motion
						local zigzagNoise = Core.getNoise3D(
							(startPos.X + d) * 0.3,
							(startPos.Y + d) * 0.3,
							(startPos.Z + d) * 0.3
						)

						-- Create perpendicular zigzag
						local zigzagOffset = perpendicular * zigzagNoise * veinConfig.zigzagIntensity

						currentPos = currentPos + currentDir * step + zigzagOffset
						table.insert(veinPath, currentPos)
					end

					local vein = {
						id = Core.generateId("vein"),
						startPos = startPos,
						path = veinPath,
						width = veinConfig.width,
						length = length,
						perpendicular = perpendicular -- Store for carving
					}

					table.insert(fractureVeins, vein)
					Core.addFeature({
						id = vein.id,
						type = "fracture_vein",
						position = startPos,
						properties = vein
					})
					veinCount = veinCount + 1

					-- Carve the vein (NOW USES STORED PERPENDICULAR)
					for _, pos in ipairs(veinPath) do
						-- Create thin crack
						for w = -veinConfig.width/2, veinConfig.width/2, 0.5 do
							for h = -veinConfig.width, veinConfig.width, 0.5 do
								local offset = vein.perpendicular * w + Vector3.new(0, h, 0)
								Core.setVoxel(pos + offset, true, Enum.Material.Air)
							end
						end
						Core.recordVoxelProcessed()
					end
				end
			end
		end
	end

	print("✅ Generated", veinCount, "fracture veins")
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

				Core.recordVoxelProcessed()
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

					Core.recordVoxelProcessed()
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

				Core.recordVoxelProcessed()
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

					Core.recordVoxelProcessed()
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

				Core.recordVoxelProcessed()
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

				Core.recordVoxelProcessed()
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
	local caveData = Core.getCaveData()

	-- Generate fracture veins throughout the region
	local fractureVeins = generateFractureVeins(region, config)

	-- Add pinch points to existing passages
	local pinchPoints = generatePinchPoints(caveData.passages, config)

	-- Generate horizontal seam layers
	local seamLayers = generateSeamLayers(region, config)

	-- Add shelf layers to chambers
	local shelfLayers = generateShelfLayers(caveData.chambers, config)

	-- Generate vertical plate gaps
	local plateGaps = generatePlateGaps(region, config)

	-- Modify chambers to create pressure funnels
	local pressureFunnels = generatePressureFunnels(caveData.chambers, config)

	-- Add concretion domes to chamber ceilings
	local concretionDomes = generateConcretionDomes(caveData.chambers, config)

	local endTime = tick()
	local generationTime = endTime - startTime

	print(string.format("✅ Tier 3 complete in %.3f seconds", generationTime))
	print(string.format("📊 Generated: %d fracture veins, %d pinch points, %d seam layers, %d shelf layers, %d plate gaps, %d pressure funnels, %d concretion domes", 
		#fractureVeins, #pinchPoints, #seamLayers, #shelfLayers, #plateGaps, #pressureFunnels, #concretionDomes))

	return {
		fractureVeins = fractureVeins,
		pinchPoints = pinchPoints,
		seamLayers = seamLayers,
		shelfLayers = shelfLayers,
		plateGaps = plateGaps,
		pressureFunnels = pressureFunnels,
		concretionDomes = concretionDomes,
		generationTime = generationTime
	}
end

return Tier3