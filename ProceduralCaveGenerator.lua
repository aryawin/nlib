--!strict

--[[
====================================================================================================
                                Procedural Cave Generation Algorithm
                                    Complete Roblox Cave System
                                    Powered by NoiseLib v2.3
====================================================================================================

This module implements a comprehensive 5-stage procedural cave generation algorithm that fully
utilizes the NoiseLib module's capabilities to generate complex, realistic cave systems in Roblox.

ALGORITHM STAGES:
1. Abstract Data Generation - Create 3D caveGrid using NoiseLib at 4-stud resolution
2. Logical Structure Analysis - Analyze networks, entrances, and water flow
3. Terrain Voxel Preparation - Prepare materials and occupancies arrays
4. Voxel Data Rendering - Single Terrain:WriteVoxels call per chunk
5. Detailed Feature Placement - Secondary pass for geological features

PERFORMANCE FEATURES:
- Optimized for Terrain:WriteVoxels performance
- Chunk-based processing with progress reporting
- Memory management and error handling
- Debug visualization capabilities
- Configurable parameters for different cave styles

====================================================================================================
]]

local NoiseLib = require(script.Parent.NoiseLib)

local ProceduralCaveGenerator = {}

-- ================================================================================================
--                                      TYPES & CONSTANTS
-- ================================================================================================

-- Generation constants
local CHUNK_SIZE: number = 64 -- Studs per chunk for WriteVoxels
local RESOLUTION: number = 4 -- Studs per voxel (4-stud resolution as specified)
local VOXELS_PER_CHUNK: number = CHUNK_SIZE / RESOLUTION

-- Material constants
local MATERIALS = {
	AIR = Enum.Material.Air,
	ROCK = Enum.Material.Rock,
	WATER = Enum.Material.Water,
	LAVA = Enum.Material.CrackedLava,
	CRYSTAL = Enum.Material.Neon
}

-- Feature generation constants
local FEATURE_TYPES = {
	STALACTITE = "stalactite",
	STALAGMITE = "stalagmite", 
	CRYSTAL_FORMATION = "crystals",
	UNDERGROUND_POOL = "pool",
	CAVE_DECORATION = "decoration"
}

export type GenerationProgress = {
	stage: string,
	progress: number,
	details: string?,
	chunksCompleted: number?,
	totalChunks: number?
}

export type CaveGenerationSettings = {
	-- Basic settings
	region: Region3,
	chunkSize: number?,
	resolution: number?,
	
	-- NoiseLib settings
	caveSettings: NoiseLib.CaveSettings?,
	surfaceSettings: NoiseLib.NoiseSettings?,
	
	-- Generation options
	generateFeatures: boolean?,
	generateWaterFlow: boolean?,
	generateEntrances: boolean?,
	
	-- Performance settings
	enableProgressReporting: boolean?,
	enableDebugVisualization: boolean?,
	memoryOptimized: boolean?
}

export type CaveChunkData = {
	position: Vector3,
	size: Vector3,
	caves: {NoiseLib.CaveData},
	materials: {{{Enum.Material}}},
	occupancies: {{{number}}},
	features: {NoiseLib.CaveFeature}
}

export type GenerationResult = {
	success: boolean,
	chunks: {CaveChunkData}?,
	totalCaves: number?,
	totalFeatures: number?,
	totalEntrances: number?,
	waterFlowPaths: {NoiseLib.FlowPath}?,
	entrances: {NoiseLib.CaveEntrance}?,
	error: string?,
	performanceStats: NoiseLib.PerformanceStats?
}

export type DebugVisualization = {
	cavePoints: {Vector3},
	entrancePoints: {Vector3},
	featurePoints: {Vector3},
	waterFlowLines: {{Vector3}}
}

-- ================================================================================================
--                                  INTERNAL VALIDATION FUNCTIONS
-- ================================================================================================

