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

-- Fallback noise functions when NoiseLib fails
local function fallbackSimplex(x: number, y: number, z: number): number
	-- Simple pseudo-random noise based on position
	local seed = x * 374761393 + y * 668265263 + z * 2147483647
	seed = (seed * 16807) % 2147483647
	return (seed / 2147483647) * 2 - 1
end

local function fallbackWorley(x: number, y: number, z: number): number
	-- Simplified cellular noise approximation
	local cellX = math.floor(x)
	local cellY = math.floor(y) 
	local cellZ = math.floor(z)
	
	local minDist = math.huge
	
	-- Check 3x3x3 neighborhood of cells
	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				local seed = (cellX + dx) * 374761393 + (cellY + dy) * 668265263 + (cellZ + dz) * 2147483647
				seed = (seed * 16807) % 2147483647
				
				local cellCenterX = cellX + dx + (seed % 1000) / 1000
				local cellCenterY = cellY + dy + ((seed / 1000) % 1000) / 1000
				local cellCenterZ = cellZ + dz + ((seed / 1000000) % 1000) / 1000
				
				local dist = math.sqrt((x - cellCenterX)^2 + (y - cellCenterY)^2 + (z - cellCenterZ)^2)
				minDist = math.min(minDist, dist)
			end
		end
	end
	
	return math.min(minDist, 1.0)
end

local function fallbackPerlin(x: number, y: number, z: number): number
	-- Simple gradient noise approximation
	return fallbackSimplex(x * 0.8, y * 0.8, z * 0.8) * 0.7 + fallbackSimplex(x * 1.6, y * 1.6, z * 1.6) * 0.3
end

function Core.getNoise3D(x: number, y: number, z: number, noiseType: string?): number
	if not noiseGenerator then
		log("WARNING", "Noise generator not initialized, using fallback")
		local nType = noiseType or "simplex"
		if nType == "worley" then
			return fallbackWorley(x, y, z)
		elseif nType == "perlin" then
			return fallbackPerlin(x, y, z)
		else
			return fallbackSimplex(x, y, z)
		end
	end

	local nType = noiseType or "simplex"
	
	-- Try NoiseLib methods with fallback on failure
	local success, result = pcall(function()
		if nType == "simplex" then
			if noiseGenerator.simplex3D then
				return noiseGenerator:simplex3D(x, y, z)
			elseif noiseGenerator.simplex then
				return noiseGenerator:simplex(x, y, z)
			else
				error("No simplex method available")
			end
		elseif nType == "worley" then
			if noiseGenerator.worley3D then
				return noiseGenerator:worley3D(x, y, z)
			elseif noiseGenerator.worley then
				return noiseGenerator:worley(x, y, z)
			else
				error("No worley method available")
			end
		elseif nType == "perlin" then
			if noiseGenerator.perlin3D then
				return noiseGenerator:perlin3D(x, y, z)
			elseif noiseGenerator.perlin then
				return noiseGenerator:perlin(x, y, z)
			else
				error("No perlin method available")
			end
		else
			-- Default to simplex
			if noiseGenerator.simplex3D then
				return noiseGenerator:simplex3D(x, y, z)
			else
				return noiseGenerator:simplex(x, y, z)
			end
		end
	end)
	
	if success then
		return result
	else
		log("WARNING", "NoiseLib method failed for " .. nType .. ", using fallback: " .. tostring(result))
		if nType == "worley" then
			return fallbackWorley(x, y, z)
		elseif nType == "perlin" then
			return fallbackPerlin(x, y, z)
		else
			return fallbackSimplex(x, y, z)
		end
	end
end

