--[[
====================================================================================================
                                        CaveGen Core
                            Central orchestration and data management
====================================================================================================
]]

local Core = {}

-- Dependencies
local NoiseLib = require(game.ServerScriptService.NoiseLib)

-- ================================================================================================
--                                    TYPES & CONSTANTS
-- ================================================================================================

export type CaveData = {
	chambers: {Chamber},
	passages: {Passage},
	verticalShafts: {VerticalShaft},
	branches: {Branch},
	subChambers: {Chamber},
	collapseRooms: {CollapseRoom},
	hiddenPockets: {HiddenPocket},
	features: {Feature},
	metadata: GenerationMetadata
}

export type Chamber = {
	id: string,
	position: Vector3,
	size: Vector3,
	shape: string, -- "sphere", "ellipsoid", "irregular"
	connections: {string}, -- IDs of connected features
	material: Enum.Material,
	isMainChamber: boolean
}

export type Passage = {
	id: string,
	startPos: Vector3,
	endPos: Vector3,
	path: {Vector3},
	width: number,
	connections: {string}
}

export type VerticalShaft = {
	id: string,
	position: Vector3,
	height: number,
	radius: number,
	angle: number -- degrees from vertical
}

export type Branch = {
	id: string,
	parentId: string,
	path: {Vector3},
	width: number,
	isDeadEnd: boolean
}

export type CollapseRoom = {
	id: string,
	position: Vector3,
	size: Vector3,
	irregularityFactor: number,
	debrisAmount: number
}

export type HiddenPocket = {
	id: string,
	position: Vector3,
	size: number,
	discovered: boolean
}

export type Feature = {
	id: string,
	type: string,
	position: Vector3,
	properties: {[string]: any}
}

export type GenerationMetadata = {
	seed: number?,
	generationTime: number,
	totalVoxels: number,
	memoryUsed: number,
	version: string
}

-- Log levels
local LOG_LEVELS = {
	DEBUG = 1,
	INFO = 2,
	WARNING = 3,
	ERROR = 4
}

-- ================================================================================================
--                                    CORE STATE
-- ================================================================================================

local caveData: CaveData = {
	chambers = {},
	passages = {},
	verticalShafts = {},
	branches = {},
	subChambers = {},
	collapseRooms = {},
	hiddenPockets = {},
	features = {},
	metadata = {
		seed = nil,
		generationTime = 0,
		totalVoxels = 0,
		memoryUsed = 0,
		version = "1.0.0"
	}
}

local noiseGenerator: any = nil
local config: any = nil
local logLevel: number = LOG_LEVELS.INFO

-- ================================================================================================
--                                    LOGGING SYSTEM
-- ================================================================================================

local function log(level: string, message: string, details: any?)
	local levelNum = LOG_LEVELS[level] or LOG_LEVELS.INFO
	if levelNum < logLevel then return end

	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s] CaveGen:", timestamp, level)

	if details then
		print(prefix, message, details)
	else
		print(prefix, message)
	end

	-- Log to output for debugging
	if level == "ERROR" then
		warn(prefix, message)
	end
end

local function setLogLevel(level: string)
	logLevel = LOG_LEVELS[level] or LOG_LEVELS.INFO
	log("INFO", "Log level set to " .. level)
end

-- ================================================================================================
--                                    INITIALIZATION
-- ================================================================================================