local function validateCaveSettings(settings)
	local s = settings or {}
	
	-- Validate ranges with proper nil checks
	if s.threshold then
		assert(s.threshold >= -1 and s.threshold <= 1, "Threshold must be between -1 and 1")
	end
	if s.optimalDepth then
		assert(s.optimalDepth < 0, "Optimal depth must be below surface (negative)")
	end
	if s.depthRange then
		assert(s.depthRange > 0, "Depth range must be positive")
	end
	if s.connectivity then
		assert(s.connectivity >= 0 and s.connectivity <= 1, "Connectivity must be between 0 and 1")
	end

	return {
		threshold = s.threshold or 0.3,
		optimalDepth = s.optimalDepth or -60,
		depthRange = s.depthRange or 40,
		tunnelScale = math.max(0.001, s.tunnelScale or 0.02),
		chamberScale = math.max(0.001, s.chamberScale or 0.05),
		connectivity = math.max(0, math.min(1, s.connectivity or 0.7)),
		waterLevel = s.waterLevel or -50,
		lavaLevel = s.lavaLevel or -150,
		weightMainTunnels = s.weightMainTunnels or 0.6,
		weightChambers = s.weightChambers or 0.3,
		weightVerticalShafts = s.weightVerticalShafts or 0.1,
		scaleVerticality = s.scaleVerticality or 0.015,
		scaleDetail = s.scaleDetail or 0.2,
	}
end

-- ================================================================================================
--                                  STAGE 1: ABSTRACT DATA GENERATION
-- ================================================================================================