function Core.getFBM(x: number, y: number, z: number, settings: any): number
	if not noiseGenerator then
		log("WARNING", "Noise generator not initialized, using fallback FBM")
		-- Simple FBM fallback
		local octaves = (settings and settings.octaves) or 4
		local lacunarity = (settings and settings.lacunarity) or 2.0
		local persistence = (settings and settings.persistence) or 0.5
		
		local value = 0
		local amplitude = 1
		local frequency = 1
		local maxValue = 0
		
		for i = 1, octaves do
			value = value + fallbackSimplex(x * frequency, y * frequency, z * frequency) * amplitude
			maxValue = maxValue + amplitude
			amplitude = amplitude * persistence
			frequency = frequency * lacunarity
		end
		
		return value / maxValue
	end

	local success, result = pcall(function()
		if noiseGenerator.getFBM then
			return noiseGenerator:getFBM(x, y, z, settings)
		elseif noiseGenerator.fbm then
			return noiseGenerator:fbm(x, y, z, settings)
		else
			error("No FBM method available")
		end
	end)
	
	if success then
		return result
	else
		log("WARNING", "NoiseLib FBM failed, using fallback: " .. tostring(result))
		-- Fallback FBM implementation
		local octaves = (settings and settings.octaves) or 4
		local lacunarity = (settings and settings.lacunarity) or 2.0
		local persistence = (settings and settings.persistence) or 0.5
		
		local value = 0
		local amplitude = 1
		local frequency = 1
		local maxValue = 0
		
		for i = 1, octaves do
			value = value + Core.getNoise3D(x * frequency, y * frequency, z * frequency) * amplitude
			maxValue = maxValue + amplitude
			amplitude = amplitude * persistence
			frequency = frequency * lacunarity
		end
		
		return value / maxValue
	end
end

function Core.getRealisticCaves(x: number, y: number, z: number, settings: any): any
	if not noiseGenerator then
		log("WARNING", "Noise generator not initialized, using fallback cave generation")
		-- Fallback cave generation logic
		local primaryNoise = Core.getFBM(x * 0.02, y * 0.02, z * 0.02, {octaves = 4, persistence = 0.5})
		local threshold = (settings and settings.threshold) or 0.3
		return {
			isAir = primaryNoise > threshold,
			density = primaryNoise,
			material = primaryNoise > threshold and Enum.Material.Air or Enum.Material.Rock
		}
	end

	local success, result = pcall(function()
		if noiseGenerator.generateRealisticCaves then
			return noiseGenerator:generateRealisticCaves(x, y, z, settings)
		elseif noiseGenerator.realisticCaves then
			return noiseGenerator:realisticCaves(x, y, z, settings)
		else
			error("No realistic caves method available")
		end
	end)
	
	if success then
		return result
	else
		log("WARNING", "NoiseLib realistic caves failed, using fallback: " .. tostring(result))
		-- Fallback cave generation logic
		local primaryNoise = Core.getFBM(x * 0.02, y * 0.02, z * 0.02, {octaves = 4, persistence = 0.5})
		local threshold = (settings and settings.threshold) or 0.3
		return {
			isAir = primaryNoise > threshold,
			density = primaryNoise,
			material = primaryNoise > threshold and Enum.Material.Air or Enum.Material.Rock
		}
	end
end

-- ================================================================================================
--                                    TERRAIN OPERATIONS
-- ================================================================================================

local voxelData = {} -- Buffer for terrain operations
local voxelMaterials = {}

function Core.initializeTerrainBuffer(region: Region3): ()
	local success, err = pcall(function()
		local size = region.Size
		local resolution = config.Core.terrainResolution or 4
		
		-- Validate region size
		if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
			error("Invalid region size: " .. tostring(size))
		end

		-- Calculate voxel grid dimensions with reasonable limits
		local voxelsX = math.min(math.ceil(size.X / resolution), 500) -- Limit to prevent memory issues
		local voxelsY = math.min(math.ceil(size.Y / resolution), 500)
		local voxelsZ = math.min(math.ceil(size.Z / resolution), 500)
		
		-- Check memory requirements
		local totalVoxels = voxelsX * voxelsY * voxelsZ
		if totalVoxels > 50000000 then -- 50M voxels limit
			error(string.format("Terrain buffer too large: %d voxels (limit: 50M)", totalVoxels))
		end

		-- Clear existing buffers
		voxelData = nil
		voxelMaterials = nil
		local _ = gcinfo() -- gcinfo triggers garbage collection

		-- Initialize 3D arrays with error handling
		voxelData = {}
		voxelMaterials = {}

		for x = 1, voxelsX do
			voxelData[x] = {}
			voxelMaterials[x] = {}
			for y = 1, voxelsY do
				voxelData[x][y] = {}
				voxelMaterials[x][y] = {}
				for z = 1, voxelsZ do
					voxelData[x][y][z] = 1 -- 0 = air, 1 = solid (start with solid rock)
					voxelMaterials[x][y][z] = config.Core.materialRock or Enum.Material.Rock
				end
			end
			
			-- Yield every few rows to prevent timeout
			if x % 10 == 0 then
				task.wait()
			end
		end

		log("INFO", "Terrain buffer initialized successfully", {
			dimensions = string.format("%dx%dx%d", voxelsX, voxelsY, voxelsZ),
			totalVoxels = totalVoxels,
			resolution = resolution,
			memoryEstimate = string.format("%.2f MB", totalVoxels * 8 / 1024 / 1024) -- Rough estimate
		})
	end)
	
	if not success then
		log("ERROR", "Failed to initialize terrain buffer", err)
		-- Initialize minimal fallback buffer
		voxelData = {{{1}}}
		voxelMaterials = {{{Enum.Material.Rock}}}
		error("Terrain buffer initialization failed: " .. tostring(err))
	end