function Core.initialize(configTable: any): boolean
	local success, err = pcall(function()
		config = configTable

		-- Set log level
		setLogLevel(config.Core.logLevel or "INFO")
		log("INFO", "Initializing CaveGen Core system...")
		
		-- Debug config structure
		log("DEBUG", "Config structure check - Performance section exists:", config.Performance ~= nil)
		if config.Performance then
			log("DEBUG", "Performance settings:", {
				enableCaching = config.Performance.enableCaching,
				cacheSize = config.Performance.cacheSize,
				maxMemoryUsage = config.Performance.maxMemoryUsage
			})
		end

		-- Initialize noise generator
		local seed = config.Core.seed or tick()
		log("DEBUG", "About to create NoiseLib with seed:", seed)
		
		local noiseGenSuccess, noiseGenResult = pcall(function()
			return NoiseLib.new(seed, {
				cache = {
					enabled = config.Performance.enableCaching,
					maxSize = config.Performance.cacheSize
				},
				performance = {
					yieldInterval = config.Core.yieldInterval,
					memoryThreshold = config.Performance.maxMemoryUsage
				}
			})
		end)
		
		if not noiseGenSuccess then
			error("NoiseLib creation failed: " .. tostring(noiseGenResult))
		end
		
		noiseGenerator = noiseGenResult
		log("DEBUG", "NoiseLib created successfully")

		-- Store seed in metadata
		caveData.metadata.seed = seed

		log("INFO", "Core initialized successfully", {seed = seed})
		return true
	end)

	if not success then
		log("ERROR", "Failed to initialize Core", err)
		return false
	end

	return true
end

-- ================================================================================================
--                                    DATA MANAGEMENT
-- ================================================================================================

function Core.getCaveData(): CaveData
	return caveData
end

function Core.clearCaveData(): ()
	caveData = {
		chambers = {},
		passages = {},
		verticalShafts = {},
		branches = {},
		subChambers = {},
		collapseRooms = {},
		hiddenPockets = {},
		features = {},
		metadata = caveData.metadata -- Preserve metadata
	}
	log("DEBUG", "Cave data cleared")
end

function Core.addChamber(chamber: Chamber): ()
	table.insert(caveData.chambers, chamber)
	log("DEBUG", "Added chamber", chamber.id)
end

function Core.addPassage(passage: Passage): ()
	table.insert(caveData.passages, passage)
	log("DEBUG", "Added passage", passage.id)
end

function Core.addVerticalShaft(shaft: VerticalShaft): ()
	table.insert(caveData.verticalShafts, shaft)
	log("DEBUG", "Added vertical shaft", shaft.id)
end

function Core.addFeature(feature: Feature): ()
	table.insert(caveData.features, feature)
	log("DEBUG", "Added feature", {type = feature.type, id = feature.id})
end

-- ================================================================================================
--                                    NOISE OPERATIONS
-- ================================================================================================

function Core.getNoise3D(x: number, y: number, z: number, noiseType: string?): number
	if not noiseGenerator then
		log("ERROR", "Noise generator not initialized")
		return 0
	end

	local nType = noiseType or "simplex"

	if nType == "simplex" then
		return noiseGenerator:simplex3D(x, y, z)
	elseif nType == "worley" then
		return noiseGenerator:worley3D(x, y, z)
	elseif nType == "perlin" then
		return noiseGenerator:perlin3D(x, y, z)
	else
		return noiseGenerator:simplex3D(x, y, z)
	end
end

function Core.getFBM(x: number, y: number, z: number, settings: any): number
	if not noiseGenerator then
		log("ERROR", "Noise generator not initialized")
		return 0
	end

	return noiseGenerator:getFBM(x, y, z, settings)
end

function Core.getRealisticCaves(x: number, y: number, z: number, settings: any): any
	if not noiseGenerator then
		log("ERROR", "Noise generator not initialized")
		return {isAir = false}
	end

	return noiseGenerator:generateRealisticCaves(x, y, z, settings)
end

-- ================================================================================================
--                                    TERRAIN OPERATIONS
-- ================================================================================================

local voxelData = {} -- Buffer for terrain operations
local voxelMaterials = {}

