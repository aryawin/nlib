--!strict

--[[
====================================================================================================
                                Simple Cave Generation for Roblox
                               Focused on Creating Beautiful Caves
====================================================================================================

This module implements a streamlined cave generation system that creates natural-looking,
connected cave systems without floating rocks or disconnected segments.

CORE FEATURES:
- 3D density field approach for smooth, connected caves
- Multi-scale noise for realistic tunnel and chamber structures
- Connectivity filtering to eliminate floating elements
- Simple API with good default settings
- Optimized for Terrain:WriteVoxels performance

DESIGN PRINCIPLES:
- Simplicity over complexity
- Visual quality over features
- Easy to use with immediate good results
- Clean, readable code

====================================================================================================
]]

local NoiseLib = require(script.Parent.NoiseLib)

local CaveGenerator = {}

-- ================================================================================================
--                                      TYPES & CONSTANTS
-- ================================================================================================

-- Simple cave settings - focused on what matters for good caves
export type CaveSettings = {
	-- Basic parameters
	caveThreshold: number?,      -- How dense caves should be (0.3-0.6, default 0.4)
	caveScale: number?,          -- Size of cave features (0.02-0.08, default 0.03)
	tunnelScale: number?,        -- Scale for main tunnels (0.01-0.05, default 0.025) 
	chamberScale: number?,       -- Scale for large chambers (0.05-0.15, default 0.08)
	
	-- Depth control
	minDepth: number?,           -- Minimum depth for caves (default -20)
	maxDepth: number?,           -- Maximum depth for caves (default -150)
	
	-- Feature generation
	generateStalactites: boolean?, -- Add cave decorations (default true)
	waterLevel: number?,         -- Y level for water (default -80)
	
	-- Performance
	resolution: number?,         -- Voxel resolution in studs (default 4)
	chunkSize: number?          -- Chunk size for processing (default 64)
}

export type CaveResult = {
	success: boolean,
	cavesGenerated: number?,
	featuresGenerated: number?,
	chunksProcessed: number?,
	error: string?
}

-- Material constants
local MATERIALS = {
	AIR = Enum.Material.Air,
	ROCK = Enum.Material.Rock,
	WATER = Enum.Material.Water,
	STALACTITE = Enum.Material.Concrete
}

-- Default settings that produce good caves immediately
local DEFAULT_SETTINGS = {
	caveThreshold = 0.4,
	caveScale = 0.03,
	tunnelScale = 0.025,
	chamberScale = 0.08,
	minDepth = -20,
	maxDepth = -150,
	generateStalactites = true,
	waterLevel = -80,
	resolution = 4,
	chunkSize = 64
}

-- ================================================================================================
--                                    CORE CAVE GENERATION
-- ================================================================================================

-- Generate a 3D density field that creates connected cave structures
local function generateCaveDensity(x: number, y: number, z: number, settings: CaveSettings, noiseGen: any): number
	-- Use multiple scales of noise to create realistic cave structures
	
	-- Large-scale chambers (creates big open spaces)
	local chambers = noiseGen:simplex3D(x * settings.chamberScale, y * settings.chamberScale, z * settings.chamberScale)
	
	-- Medium-scale tunnels (creates connecting passages)
	local tunnels = noiseGen:simplex3D(x * settings.tunnelScale, y * settings.tunnelScale * 0.5, z * settings.tunnelScale)
	
	-- Small-scale detail (adds roughness and variation)
	local detail = noiseGen:simplex3D(x * settings.caveScale * 3, y * settings.caveScale * 3, z * settings.caveScale * 3)
	
	-- Combine noise layers - this is the key to good cave structure
	-- We want caves to form where EITHER chambers OR tunnels are present
	local caveBase = math.max(chambers * 0.7, tunnels * 0.8) -- Max creates connections
	local caveValue = caveBase + detail * 0.2 -- Add small details
	
	-- Apply depth-based probability (caves more likely at mid-depths)
	local depthFactor = 1.0
	if y > settings.minDepth then
		-- Fewer caves near surface
		depthFactor = math.max(0.1, (settings.minDepth - y) / 20.0)
	elseif y < settings.maxDepth then
		-- Fewer caves at extreme depths
		depthFactor = math.max(0.1, (y - settings.maxDepth) / 30.0)
	end
	
	return caveValue * depthFactor
end

-- Check if a position should be air based on cave density
local function isPositionCave(x: number, y: number, z: number, settings: CaveSettings, noiseGen: any): boolean
	local density = generateCaveDensity(x, y, z, settings, noiseGen)
	return density > settings.caveThreshold
end

