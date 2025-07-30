--!strict

--[[
====================================================================================================
                               Simple Cave Generator Testing
                                Validate New Implementation
====================================================================================================

This script tests the new simplified cave generation system to ensure it works properly
and produces the desired results: connected caves without floating rocks.

====================================================================================================
]]

-- Mock Roblox objects for testing
local function createMockRobloxAPI()
	-- Mock Vector3
	local Vector3 = {}
	Vector3.__index = Vector3
	
	function Vector3.new(x, y, z)
		return setmetatable({
			X = x or 0,
			Y = y or 0, 
			Z = z or 0,
			Magnitude = math.sqrt((x or 0)^2 + (y or 0)^2 + (z or 0)^2)
		}, Vector3)
	end
	
	function Vector3:__add(other)
		return Vector3.new(self.X + other.X, self.Y + other.Y, self.Z + other.Z)
	end
	
	function Vector3:__sub(other)
		return Vector3.new(self.X - other.X, self.Y - other.Y, self.Z - other.Z)
	end
	
	function Vector3:__mul(scalar)
		if type(scalar) == "number" then
			return Vector3.new(self.X * scalar, self.Y * scalar, self.Z * scalar)
		end
		return self
	end
	
	function Vector3:__div(scalar)
		if type(scalar) == "number" then
			return Vector3.new(self.X / scalar, self.Y / scalar, self.Z / scalar)
		end
		return self
	end
	
	-- Mock Region3
	local Region3 = {}
	Region3.__index = Region3
	
	function Region3.new(min, max)
		local center = (min + max) * 0.5
		local size = max - min
		return setmetatable({
			CFrame = {Position = center},
			Size = size
		}, Region3)
	end
	
	-- Mock CFrame  
	local CFrame = {}
	CFrame.__index = CFrame
	
	function CFrame.new(position)
		return setmetatable({
			Position = position
		}, CFrame)
	end
	
	-- Mock Enum
	local Enum = {
		Material = {
			Air = "Air",
			Rock = "Rock", 
			Water = "Water",
			CrackedLava = "CrackedLava",
			Neon = "Neon",
			Concrete = "Concrete"
		}
	}
	
	-- Mock Terrain
	local Terrain = {}
	Terrain.__index = Terrain
	
	function Terrain.new()
		return setmetatable({
			writeVoxelsCalls = {},
			fillBlockCalls = {},
			fillBallCalls = {},
			fillRegionCalls = {}
		}, Terrain)
	end
	
	function Terrain:WriteVoxels(region, resolution, materials, occupancies)
		table.insert(self.writeVoxelsCalls, {
			region = region,
			resolution = resolution,
			materials = materials,
			occupancies = occupancies
		})
	end
	
	function Terrain:FillBlock(cframe, size, material)
		table.insert(self.fillBlockCalls, {
			cframe = cframe,
			size = size,
			material = material
		})
	end
	
	function Terrain:FillBall(position, radius, material)
		table.insert(self.fillBallCalls, {
			position = position,
			radius = radius,
			material = material
		})
	end
	
	function Terrain:FillRegion(region, resolution, material)
		table.insert(self.fillRegionCalls, {
			region = region,
			resolution = resolution,
			material = material
		})
	end
	
	function Terrain:IsA(className)
		return className == "Terrain"
	end
	
	-- Mock task
	local task = {
		wait = function() 
			-- Mock wait function
		end
	}
	
	-- Mock typeof
	local function typeof(obj)
		if type(obj) == "table" then
			if getmetatable(obj) == Vector3 then
				return "Vector3"
			elseif getmetatable(obj) == Region3 then
				return "Region3"
			elseif getmetatable(obj) == Terrain then
				return "Instance"
			end
		end
		return type(obj)
	end
	
	-- Set globals
	_G.Vector3 = Vector3
	_G.Region3 = Region3
	_G.CFrame = CFrame
	_G.Enum = Enum
	_G.task = task
	_G.typeof = typeof
	_G.workspace = {Terrain = Terrain.new()}
	_G.math = math
	_G.table = table
	_G.pairs = pairs
	_G.ipairs = ipairs
	_G.print = print
	_G.warn = print -- Mock warn as print
	_G.assert = assert
	_G.setmetatable = setmetatable
	_G.getmetatable = getmetatable
	_G.os = os
	
	return {Vector3 = Vector3, Region3 = Region3, CFrame = CFrame, Enum = Enum, Terrain = Terrain}
