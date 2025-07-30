--!strict

--[[
====================================================================================================
                               Simple Cave Generation Examples
                                Easy-to-Use Demonstrations
====================================================================================================

This script demonstrates how to use the simplified CaveGenerator to create beautiful,
natural-looking cave systems in Roblox with minimal code and immediate good results.

EXAMPLES INCLUDED:
- Basic cave generation with good defaults
- Different cave styles (dense, sparse, big caverns)
- Simple progress reporting
- Easy terrain cleanup
- Quick testing functions

====================================================================================================
]]

local CaveGenerator = require(script.Parent.ProceduralCaveGenerator)

local CaveExamples = {}

-- ================================================================================================
--                                   SIMPLE EXAMPLE FUNCTIONS
-- ================================================================================================

-- Generate a basic cave system with good defaults - just works!
function CaveExamples.generateBasicCaves(terrain: Terrain, centerPos: Vector3?): boolean
	print("🕳️ Generating basic cave system...")
	
	-- Create test region centered at specified position (or default)
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(128, 80, 128))
	
	-- Generate caves with default settings (they're already good!)
	local result = CaveGenerator.generateCaves(terrain, region)
	
	if result.success then
		print("✅ Success! Generated", result.cavesGenerated, "cave voxels and", result.featuresGenerated, "features")
		return true
	else
		warn("❌ Failed:", result.error)
		return false
	end
end

-- Generate dense caves for more complex cave networks
function CaveExamples.generateDenseCaves(terrain: Terrain, centerPos: Vector3?): boolean
	print("🕳️ Generating dense cave network...")
	
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(128, 80, 128))
	
	-- Use the dense caves preset
	local result = CaveGenerator.generateCaves(terrain, region, CaveGenerator.Presets.DENSE_CAVES)
	
	if result.success then
		print("✅ Success! Generated", result.cavesGenerated, "cave voxels and", result.featuresGenerated, "features")
		return true
	else
		warn("❌ Failed:", result.error)
		return false
	end
end

-- Generate large open caverns
function CaveExamples.generateBigCaverns(terrain: Terrain, centerPos: Vector3?): boolean
	print("🕳️ Generating big caverns...")
	
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(160, 100, 160))
	
	-- Use the big caverns preset
	local result = CaveGenerator.generateCaves(terrain, region, CaveGenerator.Presets.BIG_CAVERNS)
	
	if result.success then
		print("✅ Success! Generated", result.cavesGenerated, "cave voxels and", result.featuresGenerated, "features")
		return true
	else
		warn("❌ Failed:", result.error)
		return false
	end
end

-- Fast generation for testing (lower quality but quick)
function CaveExamples.generateQuickTest(terrain: Terrain, centerPos: Vector3?): boolean
	print("⚡ Generating quick test caves...")
	
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(96, 64, 96))
	
	-- Use the fast generation preset
	local result = CaveGenerator.generateCaves(terrain, region, CaveGenerator.Presets.FAST_GENERATION)
	
	if result.success then
		print("✅ Success! Generated", result.cavesGenerated, "cave voxels")
		return true
	else
		warn("❌ Failed:", result.error)
		return false
	end
end

-- Custom cave settings example
function CaveExamples.generateCustomCaves(terrain: Terrain, centerPos: Vector3?): boolean
	print("🛠️ Generating custom cave system...")
	
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(128, 80, 128))
	
	-- Custom settings for unique caves
	local customSettings = {
		caveThreshold = 0.35,     -- Slightly easier to form caves
		caveScale = 0.025,        -- Smaller cave features
		tunnelScale = 0.02,       -- Smaller tunnels 
		chamberScale = 0.06,      -- Medium chambers
		minDepth = -30,           -- Caves start closer to surface
		maxDepth = -120,          -- Don't go too deep
		generateStalactites = true,
		waterLevel = -70,
		resolution = 4            -- Good quality
	}
	
	local result = CaveGenerator.generateCaves(terrain, region, customSettings)
	
	if result.success then
		print("✅ Success! Generated", result.cavesGenerated, "cave voxels and", result.featuresGenerated, "features")
		return true
	else
		warn("❌ Failed:", result.error)
		return false
	end
end

-- ================================================================================================
--                                   UTILITY FUNCTIONS
-- ================================================================================================

-- Clear terrain in a test area
function CaveExamples.clearTestArea(terrain: Terrain, centerPos: Vector3?)
	local center = centerPos or Vector3.new(0, -64, 0)
	local region = CaveGenerator.createTestRegion(center, Vector3.new(200, 120, 200))
	
	print("🧹 Clearing test area...")
	CaveGenerator.clearTerrain(terrain, region)
end

-- Run a quick demo of all cave types
function CaveExamples.runDemo(terrain: Terrain)
	print("🎮 Running Cave Generation Demo...")
	print("=" .. string.rep("=", 50))
	
	-- Test different cave types in different areas
	local testPositions = {
		Vector3.new(-200, -64, 0),   -- Basic caves
		Vector3.new(0, -64, 0),      -- Dense caves  
		Vector3.new(200, -64, 0),    -- Big caverns
		Vector3.new(0, -64, 200)     -- Quick test
	}
	
	-- Clear all test areas first
	for _, pos in ipairs(testPositions) do
		CaveExamples.clearTestArea(terrain, pos)
	end
	
	wait(1)
	
	-- Generate different cave types
	print("\n1. Generating Basic Caves...")
	CaveExamples.generateBasicCaves(terrain, testPositions[1])
	
	wait(2)
	
	print("\n2. Generating Dense Caves...")
	CaveExamples.generateDenseCaves(terrain, testPositions[2])
	
	wait(2)
	
	print("\n3. Generating Big Caverns...")
	CaveExamples.generateBigCaverns(terrain, testPositions[3])
	
	wait(2)
	
	print("\n4. Generating Quick Test...")
	CaveExamples.generateQuickTest(terrain, testPositions[4])
	
	print("\n🎉 Demo Complete!")
	print("📍 Check these locations for different cave types:")
	print("   • Basic caves at:", testPositions[1])
	print("   • Dense caves at:", testPositions[2]) 
	print("   • Big caverns at:", testPositions[3])
	print("   • Quick test at:", testPositions[4])
end

-- Show usage instructions
function CaveExamples.showInstructions()
	print("=" .. string.rep("=", 60))
	print("🕳️ SIMPLE CAVE GENERATOR - USAGE INSTRUCTIONS")
	print("=" .. string.rep("=", 60))
	print("")
	print("📖 Easy Functions:")
	print("   • CaveExamples.generateBasicCaves(terrain)")
	print("   • CaveExamples.generateDenseCaves(terrain)")
	print("   • CaveExamples.generateBigCaverns(terrain)")
	print("   • CaveExamples.generateQuickTest(terrain)")
	print("   • CaveExamples.generateCustomCaves(terrain)")
	print("")
	print("🧹 Utility Functions:")
	print("   • CaveExamples.clearTestArea(terrain)")
	print("   • CaveExamples.runDemo(terrain)")
	print("")
	print("🎯 Quick Start:")
	print("   local terrain = workspace.Terrain")
	print("   CaveExamples.generateBasicCaves(terrain)")
	print("")
	print("🛠️ Custom Settings:")
	print("   local settings = {")
	print("       caveThreshold = 0.4,  -- Cave density")
	print("       caveScale = 0.03,     -- Feature size")
	print("       generateStalactites = true")
	print("   }")
	print("   CaveGenerator.generateCaves(terrain, region, settings)")
	print("")
	print("=" .. string.rep("=", 60))
end

-- Show instructions when module is loaded
CaveExamples.showInstructions()

return CaveExamples