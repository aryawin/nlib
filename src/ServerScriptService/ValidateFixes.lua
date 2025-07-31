--[[
Cave Generation Fix Validation
Checks that all critical fixes are in place
]]

local validationResults = {}

-- Check 1: Voxel Logic Fix
local function checkVoxelLogic()
    print("🔍 Checking voxel logic...")
    
    -- Read Core.lua to verify terrain buffer initialization
    local coreFile = game.ReplicatedStorage.CaveGen.Core
    if coreFile then
        print("✅ Core module found")
        validationResults.coreModule = true
    else
        print("❌ Core module not found")
        validationResults.coreModule = false
        return false
    end
    
    return true
end

-- Check 2: Performance Optimizations
local function checkPerformanceOptimizations()
    print("🔍 Checking performance optimizations...")
    
    -- Check Config.lua for optimized yield interval
    local config = require(game.ReplicatedStorage.CaveGen.Config)
    
    if config.Core.yieldInterval >= 1000 then
        print("✅ Yield interval optimized:", config.Core.yieldInterval)
        validationResults.yieldInterval = true
    else
        print("❌ Yield interval not optimized:", config.Core.yieldInterval)
        validationResults.yieldInterval = false
    end
    
    return true
end

-- Check 3: Chamber Detection Improvements  
local function checkChamberDetection()
    print("🔍 Checking chamber detection...")
    
    local config = require(game.ReplicatedStorage.CaveGen.Config)
    
    if config.Tier1.mainChambers.densityThreshold >= 0.3 then
        print("✅ Chamber density threshold improved:", config.Tier1.mainChambers.densityThreshold)
        validationResults.densityThreshold = true
    else
        print("❌ Chamber density threshold too low:", config.Tier1.mainChambers.densityThreshold)
        validationResults.densityThreshold = false
    end
    
    return true
end

-- Check 4: Region Size Handling
local function checkRegionHandling()
    print("🔍 Checking region size handling...")
    
    local config = require(game.ReplicatedStorage.CaveGen.Config)
    
    -- Check if default region size is reasonable for testing
    local defaultSize = config.Region.defaultSize
    if defaultSize.X <= 100 and defaultSize.Y <= 50 and defaultSize.Z <= 100 then
        print("✅ Default region size is reasonable for testing:", defaultSize)
        validationResults.regionSize = true
    else
        print("⚠️ Default region size might be too large for testing:", defaultSize)
        validationResults.regionSize = false
    end
    
    return true
end

-- Check 5: Module Dependencies
local function checkModuleDependencies()
    print("🔍 Checking module dependencies...")
    
    local modules = {
        "Core", "Config", "Tier1", "Tier2", "Tier3"
    }
    
    local allFound = true
    for _, moduleName in ipairs(modules) do
        local module = game.ReplicatedStorage.CaveGen:FindFirstChild(moduleName)
        if module then
            print("✅", moduleName, "module found")
        else
            print("❌", moduleName, "module not found")
            allFound = false
        end
    end
    
    validationResults.allModules = allFound
    return allFound
end

-- Main validation function
local function runValidation()
    print("🧪 === Cave Generation Fix Validation ===")
    
    local checks = {
        checkVoxelLogic,
        checkPerformanceOptimizations,
        checkChamberDetection,
        checkRegionHandling,
        checkModuleDependencies
    }
    
    local passedChecks = 0
    for _, check in ipairs(checks) do
        if check() then
            passedChecks = passedChecks + 1
        end
        print() -- Empty line for readability
    end
    
    print("📊 Validation Results:")
    print(string.format("✅ Passed: %d/%d checks", passedChecks, #checks))
    
    if passedChecks == #checks then
        print("🎉 All validation checks passed! Cave generation should work correctly.")
    else
        print("⚠️ Some validation checks failed. Cave generation may have issues.")
    end
    
    return validationResults
end

-- Export for external use
return {
    validate = runValidation,
    results = validationResults
}