-- Remove isolated floating cave voxels by checking connectivity
local function isConnectedCave(x: number, y: number, z: number, settings: CaveSettings, noiseGen: any): boolean
	if not isPositionCave(x, y, z, settings, noiseGen) then
		return false
	end
	
	-- Check if at least 2 neighboring positions are also caves (ensures connectivity)
	local neighbors = 0
	local checks = {
		{-4, 0, 0}, {4, 0, 0},  -- X axis
		{0, -4, 0}, {0, 4, 0},  -- Y axis  
		{0, 0, -4}, {0, 0, 4}   -- Z axis
	}
	
	for _, offset in ipairs(checks) do
		if isPositionCave(x + offset[1], y + offset[2], z + offset[3], settings, noiseGen) then
			neighbors = neighbors + 1
			if neighbors >= 2 then
				return true -- Connected to at least 2 neighbors
			end
		end
	end
	
	return neighbors >= 1 -- Allow some endpoints, but not isolated voxels
end

-- ================================================================================================
--                                    CHUNK PROCESSING
-- ================================================================================================

-- Process a single chunk of terrain
local function processChunk(terrain: Terrain, chunkPos: Vector3, chunkSize: number, settings: CaveSettings, noiseGen: any): (number, number)
	local resolution = settings.resolution
	local voxelsPerAxis = math.ceil(chunkSize / resolution)
	
	-- Initialize 3D arrays for WriteVoxels
	local materials = {}
	local occupancies = {}
	
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
	
	-- Calculate chunk bounds
	local chunkMin = chunkPos - Vector3.new(chunkSize/2, chunkSize/2, chunkSize/2)
	local cavesInChunk = 0
	local featuresInChunk = 0
	
	-- Generate cave structure
	for vx = 1, voxelsPerAxis do
		for vy = 1, voxelsPerAxis do
			for vz = 1, voxelsPerAxis do
				-- Convert voxel indices to world position
				local worldX = chunkMin.X + (vx - 1) * resolution
				local worldY = chunkMin.Y + (vy - 1) * resolution
				local worldZ = chunkMin.Z + (vz - 1) * resolution
				
				-- Check if this should be a cave
				if isConnectedCave(worldX, worldY, worldZ, settings, noiseGen) then
					cavesInChunk = cavesInChunk + 1
					
					-- Determine material based on depth
					if worldY < settings.waterLevel then
						materials[vx][vy][vz] = MATERIALS.WATER
						occupancies[vx][vy][vz] = 0.8
					else
						materials[vx][vy][vz] = MATERIALS.AIR
						occupancies[vx][vy][vz] = 0.0
					end
				end
			end
		end
	end
	
	-- Apply terrain changes with WriteVoxels
	local region = Region3.new(chunkMin, chunkMin + Vector3.new(chunkSize, chunkSize, chunkSize))
	local success, error = pcall(function()
		terrain:WriteVoxels(region, resolution, materials, occupancies)
	end)
	
	if not success then
		warn("Failed to write terrain chunk:", error)
		return 0, 0
	end
	
	-- Add cave features if enabled
	if settings.generateStalactites and cavesInChunk > 5 then
		featuresInChunk = addCaveFeatures(terrain, chunkPos, chunkSize, settings, noiseGen)
	end
	
	return cavesInChunk, featuresInChunk
end

-- Add stalactites and other cave decorations
function addCaveFeatures(terrain: Terrain, chunkPos: Vector3, chunkSize: number, settings: CaveSettings, noiseGen: any): number
	local featuresAdded = 0
	local attempts = math.random(3, 8) -- Random number of feature attempts per chunk
	
	for i = 1, attempts do
		-- Random position within chunk
		local offsetX = (math.random() - 0.5) * chunkSize * 0.8
		local offsetY = (math.random() - 0.5) * chunkSize * 0.8
		local offsetZ = (math.random() - 0.5) * chunkSize * 0.8
		
		local featurePos = chunkPos + Vector3.new(offsetX, offsetY, offsetZ)
		
		-- Only add features in cave areas
		if isConnectedCave(featurePos.X, featurePos.Y, featurePos.Z, settings, noiseGen) then
			-- Use noise to determine feature type and size
			local featureNoise = noiseGen:simplex3D(featurePos.X * 0.1, featurePos.Y * 0.1, featurePos.Z * 0.1)
			
			if featureNoise > 0.3 then
				-- Create stalactite
				local length = 2 + math.abs(featureNoise) * 6
				local thickness = 0.5 + math.abs(featureNoise) * 1.5
				
				local success = pcall(function()
					terrain:FillBlock(
						CFrame.new(featurePos),
						Vector3.new(thickness, length, thickness),
						MATERIALS.STALACTITE
					)
				end)
				
				if success then
					featuresAdded = featuresAdded + 1
				end
			end
		end
	end
	
	return featuresAdded
end

