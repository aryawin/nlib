--[[
Example Cave Generation Script

This script demonstrates how to use the InitializeCaveGeneration module
to create different types of caves. Copy and modify this script to suit your needs.

To use:
1. Place this script in ServerScriptService
2. Run the script in Roblox Studio
3. Check the console for generation progress and results

]]

local InitializeCaveGeneration = require(script.Parent.InitializeCaveGeneration)

-- ================================================================================================
--                                    EXAMPLE FUNCTIONS
-- ================================================================================================

-- Example 1: Simple Quick Cave with Medium Preset
local function generateSimpleCave()
    print("\n=== Example 1: Simple Quick Cave with Medium Preset ===")
    
    local position = Vector3.new(100, -25, 0) -- Offset from spawn
    local size = Vector3.new(80, 40, 80) -- Optimized size for better caves
    
    -- Use the new preset-based generation
    local result = InitializeCaveGeneration.generateCaveWithPreset(position, size, "medium")
    
    if result.success then
        print("✅ Simple cave generated successfully!")
        print(string.format("📊 Features: %d chambers, %d passages, %d shafts", 
            result.features.chambers, result.features.passages, result.features.verticalShafts))
        print(string.format("⏱️ Generated in %.2f seconds", result.generationTime))
    else
        warn("❌ Simple cave generation failed:", result.errorMessage)
    end
    
    return result
end

-- Example 2: Custom Configuration Cave with Large Preset
local function generateCustomCave()
    print("\n=== Example 2: Custom Configuration Cave with Large Preset ===")
    
    local region = Region3.new(Vector3.new(-60, -60, 100), Vector3.new(60, -10, 220))
    
    -- Use large preset as base and customize
    local Config = require(game.ReplicatedStorage.CaveGen.Config)
    local customConfig = Config.withPreset("large")
    
    -- Additional customizations
    customConfig.Core.seed = 12345 -- Fixed seed for reproducible results
    customConfig.Core.logLevel = "INFO"
    customConfig.Tier1.mainChambers.densityThreshold = 0.07 -- Slightly more chambers
    customConfig.Tier1.passages.minWidth = 6 -- Wider passages
    customConfig.Tier2.enabled = true
    customConfig.Tier3.enabled = false -- Skip micro-features for faster generation
    
    local options = {
        enableTier1 = true,
        enableTier2 = true,
        enableTier3 = false,
        timeout = 45, -- Reduced timeout with optimizations
        progressCallback = function(progress, stage, details)
            print(string.format("📊 %.1f%% - %s: %s", progress * 100, stage, details or ""))
        end
    }
    
    local result = InitializeCaveGeneration.generateCave(region, customConfig, options)
    
    if result.success then
        print("✅ Custom cave generated successfully!")
        print(string.format("📊 Features: %d chambers, %d passages, %d branches", 
            result.features.chambers, result.features.passages, result.features.branches))
        print(string.format("⏱️ Generated in %.2f seconds using %.2f KB memory", 
            result.generationTime, result.memoryUsed))
    else
        warn("❌ Custom cave generation failed:", result.errorMessage)
    end
    
    return result
end