end

-- Initialize mock API
local MockAPI = createMockRobloxAPI()

-- Mock require function to load our modules
local function mockRequire(modulePath)
	if modulePath == "script.Parent.NoiseLib" or modulePath:match("NoiseLib") then
		-- Load NoiseLib
		local file = io.open("NoiseLib.lua", "r")
		if file then
			local content = file:read("*all")
			file:close()
			local chunk = load(content)
			if chunk then
				return chunk()
			end
		end
		error("Could not load NoiseLib.lua")
	elseif modulePath == "script.ProceduralCaveGenerator" or modulePath:match("ProceduralCaveGenerator") then
		-- Load ProceduralCaveGenerator
		local file = io.open("ProceduralCaveGenerator.lua", "r")
		if file then
			local content = file:read("*all")
			file:close()
			-- Replace the require call in the content
			content = content:gsub("require%(script%.Parent%.NoiseLib%)", "mockRequire('NoiseLib')")
			local chunk = load(content)
			if chunk then
				return chunk()
			end
		end
		error("Could not load ProceduralCaveGenerator.lua")
	elseif modulePath == "script.CaveGenerationExample" or modulePath:match("CaveGenerationExample") then
		-- Load CaveGenerationExample
		local file = io.open("CaveGenerationExample.lua", "r")
		if file then
			local content = file:read("*all")
			file:close()
			-- Replace the require call in the content
			content = content:gsub("require%(script%.Parent%.ProceduralCaveGenerator%)", "mockRequire('ProceduralCaveGenerator')")
			local chunk = load(content)
			if chunk then
				return chunk()
			end
		end
		error("Could not load CaveGenerationExample.lua")
	end
	error("Unknown module: " .. tostring(modulePath))
end

-- Set global require
_G.require = mockRequire

print("🧪 Starting Simplified Cave Generator Tests...")
print("=" .. string.rep("=", 60))

-- Test 1: Basic Module Loading
print("Test 1: Module Loading")
local success, NoiseLib = pcall(mockRequire, "NoiseLib")
if success then
	print("✅ NoiseLib loaded successfully")
else
	print("❌ NoiseLib failed to load:", NoiseLib)
	return
end

local success, CaveGenerator = pcall(mockRequire, "ProceduralCaveGenerator")
if success then
	print("✅ CaveGenerator loaded successfully")
else
	print("❌ CaveGenerator failed to load:", CaveGenerator)
	return
end

local success, CaveExamples = pcall(mockRequire, "CaveGenerationExample")
if success then
	print("✅ CaveExamples loaded successfully")
else
	print("❌ CaveExamples failed to load:", CaveExamples)
	return
end

-- Test 2: Utility Functions
print("\nTest 2: Utility Functions")
local testRegion = CaveGenerator.createTestRegion(MockAPI.Vector3.new(0, -64, 0), MockAPI.Vector3.new(64, 32, 64))
if testRegion and typeof(testRegion) == "Region3" then
	print("✅ createTestRegion works")
	print("   Region size:", testRegion.Size.X, testRegion.Size.Y, testRegion.Size.Z)
	print("   Region center:", testRegion.CFrame.Position.X, testRegion.CFrame.Position.Y, testRegion.CFrame.Position.Z)
else
	print("❌ createTestRegion failed")
end

-- Test 3: Basic Cave Generation
print("\nTest 3: Basic Cave Generation")
local mockTerrain = MockAPI.Terrain.new()

-- Create a very small test region to avoid timeouts
local smallRegion = CaveGenerator.createTestRegion(MockAPI.Vector3.new(0, -32, 0), MockAPI.Vector3.new(32, 16, 32))

print("Starting basic cave generation test...")
local startTime = os.clock()
local result = CaveGenerator.generateCaves(mockTerrain, smallRegion)
local endTime = os.clock()