function Core.initializeTerrainBuffer(region: Region3): ()
	local size = region.Size
	local resolution = config.Core.terrainResolution or 4

	-- Calculate voxel grid dimensions
	local voxelsX = math.ceil(size.X / resolution)
	local voxelsY = math.ceil(size.Y / resolution)
	local voxelsZ = math.ceil(size.Z / resolution)

	-- Initialize 3D arrays
	voxelData = table.create(voxelsX)
	voxelMaterials = table.create(voxelsX)

	for x = 1, voxelsX do
		voxelData[x] = table.create(voxelsY)
		voxelMaterials[x] = table.create(voxelsY)
		for y = 1, voxelsY do
			voxelData[x][y] = table.create(voxelsZ, 1) -- 0 = air, 1 = solid (start with solid rock)
			voxelMaterials[x][y] = table.create(voxelsZ, config.Core.materialRock)
		end
	end

	log("INFO", "Terrain buffer initialized", {
		voxels = voxelsX * voxelsY * voxelsZ,
		resolution = resolution
	})
end

function Core.setVoxel(position: Vector3, isAir: boolean, material: Enum.Material?): ()
	local resolution = config.Core.terrainResolution or 4
	local x = math.floor(position.X / resolution) + 1
	local y = math.floor(position.Y / resolution) + 1
	local z = math.floor(position.Z / resolution) + 1

	-- Bounds checking
	if x >= 1 and x <= #voxelData and 
		y >= 1 and y <= #voxelData[1] and 
		z >= 1 and z <= #voxelData[1][1] then

		voxelData[x][y][z] = if isAir then 0 else 1
		voxelMaterials[x][y][z] = material or (if isAir then config.Core.materialAir else config.Core.materialRock)
	end
end