-- Example 3: Advanced Cave with All Features
local function generateAdvancedCave()
    print("\n=== Example 3: Advanced Cave with All Features ===")
    
    local region = Region3.new(Vector3.new(100, -80, 100), Vector3.new(200, -20, 200))
    
    -- Advanced configuration showcasing all features
    local advancedConfig = {
        Core = {
            seed = nil, -- Random seed for unique generation
            logLevel = "DEBUG",
            enablePerformanceLogging = true,
            yieldInterval = 75 -- More frequent yielding for stability
        },
        Tier1 = {
            mainChambers = {
                enabled = true,
                densityThreshold = 0.18,
                asymmetryFactor = 0.4,
                heightVariation = 0.5
            },
            passages = {
                enabled = true,
                curvature = 0.3,
                smoothingPasses = 4
            },
            verticalShafts = {
                enabled = true,
                density = 0.08,
                angleVariation = 20
            }
        },
        Tier2 = {
            enabled = true,
            branches = {
                enabled = true,
                probability = 0.3
            },
            subChambers = {
                enabled = true,
                probability = 0.4
            },
            collapseRooms = {
                enabled = true,
                probability = 0.15
            },
            hiddenPockets = {
                enabled = true,
                density = 0.1
            }
        },
        Tier3 = {
            enabled = true,
            fractureVeins = {
                enabled = true,
                density = 0.2
            },
            pinchPoints = {
                enabled = true,
                probability = 0.2
            }
        }
    }
    
    local progressCallback = function(progress, stage, details)
        local percentage = math.floor(progress * 100)
        local bar = string.rep("█", math.floor(percentage / 5)) .. string.rep("░", 20 - math.floor(percentage / 5))
        print(string.format("🔄 [%s] %d%% - %s", bar, percentage, stage))
        if details then
            print(string.format("   ℹ️ %s", details))
        end
    end
    
    local result = InitializeCaveGeneration.generateAdvancedCave(region, advancedConfig, progressCallback)
    
    if result.success then
        print("✅ Advanced cave generated successfully!")
        print("📊 Feature Summary:")
        print(string.format("   🏛️ Chambers: %d", result.features.chambers))
        print(string.format("   🌉 Passages: %d", result.features.passages))  
        print(string.format("   ⬆️ Vertical Shafts: %d", result.features.verticalShafts))
        print(string.format("   🌿 Branches: %d", result.features.branches))
        print(string.format("   🔸 Sub-chambers: %d", result.features.subChambers))
        print(string.format("   💥 Collapse Rooms: %d", result.features.collapseRooms))
        print(string.format("   🕳️ Hidden Pockets: %d", result.features.hiddenPockets))
        print(string.format("   ⚡ Micro-features: %d", result.features.microFeatures))
        print(string.format("⏱️ Total generation time: %.2f seconds", result.generationTime))
        print(string.format("💾 Memory used: %.2f KB", result.memoryUsed))
    else
        warn("❌ Advanced cave generation failed:", result.errorMessage)
    end
    
    return result
end

-- Example 4: Region Configuration Testing
local function testRegionConfiguration()
    print("\n=== Example 4: Region Configuration Testing ===")
    
    local Config = require(game.ReplicatedStorage.CaveGen.Config)
    
    -- Test 1: Default region
    print("📍 Testing default region configuration:")
    local defaultRegion = Config.getActiveRegion()
    
    -- Test 2: Set GIGANTIC preset
    print("📍 Setting GIGANTIC preset:")
    Config.setActiveRegionPreset("GIGANTIC")
    local giganticRegion = Config.getActiveRegion()
    
    -- Test generation with GIGANTIC preset
    local region = Region3.new(
        giganticRegion.center - giganticRegion.size/2,
        giganticRegion.center + giganticRegion.size/2
    )
    
    -- Use a smaller subset for actual testing (full GIGANTIC would take too long)
    local testRegion = Region3.new(
        Vector3.new(-50, -60, -50),
        Vector3.new(50, -10, 50)
    )
    
    local result = InitializeCaveGeneration.generateQuickCave(
        Vector3.new(0, -35, 0),
        Vector3.new(100, 50, 100)
    )
    
    if result.success then
        print("✅ Region configuration test successful!")
        print(string.format("📊 Generated cave with %d chambers, %d passages", 
            result.features.chambers, result.features.passages))
        print("🔍 The system correctly used region configuration instead of hardcoded sizes")
    else
        warn("❌ Region configuration test failed:", result.errorMessage)
    end
    
    -- Test 3: Custom region
    print("📍 Testing custom region:")
    Config.setCustomRegion(Vector3.new(200, 60, 200), Vector3.new(100, -40, 100))
    local customRegion = Config.getActiveRegion()
    
    -- Reset to defaults
    Config.clearRegionConfig()
    
    return result