end

function Core.setVoxel(position: Vector3, isAir: boolean, material: Enum.Material?): ()
	-- Validate inputs
	if not position or typeof(position) ~= "Vector3" then
		return
	end
	
	if not voxelData or #voxelData == 0 then
		return
	end
	
	local resolution = config.Core.terrainResolution or 4
	local x = math.floor(position.X / resolution) + 1
	local y = math.floor(position.Y / resolution) + 1
	local z = math.floor(position.Z / resolution) + 1

	-- Enhanced bounds checking with validation
	local maxX = #voxelData
	local maxY = voxelData[1] and #voxelData[1] or 0
	local maxZ = voxelData[1] and voxelData[1][1] and #voxelData[1][1] or 0
	
	if x >= 1 and x <= maxX and 
		y >= 1 and y <= maxY and 
		z >= 1 and z <= maxZ then
		
		-- Additional safety check for array existence
		if voxelData[x] and voxelData[x][y] and voxelMaterials[x] and voxelMaterials[x][y] then
			voxelData[x][y][z] = if isAir then 0 else 1
			voxelMaterials[x][y][z] = material or 
				(if isAir then (config.Core.materialAir or Enum.Material.Air) 
				 else (config.Core.materialRock or Enum.Material.Rock))
		end
	end
end

function Core.applyTerrainChanges(region: Region3): ()
	if not voxelData or #voxelData == 0 then
		log("WARNING", "No voxel data to apply")
		return
	end

	local startTime = tick()
	local resolution = config.Core.terrainResolution or 4

	log("INFO", "Applying terrain changes to region", {
		size = region.Size,
		resolution = resolution
	})

	local success, err = pcall(function()
		-- Validate array dimensions thoroughly
		if not voxelData or #voxelData == 0 then
			error("voxelData is empty or nil")
		end
		if not voxelMaterials or #voxelMaterials == 0 then
			error("voxelMaterials is empty or nil")
		end
		
		-- Check array structure
		if not voxelData[1] then
			error("voxelData[1] is nil")
		end
		if not voxelData[1][1] then
			error("voxelData[1][1] is nil")
		end
		if not voxelMaterials[1] then
			error("voxelMaterials[1] is nil")
		end
		if not voxelMaterials[1][1] then
			error("voxelMaterials[1][1] is nil")
		end
		
		-- Check dimensions match expectations
		local expectedX = math.min(math.ceil(region.Size.X / resolution), 500)
		local expectedY = math.min(math.ceil(region.Size.Y / resolution), 500)
		local expectedZ = math.min(math.ceil(region.Size.Z / resolution), 500)
		
		local actualX = #voxelData
		local actualY = #voxelData[1]
		local actualZ = #voxelData[1][1]
		
		log("DEBUG", "Dimension check", {
			expected = string.format("%dx%dx%d", expectedX, expectedY, expectedZ),
			actual = string.format("%dx%dx%d", actualX, actualY, actualZ)
		})
		
		-- Allow some tolerance in dimensions due to rounding
		if math.abs(actualX - expectedX) > 1 then
			error(string.format("X dimension mismatch: expected ~%d, got %d", expectedX, actualX))
		end
		if math.abs(actualY - expectedY) > 1 then
			error(string.format("Y dimension mismatch: expected ~%d, got %d", expectedY, actualY))
		end
		if math.abs(actualZ - expectedZ) > 1 then
			error(string.format("Z dimension mismatch: expected ~%d, got %d", expectedZ, actualZ))
		end
		
		-- Validate region for WriteVoxels compatibility
		local minPoint = region.CFrame.Position - region.Size/2
		local alignedMin = Vector3.new(
			math.floor(minPoint.X / resolution) * resolution,
			math.floor(minPoint.Y / resolution) * resolution,
			math.floor(minPoint.Z / resolution) * resolution
		)
		local alignedSize = Vector3.new(
			actualX * resolution,
			actualY * resolution,
			actualZ * resolution
		)
		local alignedRegion = Region3.new(alignedMin, alignedMin + alignedSize)
		
		log("DEBUG", "Using aligned region for WriteVoxels", {
			original = region.Size,
			aligned = alignedSize,
			minPoint = alignedMin
		})
		
		-- Apply via WriteVoxels with the aligned region
		workspace.Terrain:WriteVoxels(
			alignedRegion,
			resolution,
			voxelMaterials,
			voxelData
		)
		
		log("DEBUG", "WriteVoxels completed successfully")
	end)

	local endTime = tick()
	
	if success then
		log("INFO", "Terrain changes applied successfully", {
			time = string.format("%.3f seconds", endTime - startTime),
			voxels = voxelData and (#voxelData * #voxelData[1] * #voxelData[1][1]) or 0
		})
	else
		log("ERROR", "Failed to apply terrain changes", {
			error = tostring(err),
			time = string.format("%.3f seconds", endTime - startTime)
		})
		
		-- Try fallback approach with smaller chunks
		local fallbackSuccess = pcall(function()
			log("INFO", "Attempting fallback terrain application...")
			-- Apply in smaller chunks to avoid WriteVoxels issues
			-- This is a simplified fallback - just clear some terrain manually
			local centerPos = region.CFrame.Position
			local size = region.Size
			
			-- Create a basic rectangular hollow
			local minPos = centerPos - size/2
			local maxPos = centerPos + size/2
			
			workspace.Terrain:FillRegion(
				Region3.new(minPos, maxPos),
				resolution,
				Enum.Material.Air
			)
		end)
		
		if fallbackSuccess then
			log("INFO", "Fallback terrain application succeeded")
		else
			log("ERROR", "Both primary and fallback terrain application failed")
		end
	end
end

-- ================================================================================================
--                                    PATHFINDING
-- ================================================================================================

function Core.findPath(startPos, endPos, maxSteps)
	-- Validate inputs
	if not startPos or not endPos or typeof(startPos) ~= "Vector3" or typeof(endPos) ~= "Vector3" then
		log("WARNING", "Invalid pathfinding inputs")
		return {startPos or Vector3.new(0,0,0), endPos or Vector3.new(0,0,0)}
	end
	
	maxSteps = maxSteps or 50
	maxSteps = math.max(5, math.min(maxSteps, 100)) -- Clamp to reasonable range

	-- Simple direct path for short distances to avoid pathfinding overhead
	local distance = (endPos - startPos).Magnitude
	if distance < 15 then
		return {startPos, endPos}
	end
	
	-- Handle zero distance
	if distance < 0.1 then
		return {startPos}
	end

	local success, path = pcall(function()
		-- Simplified pathfinding with adaptive step count
		local adaptiveSteps = math.min(maxSteps, math.max(5, math.floor(distance / 4)))
		local pathPoints = {startPos}
		local direction = (endPos - startPos).Unit
		local stepSize = distance / adaptiveSteps

		for i = 1, adaptiveSteps - 1 do
			local progress = i / adaptiveSteps
			local targetPos = startPos + direction * distance * progress

			-- Add some controlled curvature for more natural paths
			local curvature = math.sin(progress * math.pi) * math.min(5, distance * 0.1)
			local curveDirection = Vector3.new(-direction.Z, 0, direction.X) -- Perpendicular in XZ plane
			targetPos = targetPos + curveDirection * curvature
			
			-- Add slight vertical variation
			local verticalVariation = math.sin(progress * math.pi * 2) * 2
			targetPos = targetPos + Vector3.new(0, verticalVariation, 0)

			table.insert(pathPoints, targetPos)

			-- Yield occasionally to prevent lag (less frequently than before)
			if i % 10 == 0 then
				task.wait()
			end
		end

		-- Ensure end position is reached exactly
		table.insert(pathPoints, endPos)
		return pathPoints
	end)
	
	if success then
		return path
	else
		log("WARNING", "Pathfinding failed, using direct path: " .. tostring(path))
		-- Fallback to simple direct path
		return {startPos, endPos}
	end
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