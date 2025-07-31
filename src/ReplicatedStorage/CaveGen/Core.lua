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

	-- Check if we need to yield
	if performanceData.voxelsProcessed % config.Core.yieldInterval == 0 then
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

	-- Check connectivity between chambers
	local connected = {}
	local isolated = {}

	for i, chamber in ipairs(mainChambers) do
		local hasConnection = false
		for _, passage in ipairs(caveData.passages) do
			for _, connectionId in ipairs(passage.connections) do
				if connectionId == chamber.id then
					hasConnection = true
					break
				end
			end
			if hasConnection then break end
		end

		if hasConnection then
			table.insert(connected, chamber)
		else
			table.insert(isolated, chamber)
		end
	end

	-- Connect isolated chambers
	for _, isolatedChamber in ipairs(isolated) do
		if #connected > 0 then
			local nearestConnected = connected[1]
			local minDistance = Core.calculateDistance3D(isolatedChamber.position, nearestConnected.position)

			for _, connectedChamber in ipairs(connected) do
				local distance = Core.calculateDistance3D(isolatedChamber.position, connectedChamber.position)
				if distance < minDistance then
					minDistance = distance
					nearestConnected = connectedChamber
				end
			end

			-- Create connecting passage
			local path = Core.findPath(isolatedChamber.position, nearestConnected.position)
			local passage: Passage = {
				id = Core.generateId("bridge_passage"),
				startPos = isolatedChamber.position,
				endPos = nearestConnected.position,
				path = path,
				width = 4,
				connections = {isolatedChamber.id, nearestConnected.id}
			}

			Core.addPassage(passage)
			table.insert(connected, isolatedChamber)

			log("INFO", "Created bridge passage", {
				from = isolatedChamber.id,
				to = nearestConnected.id,
				distance = string.format("%.1f", minDistance)
			})
		end
	end

	log("INFO", "Connectivity analysis complete", {
		totalChambers = #mainChambers,
		connected = #connected,
		bridgesCreated = #isolated
	})
end

return Core