end

-- Example 5: Error Handling and Recovery
local function demonstrateErrorHandling()
    print("\n=== Example 5: Error Handling Demo ===")
    
    -- Intentionally create a problematic configuration
    local region = Region3.new(Vector3.new(0, 0, 0), Vector3.new(10, 10, 10)) -- Very small region
    
    local problematicConfig = {
        Core = {
            maxGenerationTime = 1, -- Very short timeout
            chunkSize = 1 -- Very small chunks
        }
    }
    
    local options = {
        timeout = 2, -- Very short timeout
        progressCallback = function(progress, stage, details)
            print(string.format("⚠️ %.1f%% - %s", progress * 100, stage))
        end
    }
    
    local result = InitializeCaveGeneration.generateCave(region, problematicConfig, options)
    
    if result.success then
        print("✅ Surprisingly, the problematic cave worked!")
    else
        print("❌ Expected failure occurred:", result.errorMessage)
        print("📊 Partial results:")
        print(string.format("   Time: %.2f seconds", result.generationTime))
        print(string.format("   Features generated before failure: %d chambers", result.features.chambers))
        print("💡 This demonstrates graceful failure handling")
    end
    
    return result
end

-- ================================================================================================
--                                    MAIN EXECUTION
-- ================================================================================================

local function runExamples()
    print("🚀 Starting Cave Generation Examples")
    print("📋 Version:", InitializeCaveGeneration.getVersion())
    
    -- Check if modules are available
    if not InitializeCaveGeneration.validateModules() then
        warn("❌ Required modules not available - examples cannot run")
        return
    end
    
    -- Show initial stats
    local initialStats = InitializeCaveGeneration.getGenerationStats()
    print("📊 Initial Generation Stats:", initialStats)
    
    -- Wait between examples to prevent overlap
    local function waitForGeneration()
        while InitializeCaveGeneration.isGenerating() do
            wait(0.5)
        end
        wait(1) -- Additional buffer
    end
    
    -- Run examples
    generateSimpleCave()
    waitForGeneration()
    
    generateCustomCave()
    waitForGeneration()
    
    generateAdvancedCave()
    waitForGeneration()
    
    testRegionConfiguration()
    waitForGeneration()
    
    demonstrateErrorHandling()
    waitForGeneration()
    
    -- Show final stats
    local finalStats = InitializeCaveGeneration.getGenerationStats()
    print("\n📊 Final Generation Stats:")
    print(string.format("   Total generations: %d", finalStats.totalGenerations))
    print(string.format("   Successful generations: %d", finalStats.successfulGenerations))
    print(string.format("   Success rate: %.1f%%", finalStats.successRate * 100))
    print(string.format("   Average generation time: %.2f seconds", finalStats.averageGenerationTime))
    
    -- Cleanup
    InitializeCaveGeneration.cleanup()
    print("\n✅ All examples completed! Check your workspace for the generated caves.")
end

-- Uncomment the line below to run examples automatically when script loads
-- runExamples()

-- Or call individual examples:
-- generateSimpleCave()
-- generateCustomCave()
-- generateAdvancedCave()

-- Quick preset examples:
-- InitializeCaveGeneration.generateCaveWithPreset(Vector3.new(0, -30, 0), Vector3.new(60, 30, 60), "small")
-- InitializeCaveGeneration.generateCaveWithPreset(Vector3.new(0, -30, 0), Vector3.new(100, 50, 100), "medium")
-- InitializeCaveGeneration.generateCaveWithPreset(Vector3.new(0, -30, 0), Vector3.new(150, 80, 150), "large")

print("💡 Cave Generation Examples loaded!")
print("💡 Call runExamples() to run all examples, or call individual functions:")
print("   - generateSimpleCave()")
print("   - generateCustomCave()")  
print("   - generateAdvancedCave()")
print("   - testRegionConfiguration()")
print("   - demonstrateErrorHandling()")