local function generateCaveGrid(generator: NoiseLib.NoiseGenerator, region: Region3, settings: NoiseLib.ValidatedCaveSettings, resolution: number, progressCallback: NoiseLib.ProgressCallback?): {NoiseLib.CaveData}
	local caves: {NoiseLib.CaveData} = {}
	local callback = progressCallback or function() end
	
	-- Get region bounds
	local center = region.CFrame.Position
	local size = region.Size
	local halfSize = size * 0.5
	local minPoint = center - halfSize
	local maxPoint = center + halfSize
	
	-- Calculate total voxels for progress tracking
	local totalVoxels = math.ceil((maxPoint.X - minPoint.X) / resolution) * 
					   math.ceil((maxPoint.Y - minPoint.Y) / resolution) * 
					   math.ceil((maxPoint.Z - minPoint.Z) / resolution)
	local processedVoxels = 0
	
	print("🗻 Stage 1: Generating cave grid at", resolution, "stud resolution")
	print("📊 Processing", totalVoxels, "voxels in region", region.Size)
	
	local x = minPoint.X
	while x <= maxPoint.X do
		local y = minPoint.Y
		while y <= maxPoint.Y do
			local z = minPoint.Z
			while z <= maxPoint.Z do
				-- Generate cave data using NoiseLib's generateRealisticCaves
				local caveData = generator:generateRealisticCaves(x, y, z, settings)
				
				if caveData.isAir then
					caves[#caves + 1] = caveData
				end
				
				processedVoxels = processedVoxels + 1
				z = z + resolution
			end
			y = y + resolution
		end
		
		-- Progress reporting and yielding
		local progress = processedVoxels / totalVoxels
		callback(progress * 0.6, "Stage 1: Abstract Data Generation", 
				string.format("Generated %d cave points (%d/%d voxels)", #caves, processedVoxels, totalVoxels))
		
		-- Yield periodically to prevent timeout
		if (x - minPoint.X) % (32 * resolution) == 0 then
			task.wait()
		end
		
		x = x + resolution
	end
	
	print("✅ Stage 1 Complete: Generated", #caves, "cave data points")
	return caves
end

-- ================================================================================================
--                                STAGE 2: LOGICAL STRUCTURE ANALYSIS  
-- ================================================================================================

local function analyzeCaveStructures(generator: NoiseLib.NoiseGenerator, caves: {NoiseLib.CaveData}, settings: NoiseLib.ValidatedCaveSettings, progressCallback: NoiseLib.ProgressCallback?): ({{NoiseLib.CaveData}}, {NoiseLib.CaveEntrance}, {NoiseLib.FlowPath})
	local callback = progressCallback or function() end
	
	print("🔍 Stage 2: Analyzing cave structures")
	
	-- Step 1: Analyze cave networks
	callback(0.6, "Stage 2: Network Analysis", "Finding interconnected cave systems...")
	local networks = generator:analyzeCaveNetworks(caves, settings)
	print("🌐 Found", #networks, "cave networks")
	
	-- Step 2: Find cave entrances  
	callback(0.65, "Stage 2: Entrance Detection", "Locating surface openings...")
	local entrances = generator:findCaveEntrances(caves)
	print("🚪 Found", #entrances, "potential cave entrances")
	
	-- Step 3: Simulate water flow
	callback(0.7, "Stage 2: Water Flow Simulation", "Calculating erosion patterns...")
	local waterFlow = generator:simulateWaterFlow(caves, 75)
	print("💧 Generated", #waterFlow, "water flow paths")
	
	print("✅ Stage 2 Complete: Analyzed", #networks, "networks,", #entrances, "entrances,", #waterFlow, "flow paths")
	return networks, entrances, waterFlow
end

-- ================================================================================================
--                               STAGE 3: TERRAIN VOXEL PREPARATION
-- ================================================================================================

local function prepareChunkVoxelData(caves: {NoiseLib.CaveData}, chunkPosition: Vector3, chunkSize: Vector3, resolution: number): (CaveChunkData)
	local voxelsPerAxis = math.ceil(chunkSize.X / resolution)
	
	-- Initialize 3D arrays for materials and occupancies
	local materials: {{{Enum.Material}}} = {}
	local occupancies: {{{number}}} = {}
	local chunkCaves: {NoiseLib.CaveData} = {}
	
	-- Initialize arrays
	for x = 1, voxelsPerAxis do
		materials[x] = {}
		occupancies[x] = {}
		for y = 1, voxelsPerAxis do
			materials[x][y] = {}
			occupancies[x][y] = {}
			for z = 1, voxelsPerAxis do
				materials[x][y][z] = MATERIALS.ROCK
				occupancies[x][y][z] = 1.0
			end
		end
	end
	
	-- Process caves within this chunk
	local chunkMin = chunkPosition - chunkSize * 0.5
	local chunkMax = chunkPosition + chunkSize * 0.5
	
	for _, cave in pairs(caves) do
		local pos = cave.position
		
		-- Check if cave is within chunk bounds
		if pos.X >= chunkMin.X and pos.X <= chunkMax.X and
		   pos.Y >= chunkMin.Y and pos.Y <= chunkMax.Y and
		   pos.Z >= chunkMin.Z and pos.Z <= chunkMax.Z then
			
			chunkCaves[#chunkCaves + 1] = cave
			
			-- Convert world position to voxel indices
			local voxelX = math.floor((pos.X - chunkMin.X) / resolution) + 1
			local voxelY = math.floor((pos.Y - chunkMin.Y) / resolution) + 1
			local voxelZ = math.floor((pos.Z - chunkMin.Z) / resolution) + 1
			
			-- Clamp to valid array bounds
			voxelX = math.max(1, math.min(voxelsPerAxis, voxelX))
			voxelY = math.max(1, math.min(voxelsPerAxis, voxelY))
			voxelZ = math.max(1, math.min(voxelsPerAxis, voxelZ))
			
			-- Set material based on cave contents
			if cave.isAir then
				if cave.contents == "water" then
					materials[voxelX][voxelY][voxelZ] = MATERIALS.WATER
					occupancies[voxelX][voxelY][voxelZ] = 0.8
				elseif cave.contents == "lava" then
					materials[voxelX][voxelY][voxelZ] = MATERIALS.LAVA
					occupancies[voxelX][voxelY][voxelZ] = 0.9
				else
					materials[voxelX][voxelY][voxelZ] = MATERIALS.AIR
					occupancies[voxelX][voxelY][voxelZ] = 0.0
				end
			end
		end
	end
	
	return {
		position = chunkPosition,
		size = chunkSize,
		caves = chunkCaves,
		materials = materials,
		occupancies = occupancies,
		features = {}
	}
end

-- ================================================================================================
--                                STAGE 4: VOXEL DATA RENDERING
-- ================================================================================================

local function renderTerrainChunk(terrain: Terrain, chunkData: CaveChunkData, resolution: number, progressCallback: NoiseLib.ProgressCallback?): boolean
	local callback = progressCallback or function() end
	
	local success, result = pcall(function()
		-- Create Region3 for this chunk
		local chunkMin = chunkData.position - chunkData.size * 0.5
		local chunkMax = chunkData.position + chunkData.size * 0.5
		
		local region = Region3.new(chunkMin, chunkMax)
		
		-- Call Terrain:WriteVoxels with the prepared data
		terrain:WriteVoxels(region, resolution, chunkData.materials, chunkData.occupancies)
		
		return true
	end)
	end)
	
	if not success then
		warn("❌ Failed to render terrain chunk at", chunkData.position, ":", result)
		return false
	end
	
	return true
end

-- ================================================================================================
--                              STAGE 5: DETAILED FEATURE PLACEMENT
-- ================================================================================================

local function generateAndPlaceFeatures(generator: NoiseLib.NoiseGenerator, terrain: Terrain, chunkData: CaveChunkData, progressCallback: NoiseLib.ProgressCallback?): {NoiseLib.CaveFeature}
	local callback = progressCallback or function() end
	local allFeatures: {NoiseLib.CaveFeature} = {}
	
	-- Generate features for each cave in the chunk
	for i, cave in pairs(chunkData.caves) do
		local features = generator:generateCaveFeatures(cave, cave.position)
		
		-- Place each feature using appropriate Terrain methods
		for _, feature in pairs(features) do
			allFeatures[#allFeatures + 1] = feature
			
			local success, result = pcall(function()
				if feature.type == FEATURE_TYPES.STALACTITE then
					-- Create stalactite using FillBlock
					local size = Vector3.new(feature.thickness or 1, feature.length or 3, feature.thickness or 1)
					local cframe = CFrame.new(feature.position)
					terrain:FillBlock(cframe, size, MATERIALS.ROCK)
					
				elseif feature.type == FEATURE_TYPES.STALAGMITE then
					-- Create stalagmite using FillBlock
					local size = Vector3.new(feature.thickness or 1, feature.length or 2, feature.thickness or 1)
					local cframe = CFrame.new(feature.position)
					terrain:FillBlock(cframe, size, MATERIALS.ROCK)
					
				elseif feature.type == FEATURE_TYPES.CRYSTAL_FORMATION then
					-- Create crystal formation using FillBall
					local radius = 1 + (feature.count or 5) * 0.2
					terrain:FillBall(feature.position, radius, MATERIALS.CRYSTAL)
					
				elseif feature.type == FEATURE_TYPES.UNDERGROUND_POOL then
					-- Create underground pool using FillBall
					local radius = feature.radius or 3
					terrain:FillBall(feature.position, radius, MATERIALS.WATER)
				end
			end)
			end)
			
			if not success then
				warn("⚠️ Failed to place feature", feature.type, "at", feature.position, ":", result)
			end
		end
		
		-- Progress reporting
		if i % 10 == 0 then
			local featureProgress = i / #chunkData.caves
			callback(0.9 + featureProgress * 0.1, "Stage 5: Feature Placement", 
					string.format("Placed %d features (%d/%d caves)", #allFeatures, i, #chunkData.caves))
		end
	end
	
	return allFeatures
end

-- ================================================================================================
--                                   MAIN GENERATION FUNCTION
-- ================================================================================================

function ProceduralCaveGenerator.generateCaveSystem(terrain: Terrain, settings: CaveGenerationSettings, progressCallback: NoiseLib.ProgressCallback?): GenerationResult
	assert(typeof(terrain) == "Instance" and terrain:IsA("Terrain"), "First argument must be a Terrain instance")
	assert(type(settings) == "table", "Settings must be a table")
	assert(typeof(settings.region) == "Region3", "Settings must include a valid Region3")
	
	local callback = progressCallback or function() end
	local startTime = os.clock()
	
	print("🎯 Starting Procedural Cave Generation")
	print("📏 Region Size:", settings.region.Size)
	
	-- Initialize NoiseLib generator with high-performance configuration
	local generator = NoiseLib.new(settings.caveSettings and settings.caveSettings.seed or 12345, NoiseLib.Presets.CONFIG_HIGH_PERFORMANCE)
	
	-- Validate and prepare settings
	local chunkSize = settings.chunkSize or CHUNK_SIZE
	local resolution = settings.resolution or RESOLUTION
	local caveSettings = validateCaveSettings(settings.caveSettings)
	
	local totalResult: GenerationResult = {
		success = false,
		chunks = {},
		totalCaves = 0,
		totalFeatures = 0,
		totalEntrances = 0,
		waterFlowPaths = {},
		entrances = {}
	}
	
	local success, result = pcall(function()
		-- =====================================================================================
		-- STAGE 1: Abstract Data Generation
		-- =====================================================================================
		callback(0, "Stage 1: Abstract Data Generation", "Initializing cave grid generation...")
		local caves = generateCaveGrid(generator, settings.region, caveSettings, resolution, callback)
		totalResult.totalCaves = #caves
		
		-- =====================================================================================
		-- STAGE 2: Logical Structure Analysis  
		-- =====================================================================================
		local networks, entrances, waterFlow = analyzeCaveStructures(generator, caves, caveSettings, callback)
		totalResult.totalEntrances = #entrances
		totalResult.waterFlowPaths = waterFlow
		totalResult.entrances = entrances
		
		-- =====================================================================================
		-- STAGE 3 & 4: Chunk-based Voxel Preparation and Rendering
		-- =====================================================================================
		callback(0.7, "Stage 3: Voxel Preparation", "Dividing region into chunks...")
		
		-- Calculate chunks needed
		local regionSize = settings.region.Size
		local chunksX = math.ceil(regionSize.X / chunkSize)
		local chunksY = math.ceil(regionSize.Y / chunkSize) 
		local chunksZ = math.ceil(regionSize.Z / chunkSize)
		local totalChunks = chunksX * chunksY * chunksZ
		
		print("📦 Processing", totalChunks, "chunks of size", chunkSize)
		
		local processedChunks = 0
		local regionCenter = settings.region.CFrame.Position
		local regionMin = regionCenter - regionSize * 0.5
		
		for x = 1, chunksX do
			for y = 1, chunksY do
				for z = 1, chunksZ do
					-- Calculate chunk position
					local chunkOffset = Vector3.new(
						(x - 1) * chunkSize + chunkSize * 0.5,
						(y - 1) * chunkSize + chunkSize * 0.5,
						(z - 1) * chunkSize + chunkSize * 0.5
					)
					local chunkPosition = regionMin + chunkOffset
					local chunkSizeVector = Vector3.new(chunkSize, chunkSize, chunkSize)
					
					-- Stage 3: Prepare voxel data for this chunk
					local chunkData = prepareChunkVoxelData(caves, chunkPosition, chunkSizeVector, resolution)
					
					-- Stage 4: Render terrain using single WriteVoxels call
					local renderSuccess = renderTerrainChunk(terrain, chunkData, resolution, callback)
					
					if renderSuccess then
						-- Stage 5: Generate and place detailed features (if enabled)
						if settings.generateFeatures ~= false then
							local features = generateAndPlaceFeatures(generator, terrain, chunkData, callback)
							chunkData.features = features
							totalResult.totalFeatures = totalResult.totalFeatures + #features
						end
						
						totalResult.chunks[#totalResult.chunks + 1] = chunkData
					end
					
					processedChunks = processedChunks + 1
					local chunkProgress = processedChunks / totalChunks
					callback(0.7 + chunkProgress * 0.3, "Processing Chunks", 
							string.format("Completed chunk %d/%d", processedChunks, totalChunks))
					
					-- Yield periodically
					if processedChunks % 4 == 0 then
						task.wait()
					end
				end
			end
		end
		
		return true
	end)
	end)
	
	local endTime = os.clock()
	local generationTime = endTime - startTime
	
	if success then
		totalResult.success = true
		totalResult.performanceStats = generator:getPerformanceStats()
		
		callback(1.0, "Generation Complete", string.format("Generated %d caves, %d features, %d entrances in %.2fs", 
			totalResult.totalCaves, totalResult.totalFeatures, totalResult.totalEntrances, generationTime))
		
		print("🎉 Cave Generation Complete!")
		print("📊 Final Stats:")
		print("   • Caves:", totalResult.totalCaves)
		print("   • Features:", totalResult.totalFeatures) 
		print("   • Entrances:", totalResult.totalEntrances)
		print("   • Chunks:", #totalResult.chunks)
		print("   • Generation Time:", string.format("%.2fs", generationTime))
	else
		totalResult.success = false
		totalResult.error = "Generation failed: " .. tostring(result)
		warn("❌ Cave generation failed:", result)
	end
	
	-- Cleanup
	generator:cleanup()
	
	return totalResult
end

-- ================================================================================================
--                                    DEBUG VISUALIZATION
-- ================================================================================================

function ProceduralCaveGenerator.generateDebugVisualization(result: GenerationResult): DebugVisualization?
	if not result.success or not result.chunks then
		return nil
	end
	
	local viz: DebugVisualization = {
		cavePoints = {},
		entrancePoints = {},
		featurePoints = {},
		waterFlowLines = {}
	}
	
	-- Collect cave points
	for _, chunk in pairs(result.chunks) do
		for _, cave in pairs(chunk.caves) do
			viz.cavePoints[#viz.cavePoints + 1] = cave.position
		end
		
		-- Collect feature points
		for _, feature in pairs(chunk.features) do
			viz.featurePoints[#viz.featurePoints + 1] = feature.position
		end
	end
	
	-- Collect entrance points
	if result.entrances then
		for _, entrance in pairs(result.entrances) do
			viz.entrancePoints[#viz.entrancePoints + 1] = entrance.position
		end
	end
	
	-- Collect water flow lines
	if result.waterFlowPaths then
		for _, flow in pairs(result.waterFlowPaths) do
			viz.waterFlowLines[#viz.waterFlowLines + 1] = flow.path
		end
	end
	
	return viz
end

-- ================================================================================================
--                                    PRESET CONFIGURATIONS
-- ================================================================================================

ProceduralCaveGenerator.Presets = {
	-- Small scale testing
	SMALL_TEST_CAVE = {
		region = Region3.new(Vector3.new(-32, -64, -32), Vector3.new(32, 0, 32)),
		chunkSize = 32,
		resolution = 4,
		caveSettings = NoiseLib.Presets.CAVES_SPARSE,
		generateFeatures = true,
		generateWaterFlow = true,
		generateEntrances = true,
		enableProgressReporting = true
	},
	
	-- Medium realistic cave system
	REALISTIC_CAVE_SYSTEM = {
		region = Region3.new(Vector3.new(-128, -128, -128), Vector3.new(128, 0, 128)),
		chunkSize = 64,
		resolution = 4, 
		caveSettings = NoiseLib.Presets.CAVES_SPARSE,
		generateFeatures = true,
		generateWaterFlow = true,
		generateEntrances = true,
		enableProgressReporting = true
	},
	
	-- Large dense cave network
	MASSIVE_CAVE_NETWORK = {
		region = Region3.new(Vector3.new(-256, -200, -256), Vector3.new(256, 0, 256)),
		chunkSize = 64,
		resolution = 4,
		caveSettings = NoiseLib.Presets.CAVES_DENSE,
		generateFeatures = true,
		generateWaterFlow = true,
		generateEntrances = true,
		enableProgressReporting = true,
		memoryOptimized = true
	},
	
	-- Performance optimized (minimal features)
	PERFORMANCE_OPTIMIZED = {
		region = Region3.new(Vector3.new(-128, -128, -128), Vector3.new(128, 0, 128)),
		chunkSize = 128,
		resolution = 8,
		caveSettings = NoiseLib.Presets.CAVES_SPARSE,
		generateFeatures = false,
		generateWaterFlow = false,
		generateEntrances = true,
		enableProgressReporting = false,
		memoryOptimized = true
	}
}

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function ProceduralCaveGenerator.validateSettings(settings: CaveGenerationSettings): boolean
	if type(settings) ~= "table" then
		return false
	end
	
	if typeof(settings.region) ~= "Region3" then
		return false
	end
	
	-- Validate region size isn't too large
	local size = settings.region.Size
	local maxSize = 1024
	if size.X > maxSize or size.Y > maxSize or size.Z > maxSize then
		warn("⚠️ Region size is very large:", size, "- consider using smaller chunks or lower resolution")
	end
	
	return true
end

function ProceduralCaveGenerator.estimateMemoryUsage(settings: CaveGenerationSettings): number
	if not ProceduralCaveGenerator.validateSettings(settings) then
		return -1
	end
	
	local regionSize = settings.region.Size
	local resolution = settings.resolution or RESOLUTION
	local chunkSize = settings.chunkSize or CHUNK_SIZE
	
	-- Estimate voxel count
	local totalVoxels = (regionSize.X / resolution) * (regionSize.Y / resolution) * (regionSize.Z / resolution)
	local chunksCount = math.ceil(regionSize.X / chunkSize) * math.ceil(regionSize.Y / chunkSize) * math.ceil(regionSize.Z / chunkSize)
	
	-- Rough memory estimate (bytes)
	local voxelMemory = totalVoxels * 8 -- Each voxel needs material + occupancy
	local caveDataMemory = totalVoxels * 0.1 * 100 -- Estimate 10% caves, 100 bytes each
	local chunkMemory = chunksCount * 1000 -- Chunk overhead
	
	return voxelMemory + caveDataMemory + chunkMemory
end

return ProceduralCaveGenerator