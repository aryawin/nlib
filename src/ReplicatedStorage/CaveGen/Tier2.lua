--[[
====================================================================================================
                                        CaveGen Tier 2
                     Complexity Features: Branches, Sub-chambers, Collapse Rooms, etc.
====================================================================================================
]]

local Tier2 = {}

-- Dependencies
local Core = require(script.Parent.Core)

-- ================================================================================================
--                                    BRANCHES
-- ================================================================================================

local function generateBranches(passages, config)
	if not config.Tier2.branches.enabled then
		print("🌿 Branches disabled, skipping...")
		return {}
	end

	print("🌿 Generating passage branches...")
	local branches = {}
	local branchConfig = config.Tier2.branches
	local branchCount = 0

	for _, passage in ipairs(passages) do
		-- Create branches along the passage path
		for i = 2, #passage.path - 1 do
			if math.random() < branchConfig.probability then
				local branchPoint = passage.path[i]

				-- Determine branch direction (perpendicular to passage)
				local passageDir = (passage.path[i+1] - passage.path[i-1]).Unit
				local perpendicular = Vector3.new(-passageDir.Z, 0, passageDir.X).Unit

				-- Add some randomness to branch direction
				local randomAngle = (math.random() - 0.5) * math.pi
				local branchDir = Vector3.new(
					perpendicular.X * math.cos(randomAngle) - perpendicular.Z * math.sin(randomAngle),
					(math.random() - 0.5) * 0.5, -- Slight vertical component
					perpendicular.X * math.sin(randomAngle) + perpendicular.Z * math.cos(randomAngle)
				).Unit

				-- Determine branch length
				local lengthNoise = Core.getNoise3D(branchPoint.X * 0.1, branchPoint.Y * 0.1, branchPoint.Z * 0.1)
				local length = branchConfig.minLength + 
					(branchConfig.maxLength - branchConfig.minLength) * (lengthNoise + 1) / 2

				-- Create branch path
				local branchPath = {branchPoint}
				local currentPos = branchPoint
				local step = 2

				for d = step, length, step do
					-- Add some curvature
					local curvature = Core.getNoise3D(
						(branchPoint.X + d) * 0.15,
						(branchPoint.Y + d) * 0.15,
						(branchPoint.Z + d) * 0.15
					) * 0.3

					local curvedDir = branchDir + Vector3.new(curvature, curvature * 0.5, curvature)
					currentPos = currentPos + curvedDir.Unit * step
					table.insert(branchPath, currentPos)
				end

				-- Determine if this is a dead end
				local isDeadEnd = math.random() < branchConfig.deadEndChance

				-- Calculate branch width (tapers from main passage)
				local baseWidth = passage.width * branchConfig.tapering

				local branch = {
					id = Core.generateId("branch"),
					parentId = passage.id,
					path = branchPath,
					width = baseWidth,
					isDeadEnd = isDeadEnd
				}

				table.insert(branches, branch)
				branchCount = branchCount + 1

				-- Carve the branch
				for j = 1, #branchPath do
					local pos = branchPath[j]
					local widthAtPoint = baseWidth * (1 - (j - 1) / #branchPath * 0.5) -- Gradual tapering

					-- Carve cylindrical tunnel
					for r = 0, widthAtPoint/2, 1 do
						for angle = 0, 2*math.pi, math.pi/6 do
							local offset = Vector3.new(
								math.cos(angle) * r,
								0,
								math.sin(angle) * r
							)

							-- Add vertical variation
							for h = -widthAtPoint/4, widthAtPoint/4, 1 do
								local finalPos = pos + offset + Vector3.new(0, h, 0)

								-- Wall roughness
								local roughness = Core.getNoise3D(
									finalPos.X * 0.25,
									finalPos.Y * 0.25,
									finalPos.Z * 0.25
								) * 0.4

								if r <= widthAtPoint/2 + roughness then
									Core.setVoxel(finalPos, true, Enum.Material.Air)
								end
							end
						end
					end

					Core.recordVoxelProcessed()
				end

				-- Seal dead end if needed
				if isDeadEnd and config.Tier2.falsePassages.enabled then
					local endPos = branchPath[#branchPath]
					local sealLength = config.Tier2.falsePassages.taperLength

					-- Create tapering seal
					for s = 0, sealLength, 1 do
						local sealPos = endPos + branchDir * s
						local sealRadius = baseWidth/2 * (1 - s/sealLength)

						for r = 0, sealRadius, 1 do
							for angle = 0, 2*math.pi, math.pi/4 do
								local offset = Vector3.new(
									math.cos(angle) * r,
									0,
									math.sin(angle) * r
								)
								Core.setVoxel(sealPos + offset, false, config.Tier2.falsePassages.sealMaterial)
							end
						end
					end
				end
			end
		end
	end

	print("✅ Generated", branchCount, "branches")
	return branches
end

-- ================================================================================================
--                                    SUB-CHAMBERS
-- ================================================================================================

local function generateSubChambers(mainChambers, config)
	if not config.Tier2.subChambers.enabled then
		print("🏠 Sub-chambers disabled, skipping...")
		return {}
	end

	print("🏠 Generating sub-chambers...")
	local subChambers = {}
	local subChamberConfig = config.Tier2.subChambers
	local subChamberCount = 0

	for _, chamber in ipairs(mainChambers) do
		if math.random() < subChamberConfig.probability then
			-- Determine number of sub-chambers for this main chamber
			local numSubChambers = math.random(1, 3)

			for i = 1, numSubChambers do
				-- Generate position around the main chamber
				local angle = (i / numSubChambers) * 2 * math.pi + math.random() * math.pi/4
				local distance = chamber.size.X/2 + subChamberConfig.distance

				local subPos = chamber.position + Vector3.new(
					math.cos(angle) * distance,
					(math.random() - 0.5) * chamber.size.Y/2,
					math.sin(angle) * distance
				)

				-- Calculate sub-chamber size
				local subSize = chamber.size * subChamberConfig.sizeRatio

				-- Add variation
				local sizeNoise = Core.getNoise3D(subPos.X * 0.08, subPos.Y * 0.08, subPos.Z * 0.08)
				subSize = subSize * (1 + sizeNoise * 0.3)

				local subChamber = {
					id = Core.generateId("subchamber"),
					position = subPos,
					size = subSize,
					shape = "ellipsoid",
					connections = {chamber.id},
					material = Enum.Material.Air,
					isMainChamber = false,
					parentId = chamber.id
				}

				table.insert(subChambers, subChamber)
				Core.addChamber(subChamber)
				subChamberCount = subChamberCount + 1

				-- Carve the sub-chamber
				local radiusX = subSize.X / 2
				local radiusY = subSize.Y / 2
				local radiusZ = subSize.Z / 2

				for x = subPos.X - radiusX, subPos.X + radiusX, 2 do
					for y = subPos.Y - radiusY, subPos.Y + radiusY, 2 do
						for z = subPos.Z - radiusZ, subPos.Z + radiusZ, 2 do
							local dx = (x - subPos.X) / radiusX
							local dy = (y - subPos.Y) / radiusY
							local dz = (z - subPos.Z) / radiusZ

							if dx*dx + dy*dy + dz*dz <= 1 then
								local roughness = Core.getNoise3D(x * 0.2, y * 0.2, z * 0.2) * 0.3
								if dx*dx + dy*dy + dz*dz <= 1 + roughness then
									Core.setVoxel(Vector3.new(x, y, z), true, Enum.Material.Air)
								end
							end
						end
					end
					Core.recordVoxelProcessed()
				end

				-- Create connecting tunnel
				local connectionPath = Core.findPath(chamber.position, subPos, 20)
				for j = 1, #connectionPath do
					local pos = connectionPath[j]
					local width = subChamberConfig.connectionWidth

					for r = 0, width/2, 1 do
						for angle = 0, 2*math.pi, math.pi/4 do
							local offset = Vector3.new(
								math.cos(angle) * r,
								0,
								math.sin(angle) * r
							)
							Core.setVoxel(pos + offset, true, Enum.Material.Air)
						end
					end
				end
			end
		end
	end

	print("✅ Generated", subChamberCount, "sub-chambers")
	return subChambers
end

-- ================================================================================================
--                                    COLLAPSE ROOMS
-- ================================================================================================

local function generateCollapseRooms(region, config)
	if not config.Tier2.collapseRooms.enabled then
		print("💥 Collapse rooms disabled, skipping...")
		return {}
	end

	print("💥 Generating collapse rooms...")
	local collapseRooms = {}
	local collapseConfig = config.Tier2.collapseRooms
	local collapseCount = 0

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	-- Potential collapse room locations
	local sampleStep = 25
	for x = minPoint.X, maxPoint.X, sampleStep do
		for y = minPoint.Y, maxPoint.Y, sampleStep do
			for z = minPoint.Z, maxPoint.Z, sampleStep do
				if math.random() < collapseConfig.probability then
					local position = Vector3.new(x, y, z)

					-- Determine size
					local sizeNoise = Core.getNoise3D(x * 0.03, y * 0.03, z * 0.03)
					local size = collapseConfig.minSize + 
						(collapseConfig.maxSize - collapseConfig.minSize) * (sizeNoise + 1) / 2

					local collapseRoom = {
						id = Core.generateId("collapse"),
						position = position,
						size = Vector3.new(size, size * 0.7, size), -- Flatter chambers
						irregularityFactor = collapseConfig.irregularityFactor,
						debrisAmount = collapseConfig.debrisAmount
					}

					table.insert(collapseRooms, collapseRoom)
					collapseCount = collapseCount + 1

					-- Carve highly irregular chamber
					local radius = size / 2
					for cx = position.X - radius, position.X + radius, 2 do
						for cy = position.Y - radius*0.7, position.Y + radius*0.7, 2 do
							for cz = position.Z - radius, position.Z + radius, 2 do
								local distance = math.sqrt(
									((cx - position.X)/radius)^2 + 
										((cy - position.Y)/(radius*0.7))^2 + 
										((cz - position.Z)/radius)^2
								)

								-- High irregularity using multiple noise octaves
								local irregularity = 
									Core.getNoise3D(cx * 0.1, cy * 0.1, cz * 0.1) * 0.4 +
									Core.getNoise3D(cx * 0.2, cy * 0.2, cz * 0.2) * 0.2 +
									Core.getNoise3D(cx * 0.4, cy * 0.4, cz * 0.4) * 0.1

								if distance <= 1 + irregularity * collapseConfig.irregularityFactor then
									Core.setVoxel(Vector3.new(cx, cy, cz), true, Enum.Material.Air)
								end

								-- Add debris piles
								if distance > 0.8 and distance <= 1.2 and 
									math.random() < collapseConfig.debrisAmount then
									Core.setVoxel(Vector3.new(cx, cy - radius*0.6, cz), false, Enum.Material.Rock)
								end
							end
						end
						Core.recordVoxelProcessed()
					end
				end
			end
		end
	end

	print("✅ Generated", collapseCount, "collapse rooms")
	return collapseRooms
end

-- ================================================================================================
--                                    HIDDEN POCKETS
-- ================================================================================================

local function generateHiddenPockets(region, config)
	if not config.Tier2.hiddenPockets.enabled then
		print("🕳️ Hidden pockets disabled, skipping...")
		return {}
	end

	print("🕳️ Generating hidden pockets...")
	local hiddenPockets = {}
	local pocketConfig = config.Tier2.hiddenPockets
	local pocketCount = 0

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	local sampleStep = 8
	for x = minPoint.X, maxPoint.X, sampleStep do
		for y = minPoint.Y, maxPoint.Y, sampleStep do
			for z = minPoint.Z, maxPoint.Z, sampleStep do
				if math.random() < pocketConfig.density then
					local position = Vector3.new(x, y, z)

					-- Determine pocket size
					local sizeNoise = Core.getNoise3D(x * 0.2, y * 0.2, z * 0.2)
					local size = pocketConfig.minSize + 
						(pocketConfig.maxSize - pocketConfig.minSize) * (sizeNoise + 1) / 2

					local pocket = {
						id = Core.generateId("pocket"),
						position = position,
						size = size,
						discovered = false
					}

					table.insert(hiddenPockets, pocket)
					pocketCount = pocketCount + 1

					-- Carve small spherical pocket
					local radius = size / 2
					for px = position.X - radius, position.X + radius, 1 do
						for py = position.Y - radius, position.Y + radius, 1 do
							for pz = position.Z - radius, position.Z + radius, 1 do
								local distance = (Vector3.new(px, py, pz) - position).Magnitude
								if distance <= radius then
									Core.setVoxel(Vector3.new(px, py, pz), true, Enum.Material.Air)
								end
							end
						end
					end
				end
			end
		end
	end

	print("✅ Generated", pocketCount, "hidden pockets")
	return hiddenPockets
end

-- ================================================================================================
--                                    OTHER TIER 2 FEATURES
-- ================================================================================================

local function generateTectonicIntersections(region, config)
	if not config.Tier2.tectonicIntersections.enabled then
		print("⚡ Tectonic intersections disabled, skipping...")
		return 0
	end

	print("⚡ Generating tectonic intersections...")
	local intersectionCount = 0
	local tectonicConfig = config.Tier2.tectonicIntersections

	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	local sampleStep = 30
	for x = minPoint.X, maxPoint.X, sampleStep do
		for y = minPoint.Y, maxPoint.Y, sampleStep do
			for z = minPoint.Z, maxPoint.Z, sampleStep do
				if math.random() < tectonicConfig.probability then
					local center = Vector3.new(x, y, z)
					local radius = tectonicConfig.chaosRadius

					-- Create chaotic intersection using two offset noise patterns
					for cx = center.X - radius, center.X + radius, 2 do
						for cy = center.Y - radius, center.Y + radius, 2 do
							for cz = center.Z - radius, center.Z + radius, 2 do
								local distance = (Vector3.new(cx, cy, cz) - center).Magnitude
								if distance <= radius then
									-- Blend two different noise patterns
									local noise1 = Core.getNoise3D(cx * 0.05, cy * 0.05, cz * 0.05)
									local noise2 = Core.getNoise3D(
										(cx + tectonicConfig.noiseOffset) * 0.05,
										(cy + tectonicConfig.noiseOffset) * 0.05,
										(cz + tectonicConfig.noiseOffset) * 0.05
									)

									local blended = noise1 * tectonicConfig.blendFactor + 
										noise2 * (1 - tectonicConfig.blendFactor)

									if blended > 0.2 then
										Core.setVoxel(Vector3.new(cx, cy, cz), true, Enum.Material.Air)
									end
								end
							end
						end
						Core.recordVoxelProcessed()
					end

					intersectionCount = intersectionCount + 1
				end
			end
		end
	end

	print("✅ Generated", intersectionCount, "tectonic intersections")
	return intersectionCount
end

-- ================================================================================================
--                                    MAIN GENERATION FUNCTION
-- ================================================================================================

function Tier2.generate(region, config)
	print("🥈 === TIER 2: COMPLEXITY GENERATION ===")

	local startTime = tick()
	local caveData = Core.getCaveData()

	-- Generate branches from existing passages
	local branches = generateBranches(caveData.passages, config)

	-- Generate sub-chambers connected to main chambers
	local subChambers = generateSubChambers(caveData.chambers, config)

	-- Generate large collapse rooms
	local collapseRooms = generateCollapseRooms(region, config)

	-- Generate hidden pockets
	local hiddenPockets = generateHiddenPockets(region, config)

	-- Generate tectonic intersections
	local tectonicCount = generateTectonicIntersections(region, config)

	-- TODO: Add other Tier 2 features (crustal overhangs, tilted floors, etc.)

	local endTime = tick()
	local generationTime = endTime - startTime

	print(string.format("✅ Tier 2 complete in %.3f seconds", generationTime))
	print(string.format("📊 Generated: %d branches, %d sub-chambers, %d collapse rooms, %d hidden pockets, %d tectonic intersections", 
		#branches, #subChambers, #collapseRooms, #hiddenPockets, tectonicCount))

	return {
		branches = branches,
		subChambers = subChambers,
		collapseRooms = collapseRooms,
		hiddenPockets = hiddenPockets,
		tectonicIntersections = tectonicCount,
		generationTime = generationTime
	}
end

return Tier2