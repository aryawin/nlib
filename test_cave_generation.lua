#!/usr/bin/env lua

--[[
Simple test script to verify cave generation is working
This simulates the basic cave generation logic
]]

print("=== Cave Generation Test ===")

-- Simulate the basic logic
local testRegion = {
    Size = {X = 100, Y = 50, Z = 100},
    CFrame = {Position = {X = 0, Y = -25, Z = 0}}
}

-- Test chamber detection logic
local function testChamberDetection()
    print("\n--- Testing Chamber Detection ---")
    
    -- Simulate noise values for chamber detection
    local chamberThreshold = 0.15
    local testNoiseValues = {0.05, 0.1, 0.12, 0.18, 0.25, 0.3}
    
    print("Chamber threshold:", chamberThreshold)
    
    for i, noiseValue in ipairs(testNoiseValues) do
        local shouldGenerateChamber = noiseValue < chamberThreshold
        print(string.format("Noise value %.2f -> Chamber: %s", noiseValue, shouldGenerateChamber and "YES" or "NO"))
    end
end

-- Test voxel logic
local function testVoxelLogic()
    print("\n--- Testing Voxel Logic ---")
    
    -- Simulate terrain buffer
    local voxelData = {}
    for x = 1, 10 do
        voxelData[x] = {}
        for y = 1, 10 do
            voxelData[x][y] = {}
            for z = 1, 10 do
                voxelData[x][y][z] = 1 -- Start with solid rock
            end
        end
    end
    
    print("Initial terrain: solid rock (1)")
    
    -- Carve a chamber at center
    local centerX, centerY, centerZ = 5, 5, 5
    local radius = 2
    local carvedCount = 0
    
    for x = centerX - radius, centerX + radius do
        for y = centerY - radius, centerY + radius do
            for z = centerZ - radius, centerZ + radius do
                local dx = (x - centerX) / radius
                local dy = (y - centerY) / radius  
                local dz = (z - centerZ) / radius
                
                if dx*dx + dy*dy + dz*dz <= 1 then
                    voxelData[x][y][z] = 0 -- Carve air
                    carvedCount = carvedCount + 1
                end
            end
        end
    end
    
    print("Carved", carvedCount, "voxels as air")
    
    -- Count final state
    local airCount = 0
    local solidCount = 0
    for x = 1, 10 do
        for y = 1, 10 do
            for z = 1, 10 do
                if voxelData[x][y][z] == 0 then
                    airCount = airCount + 1
                else
                    solidCount = solidCount + 1
                end
            end
        end
    end
    
    print("Final state:", airCount, "air,", solidCount, "solid")
    print("Air percentage:", string.format("%.1f%%", (airCount / (airCount + solidCount)) * 100))
end

-- Test region size calculation
local function testRegionCalculation()
    print("\n--- Testing Region Calculation ---")
    
    local resolution = 4
    local originalSize = testRegion.Size
    
    -- Simulate ExpandToGrid
    local expandedX = math.ceil(originalSize.X / resolution) * resolution
    local expandedY = math.ceil(originalSize.Y / resolution) * resolution
    local expandedZ = math.ceil(originalSize.Z / resolution) * resolution
    
    print("Original size:", originalSize.X, originalSize.Y, originalSize.Z)
    print("Expanded size:", expandedX, expandedY, expandedZ)
    
    -- Calculate voxel dimensions
    local voxelsX = math.ceil(expandedX / resolution)
    local voxelsY = math.ceil(expandedY / resolution)
    local voxelsZ = math.ceil(expandedZ / resolution)
    
    print("Voxel dimensions:", voxelsX, voxelsY, voxelsZ)
    print("Total voxels:", voxelsX * voxelsY * voxelsZ)
end

-- Run tests
testChamberDetection()
testVoxelLogic()
testRegionCalculation()

print("\n=== Test Complete ===")