--[[
Simple Cave Generation Test Script
Tests the basic cave generation functionality
]]

local Config = require(game.ReplicatedStorage.CaveGen.Config)
local InitializeCaveGeneration = require(game.ServerScriptService.InitializeCaveGeneration)

print("🧪 Starting Cave Generation Test...")

-- Test configuration
local testPosition = Vector3.new(0, -25, 0)
local testSize = Vector3.new(60, 30, 60) -- Smaller size for faster testing

print("📍 Test region - Position:", testPosition, "Size:", testSize)

-- Generate cave with progress tracking
local options = {
    enableTier1 = true,
    enableTier2 = false, -- Disable for faster testing
    enableTier3 = false,
    timeout = 60,
    enablePerformanceLogging = true,
    progressCallback = function(progress, stage, details)
        print(string.format("🔄 Progress: %d%% - %s: %s", 
            math.floor(progress * 100), stage, details or ""))
    end
}

print("🚀 Starting cave generation...")
local startTime = tick()

local result = InitializeCaveGeneration.generateQuickCave(testPosition, testSize)

local endTime = tick()
local totalTime = endTime - startTime

print("⏱️ Generation completed in", string.format("%.2f", totalTime), "seconds")

if result.success then
    print("✅ Cave generation SUCCESSFUL!")
    print("📊 Results:")
    print("  - Chambers:", result.features.chambers)
    print("  - Passages:", result.features.passages)
    print("  - Vertical Shafts:", result.features.verticalShafts)
    print("  - Total Voxels:", result.totalVoxels)
    print("  - Memory Used:", string.format("%.2f KB", result.memoryUsed))
    print("  - Generation Time:", string.format("%.3f seconds", result.generationTime))
else
    print("❌ Cave generation FAILED!")
    print("Error:", result.errorMessage or "Unknown error")
end

print("🧪 Test complete!")