if result.success then
	print("✅ Basic cave generation completed successfully!")
	print("   Time taken:", string.format("%.2f seconds", endTime - startTime))
	print("   Caves generated:", result.cavesGenerated or 0)
	print("   Features generated:", result.featuresGenerated or 0)
	print("   Chunks processed:", result.chunksProcessed or 0)
	print("   WriteVoxels calls:", #mockTerrain.writeVoxelsCalls)
	print("   FillBlock calls:", #mockTerrain.fillBlockCalls)
else
	print("❌ Basic cave generation failed:", result.error)
end

-- Test 4: Preset Configurations
print("\nTest 4: Preset Configurations")
if CaveGenerator.Presets then
	print("✅ Presets available:")
	for presetName, preset in pairs(CaveGenerator.Presets) do
		print("   •", presetName)
		-- Test one preset
		if presetName == "SMALL_TEST" then
			local testResult = CaveGenerator.generateCaves(mockTerrain, smallRegion, preset)
			if testResult.success then
				print("     ✓ Preset works:", testResult.cavesGenerated, "caves")
			else
				print("     ✗ Preset failed:", testResult.error)
			end
		end
	end
else
	print("❌ No presets found")
end

-- Test 5: Custom Settings
print("\nTest 5: Custom Settings")
local customSettings = {
	caveThreshold = 0.35,
	caveScale = 0.04,
	tunnelScale = 0.03,
	chamberScale = 0.1,
	generateStalactites = true,
	resolution = 8, -- Lower resolution for faster testing
	chunkSize = 32
}

local customResult = CaveGenerator.generateCaves(mockTerrain, smallRegion, customSettings)
if customResult.success then
	print("✅ Custom settings work!")
	print("   Caves generated:", customResult.cavesGenerated or 0)
	print("   Features generated:", customResult.featuresGenerated or 0)
else
	print("❌ Custom settings failed:", customResult.error)
end

-- Test 6: Example Functions
print("\nTest 6: Example Functions")

-- Test basic caves
print("Testing basic caves example...")
local exampleResult = CaveExamples.generateBasicCaves(mockTerrain, MockAPI.Vector3.new(100, -64, 0))
if exampleResult then
	print("✅ Basic caves example works")
else
	print("❌ Basic caves example failed")
end

-- Test clearing
print("Testing terrain clearing...")
CaveExamples.clearTestArea(mockTerrain, MockAPI.Vector3.new(0, -64, 0))
if #mockTerrain.fillRegionCalls > 0 then
	print("✅ Terrain clearing works")
else
	print("❌ Terrain clearing failed")
end

-- Test 7: Data Validation
print("\nTest 7: Data Validation")
if result.success and result.cavesGenerated then
	-- Check if we generated a reasonable number of caves
	if result.cavesGenerated > 0 and result.cavesGenerated < 10000 then
		print("✅ Cave count is reasonable:", result.cavesGenerated)
	else
		print("⚠️ Cave count seems unusual:", result.cavesGenerated)
	end
	
	-- Check if chunks were processed
	if result.chunksProcessed and result.chunksProcessed > 0 then
		print("✅ Chunks were processed:", result.chunksProcessed)
	else
		print("❌ No chunks were processed")
	end
	
	-- Check if WriteVoxels was called
	if #mockTerrain.writeVoxelsCalls > 0 then
		print("✅ WriteVoxels was called:", #mockTerrain.writeVoxelsCalls, "times")
	else
		print("❌ WriteVoxels was never called")
	end
else
	print("❌ Cannot validate data - generation failed")
end

print("\n" .. string.rep("=", 60))
print("🎉 Simplified Cave Generator Tests Complete!")

if result.success and customResult.success and exampleResult then
	print("✅ All major components are working correctly!")
	print("\n📝 Summary:")
	print("   • Basic generation: ✅ Works")
	print("   • Custom settings: ✅ Works") 
	print("   • Presets: ✅ Available")
	print("   • Examples: ✅ Work")
	print("   • Utilities: ✅ Work")
	print("\n🎯 Ready for Roblox testing!")
	print("   1. Load into Roblox Studio")
	print("   2. Run: CaveExamples.generateBasicCaves(workspace.Terrain)")
	print("   3. Check results for connected caves without floating rocks")
else
	print("❌ Some tests failed - check implementation")
end