function Core.applyTerrainChanges(region: Region3): ()
	if not voxelData or #voxelData == 0 then
		log("WARNING", "No voxel data to apply")
		return
	end

	local startTime = tick()
	local resolution = config.Core.terrainResolution or 4

	-- Convert to Roblox terrain format
	local minPoint = region.CFrame.Position - region.Size/2

	-- Apply via WriteVoxels
	local success, err = pcall(function()
		-- Validate array dimensions
		if not voxelData or #voxelData == 0 then
			error("voxelData is empty")
		end
		if not voxelMaterials or #voxelMaterials == 0 then
			error("voxelMaterials is empty")
		end
		
		-- Check dimensions match
		local expectedX = math.ceil(region.Size.X / resolution)
		local expectedY = math.ceil(region.Size.Y / resolution)
		local expectedZ = math.ceil(region.Size.Z / resolution)
		
		if #voxelData ~= expectedX then
			error(string.format("X dimension mismatch: expected %d, got %d", expectedX, #voxelData))
		end
		if #voxelData[1] ~= expectedY then
			error(string.format("Y dimension mismatch: expected %d, got %d", expectedY, #voxelData[1]))
		end
		if #voxelData[1][1] ~= expectedZ then
			error(string.format("Z dimension mismatch: expected %d, got %d", expectedZ, #voxelData[1][1]))
		end
		
		workspace.Terrain:WriteVoxels(
			region,
			resolution,
			voxelMaterials,
			voxelData
		)
	end)

	if success then
		local endTime = tick()
		log("INFO", "Terrain changes applied successfully", {
			time = string.format("%.3f", endTime - startTime),
			voxels = #voxelData * #voxelData[1] * #voxelData[1][1]
		})
	else
		log("ERROR", "Failed to apply terrain changes", err)
	end
end

-- ================================================================================================
--                                    PATHFINDING
-- ================================================================================================

function Core.findPath(startPos, endPos, maxSteps)
	maxSteps = maxSteps or 50

	-- Simple direct path for short distances to avoid pathfinding overhead
	local distance = (endPos - startPos).Magnitude
	if distance < 20 then
		return {startPos, endPos}
	end

	-- Simplified pathfinding with fewer steps to reduce warnings
	local path = {startPos}
	local currentPos = startPos
	local direction = (endPos - startPos).Unit
	local stepSize = distance / math.min(maxSteps, 20) -- Limit steps to reduce spam

	for i = 1, math.min(maxSteps, 20) do
		local progress = i / math.min(maxSteps, 20)
		local targetPos = startPos + direction * distance * progress

		-- Add some simple curve without complex pathfinding
		local curvature = math.sin(progress * math.pi) * 5
		targetPos = targetPos + Vector3.new(curvature, 0, curvature)

		table.insert(path, targetPos)
		currentPos = targetPos

		-- Yield occasionally to prevent lag
		if i % 5 == 0 then
			wait()
		end
	end

	-- Ensure end position is reached
	if (path[#path] - endPos).Magnitude > 1 then
		table.insert(path, endPos)
	end

	return path
end

-- ================================================================================================
--                                    PERFORMANCE MONITORING
-- ================================================================================================

local performanceData = {
	frameStart = 0,
	voxelsProcessed = 0,
	memoryStart = 0
}

function Core.startPerformanceMonitoring(): ()
	performanceData.frameStart = tick()
	performanceData.voxelsProcessed = 0
	performanceData.memoryStart = gcinfo("count")
end

function Core.recordVoxelProcessed(): ()
	performanceData.voxelsProcessed = performanceData.voxelsProcessed + 1

	-- Check if we need to yield (using optimized interval)
	local yieldInterval = config.Core.yieldInterval or 50
	if performanceData.voxelsProcessed % yieldInterval == 0 then
		task.wait()
	end
end

function Core.endPerformanceMonitoring(): ()
	local endTime = tick()
	local endMemory = gcinfo("count")

	caveData.metadata.generationTime = endTime - performanceData.frameStart
	caveData.metadata.totalVoxels = performanceData.voxelsProcessed
	caveData.metadata.memoryUsed = endMemory - performanceData.memoryStart

	if config.Core.enablePerformanceLogging then
		log("INFO", "Performance metrics", {
			time = string.format("%.3f seconds", caveData.metadata.generationTime),
			voxels = caveData.metadata.totalVoxels,
			memory = string.format("%.2f KB", caveData.metadata.memoryUsed),
			voxelsPerSecond = math.floor(caveData.metadata.totalVoxels / caveData.metadata.generationTime)
		})
	end
end

-- ================================================================================================
--                                    UTILITIES
-- ================================================================================================

function Core.generateId(prefix: string?): string
	local p = prefix or "item"
	return p .. "_" .. tostring(tick()):gsub("%.", "")
end

function Core.isValidPosition(position: Vector3, region: Region3): boolean
	local minPoint = region.CFrame.Position - region.Size/2
	local maxPoint = region.CFrame.Position + region.Size/2

	return position.X >= minPoint.X and position.X <= maxPoint.X and
		position.Y >= minPoint.Y and position.Y <= maxPoint.Y and
		position.Z >= minPoint.Z and position.Z <= maxPoint.Z
end

function Core.smoothPath(path: {Vector3}, smoothingPasses: number?): {Vector3}
	local passes = smoothingPasses or 3
	local smoothed = {table.unpack(path)}

	for pass = 1, passes do
		for i = 2, #smoothed - 1 do
			local prev = smoothed[i-1]
			local curr = smoothed[i]
			local next = smoothed[i+1]

			smoothed[i] = curr:lerp((prev + next) / 2, 0.3)
		end
	end

	return smoothed
end

function Core.calculateDistance3D(pos1: Vector3, pos2: Vector3): number
	return (pos2 - pos1).Magnitude
end

-- ================================================================================================
--                                    CONNECTIVITY ANALYSIS
-- ================================================================================================

function Core.ensureConnectivity(): ()
	if not config.Connectivity.ensureConnectivity then return end

	log("INFO", "Analyzing cave connectivity...")

	-- Find all main chambers
	local mainChambers = {}
	for _, chamber in ipairs(caveData.chambers) do
		if chamber.isMainChamber then
			table.insert(mainChambers, chamber)
		end
	end

	if #mainChambers <= 1 then return end

	-- Build connectivity graph
	local connectionGraph = {}
	for i, chamber in ipairs(mainChambers) do
		connectionGraph[chamber.id] = {}
	end

	-- Map existing connections from passages
	for _, passage in ipairs(caveData.passages) do
		if passage.connections and #passage.connections >= 2 then
			local id1, id2 = passage.connections[1], passage.connections[2]
			if connectionGraph[id1] and connectionGraph[id2] then
				table.insert(connectionGraph[id1], id2)
				table.insert(connectionGraph[id2], id1)
			end
		end
	end

	-- Find connected components using flood fill
	local visited = {}
	local components = {}

	local function floodFill(startId)
		local component = {}
		local queue = {startId}
		visited[startId] = true

		while #queue > 0 do
			local currentId = table.remove(queue, 1)
			table.insert(component, currentId)

			for _, neighborId in ipairs(connectionGraph[currentId] or {}) do
				if not visited[neighborId] then
					visited[neighborId] = true
					table.insert(queue, neighborId)
				end
			end
		end

		return component
	end

	for _, chamber in ipairs(mainChambers) do
		if not visited[chamber.id] then
			local component = floodFill(chamber.id)
			table.insert(components, component)
		end
	end

	log("INFO", "Found connectivity components", {
		totalChambers = #mainChambers,
		components = #components
	})

	-- Connect isolated components to the largest component
	if #components > 1 then
		-- Find largest component
		local largestComponent = components[1]
		for _, component in ipairs(components) do
			if #component > #largestComponent then
				largestComponent = component
			end
		end

		-- Connect other components to the largest one
		for _, component in ipairs(components) do
			if component ~= largestComponent then
				-- Find closest chambers between components
				local minDistance = math.huge
				local bestConnection = nil

				for _, isolatedId in ipairs(component) do
					for _, connectedId in ipairs(largestComponent) do
						local isolatedChamber = nil
						local connectedChamber = nil

						-- Find chamber objects
						for _, chamber in ipairs(mainChambers) do
							if chamber.id == isolatedId then
								isolatedChamber = chamber
							elseif chamber.id == connectedId then
								connectedChamber = chamber
							end
						end

						if isolatedChamber and connectedChamber then
							local distance = Core.calculateDistance3D(isolatedChamber.position, connectedChamber.position)
							if distance < minDistance then
								minDistance = distance
								bestConnection = {isolatedChamber, connectedChamber}
							end
						end
					end
				end

				-- Create bridge passage
				if bestConnection then
					local chamber1, chamber2 = bestConnection[1], bestConnection[2]
					local path = Core.findPath(chamber1.position, chamber2.position, 30) -- Limited pathfinding

					local bridgePassage: Passage = {
						id = Core.generateId("bridge_passage"),
						startPos = chamber1.position,
						endPos = chamber2.position,
						path = path,
						width = 6, -- Wider bridge passages
						connections = {chamber1.id, chamber2.id}
					}

					-- Carve the bridge passage with optimized algorithm
					for i, pos in ipairs(path) do
						if i % 2 == 0 then -- Skip every other point for performance
							local radius = bridgePassage.width / 2
							
							-- Simple cylindrical carving
							for r = 0, radius, 2 do
								for angle = 0, 2*math.pi, math.pi/3 do
									local offset = Vector3.new(
										math.cos(angle) * r,
										0,
										math.sin(angle) * r
									)
									
									for h = -radius, radius, 2 do
										local voxelPos = pos + offset + Vector3.new(0, h, 0)
										Core.setVoxel(voxelPos, true, Enum.Material.Air)
									end
								end
							end
						end
						
						-- Yield periodically
						if i % 5 == 0 then
							task.wait()
						end
					end

					Core.addPassage(bridgePassage)

					-- Update connectivity graph
					table.insert(connectionGraph[chamber1.id], chamber2.id)
					table.insert(connectionGraph[chamber2.id], chamber1.id)

					log("INFO", "Created bridge passage", {
						from = chamber1.id,
						to = chamber2.id,
						distance = string.format("%.1f", minDistance),
						pathPoints = #path
					})
				end
			end
		end
	end

	log("INFO", "Connectivity analysis complete", {
		totalChambers = #mainChambers,
		originalComponents = #components,
		bridgesCreated = math.max(0, #components - 1)
	})
end

return Core