-- ================================================================================================
--                                    MAIN GENERATION FUNCTION
-- ================================================================================================

function CaveGenerator.generateCaves(terrain: Terrain, region: Region3, caveSettings: CaveSettings?): CaveResult
	assert(typeof(terrain) == "Instance" and terrain:IsA("Terrain"), "First argument must be a Terrain instance")
	assert(typeof(region) == "Region3", "Second argument must be a Region3")
	
	-- Merge user settings with defaults
	local settings = {}
	for key, value in pairs(DEFAULT_SETTINGS) do
		settings[key] = value
	end
	if caveSettings then
		for key, value in pairs(caveSettings) do
			settings[key] = value
		end
	end
	
	-- Initialize noise generator
	local noiseGen = NoiseLib.new(math.random(1, 999999))
	
	-- Calculate processing chunks
	local regionSize = region.Size
	local regionCenter = region.CFrame.Position
	local chunkSize = settings.chunkSize
	
	local chunksX = math.ceil(regionSize.X / chunkSize)
	local chunksY = math.ceil(regionSize.Y / chunkSize)
	local chunksZ = math.ceil(regionSize.Z / chunkSize)
	local totalChunks = chunksX * chunksY * chunksZ
	
	print("🕳️ Generating caves in", totalChunks, "chunks...")
	
	local totalCaves = 0
	local totalFeatures = 0
	local chunksProcessed = 0
	
	-- Process each chunk
	local regionMin = regionCenter - regionSize / 2
	
	local success, error = pcall(function()
		for cx = 1, chunksX do
			for cy = 1, chunksY do
				for cz = 1, chunksZ do
					-- Calculate chunk position
					local chunkOffset = Vector3.new(
						(cx - 1) * chunkSize + chunkSize/2,
						(cy - 1) * chunkSize + chunkSize/2,
						(cz - 1) * chunkSize + chunkSize/2
					)
					local chunkPos = regionMin + chunkOffset
					
					-- Process this chunk
					local caves, features = processChunk(terrain, chunkPos, chunkSize, settings, noiseGen)
					totalCaves = totalCaves + caves
					totalFeatures = totalFeatures + features
					chunksProcessed = chunksProcessed + 1
					
					-- Progress update
					if chunksProcessed % 4 == 0 then
						print(string.format("Progress: %d/%d chunks (%d caves generated)", 
							chunksProcessed, totalChunks, totalCaves))
						task.wait() -- Yield to prevent timeout
					end
				end
			end
		end
	end)
	
	-- Cleanup
	if noiseGen.cleanup then
		noiseGen:cleanup()
	end
	
	if success then
		print("✅ Cave generation complete!")
		print("📊 Generated", totalCaves, "cave voxels and", totalFeatures, "features")
		
		return {
			success = true,
			cavesGenerated = totalCaves,
			featuresGenerated = totalFeatures,
			chunksProcessed = chunksProcessed
		}
	else
		warn("❌ Cave generation failed:", error)
		return {
			success = false,
			error = tostring(error)
		}
	end
end

-- ================================================================================================
--                                    PRESET CONFIGURATIONS
-- ================================================================================================

CaveGenerator.Presets = {
	-- Small test cave for development
	SMALL_TEST = {
		caveThreshold = 0.35,
		caveScale = 0.04,
		tunnelScale = 0.03,
		chamberScale = 0.1,
		generateStalactites = true
	},
	
	-- Dense cave network
	DENSE_CAVES = {
		caveThreshold = 0.3,
		caveScale = 0.025,
		tunnelScale = 0.02,
		chamberScale = 0.06,
		generateStalactites = true
	},
	
	-- Large open caverns
	BIG_CAVERNS = {
		caveThreshold = 0.45,
		caveScale = 0.02,
		tunnelScale = 0.015,
		chamberScale = 0.04,
		generateStalactites = true
	},
	
	-- Performance optimized (fewer details)
	FAST_GENERATION = {
		caveThreshold = 0.4,
		caveScale = 0.035,
		tunnelScale = 0.025,
		chamberScale = 0.08,
		generateStalactites = false,
		resolution = 8, -- Lower resolution for speed
		chunkSize = 128
	}
}

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function CaveGenerator.createTestRegion(centerPosition: Vector3?, size: Vector3?): Region3
	local center = centerPosition or Vector3.new(0, -64, 0)
	local regionSize = size or Vector3.new(128, 80, 128)
	local halfSize = regionSize / 2
	
	return Region3.new(center - halfSize, center + halfSize)
end

function CaveGenerator.clearTerrain(terrain: Terrain, region: Region3)
	terrain:FillRegion(region, 4, Enum.Material.Air)
	print("✅ Terrain cleared")
end

return CaveGenerator