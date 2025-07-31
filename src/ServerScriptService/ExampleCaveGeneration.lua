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

-- Example 1: Simple Quick Cave
local function generateSimpleCave()
    print("\n=== Example 1: Simple Quick Cave ===")
    
    local position = Vector3.new(100, -25, 0) -- Offset from spawn
    local size = Vector3.new(60, 30, 60) -- Moderate size
    
    local result = InitializeCaveGeneration.generateQuickCave(position, size)
    
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

-- Example 2: Custom Configuration Cave
local function generateCustomCave()
    print("\n=== Example 2: Custom Configuration Cave ===")
    
    local region = Region3.new(Vector3.new(-50, -50, 100), Vector3.new(50, -10, 200))
    
    -- Custom configuration for a specific cave style
    local customConfig = {
        Core = {
            seed = 12345, -- Fixed seed for reproducible results
            logLevel = "INFO",
            enablePerformanceLogging = true
        },
        Tier1 = {
            mainChambers = {
                enabled = true,
                densityThreshold = 0.12, -- More chambers than default
                minSize = 12,
                maxSize = 28,
                heightVariation = 0.6 -- More varied chamber heights
            },
            passages = {
                enabled = true,
                minWidth = 5,
                maxWidth = 12,
                curvature = 0.4 -- More curved passages
            },
            verticalShafts = {
                enabled = true,
                density = 0.1, -- More vertical connections
                minHeight = 20,
                maxHeight = 60
            }
        },
        Tier2 = {
            enabled = true,
            branches = {
                enabled = true,
                probability = 0.35, -- More branching
                deadEndChance = 0.25 -- Fewer dead ends
            },
            subChambers = {
                enabled = true,
                probability = 0.6, -- More sub-chambers
                sizeRatio = 0.8 -- Larger sub-chambers
            }
        },
        Tier3 = {
            enabled = false -- Skip micro-features for this example
        }
    }
    
    local options = {
        enableTier1 = true,
        enableTier2 = true,
        enableTier3 = false,
        timeout = 90,
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

-- Example 4: Test Cave for Debugging
local function generateTestCave()
    print("\n=== Example 4: Test Cave for Debugging ===")
    
    local result = InitializeCaveGeneration.generateTestCave()
    
    if result.success then
        print("✅ Test cave generated successfully!")
        print("🔍 This cave uses a fixed seed and debug settings for reproducible testing")
    else
        warn("❌ Test cave generation failed:", result.errorMessage)
    end
    
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
    
    generateTestCave()
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

print("💡 Cave Generation Examples loaded!")
print("💡 Call runExamples() to run all examples, or call individual functions:")
print("   - generateSimpleCave()")
print("   - generateCustomCave()")  
print("   - generateAdvancedCave()")
print("   - generateTestCave()")
print("   - demonstrateErrorHandling()")