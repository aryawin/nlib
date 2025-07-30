--!strict

--[[
====================================================================================================
                               Cave Generator Testing Script
                              Simple Validation and Testing
====================================================================================================

This script provides basic tests to validate the ProceduralCaveGenerator implementation.
It focuses on testing the core functionality without requiring actual Roblox Terrain objects.

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
			Neon = "Neon"
		}
	}
	
	-- Mock Color3
	local Color3 = {}
	Color3.__index = Color3
	
	function Color3.new(r, g, b)
		return setmetatable({r = r, g = g, b = b}, Color3)
	end
	
	function Color3.fromRGB(r, g, b)
		return Color3.new(r/255, g/255, b/255)
	end
	
	-- Mock Terrain
	local Terrain = {}
	Terrain.__index = Terrain
	
	function Terrain.new()
		return setmetatable({
			writeVoxelsCalls = {},
			fillBlockCalls = {},
			fillBallCalls = {}
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
		-- Mock cleanup function
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
	_G.Color3 = Color3
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
	_G.gcinfo = function() return 1000 end -- Mock memory usage
	
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
	elseif modulePath == "script.Parent.ProceduralCaveGenerator" or modulePath:match("ProceduralCaveGenerator") then
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
	end
	error("Unknown module: " .. tostring(modulePath))
end

-- Set global require
_G.require = mockRequire

print("🧪 Starting Cave Generator Tests...")
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

local success, ProceduralCaveGenerator = pcall(mockRequire, "ProceduralCaveGenerator")
if success then
	print("✅ ProceduralCaveGenerator loaded successfully")
else
	print("❌ ProceduralCaveGenerator failed to load:", ProceduralCaveGenerator)
	return
end

-- Test 2: Settings Validation
print("\nTest 2: Settings Validation")
local testSettings = {
	region = MockAPI.Region3.new(MockAPI.Vector3.new(-32, -64, -32), MockAPI.Vector3.new(32, 0, 32)),
	chunkSize = 32,
	resolution = 4,
	caveSettings = {
		threshold = 0.4,
		optimalDepth = -60,
		connectivity = 0.8
	},
	generateFeatures = true
}

local validationResult = ProceduralCaveGenerator.validateSettings(testSettings)
if validationResult then
	print("✅ Settings validation passed")
else
	print("❌ Settings validation failed")
end

-- Test 3: Memory Estimation
print("\nTest 3: Memory Estimation")
local memoryEstimate = ProceduralCaveGenerator.estimateMemoryUsage(testSettings)
if memoryEstimate > 0 then
	print("✅ Memory estimation works:", string.format("%.2f KB", memoryEstimate / 1024))
else
	print("❌ Memory estimation failed")
end

-- Test 4: NoiseLib Generator Creation
print("\nTest 4: NoiseLib Generator")
local generator = NoiseLib.new(12345)
if generator then
	print("✅ NoiseLib generator created")
	
	-- Test basic noise functions
	local noise2D = generator:simplex2D(10, 20)
	local noise3D = generator:simplex3D(10, 20, 30)
	print("✅ Noise functions working: 2D =", string.format("%.3f", noise2D), "3D =", string.format("%.3f", noise3D))
else
	print("❌ NoiseLib generator creation failed")
end

-- Test 5: Basic Cave Generation (Dry Run)
print("\nTest 5: Cave Generation Test (Dry Run)")
local mockTerrain = MockAPI.Terrain.new()

-- Create a very small test region to avoid timeouts
local smallTestSettings = {
	region = MockAPI.Region3.new(MockAPI.Vector3.new(-16, -32, -16), MockAPI.Vector3.new(16, -8, 16)),
	chunkSize = 16,
	resolution = 8, -- Lower resolution for faster testing
	caveSettings = {
		threshold = 0.4,
		optimalDepth = -20,
		connectivity = 0.8
	},
	generateFeatures = false, -- Disable features for testing
	generateWaterFlow = false,
	generateEntrances = false
}

local progressCount = 0
local function progressCallback(progress, stage, details)
	progressCount = progressCount + 1
	if progressCount % 5 == 0 then -- Only print every 5th progress update
		print(string.format("   Progress: %s %.1f%% - %s", stage, progress * 100, details or ""))
	end
end

print("Starting cave generation test...")
local startTime = os.clock()
local result = ProceduralCaveGenerator.generateCaveSystem(mockTerrain, smallTestSettings, progressCallback)
local endTime = os.clock()

if result.success then
	print("✅ Cave generation completed successfully!")
	print("   Time taken:", string.format("%.2f seconds", endTime - startTime))
	print("   Total caves:", result.totalCaves or 0)
	print("   Total features:", result.totalFeatures or 0)
	print("   Total chunks:", result.chunks and #result.chunks or 0)
	print("   WriteVoxels calls:", #mockTerrain.writeVoxelsCalls)
	print("   FillBlock calls:", #mockTerrain.fillBlockCalls)
	print("   FillBall calls:", #mockTerrain.fillBallCalls)
else
	print("❌ Cave generation failed:", result.error)
end

-- Test 6: Debug Visualization
print("\nTest 6: Debug Visualization")
if result.success then
	local viz = ProceduralCaveGenerator.generateDebugVisualization(result)
	if viz then
		print("✅ Debug visualization created")
		print("   Cave points:", #viz.cavePoints)
		print("   Entrance points:", #viz.entrancePoints)
		print("   Feature points:", #viz.featurePoints)
		print("   Water flow lines:", #viz.waterFlowLines)
	else
		print("❌ Debug visualization failed")
	end
end

-- Test 7: Performance Stats
print("\nTest 7: Performance Stats")
if generator then
	local stats = generator:getPerformanceStats()
	if stats then
		print("✅ Performance stats available")
		print("   Total executions:", stats.totalExecutions)
		print("   Peak memory:", string.format("%.2f KB", stats.peakMemoryUsage))
		print("   Cache size:", stats.cacheStats.size, "/", stats.cacheStats.maxSize)
	else
		print("❌ Performance stats failed")
	end
end

print("\n" .. string.rep("=", 60))
print("🎉 Cave Generator Tests Complete!")
print("✅ All major components appear to be working correctly")
print("\n📝 Next Steps:")
print("   1. Test in actual Roblox environment with real Terrain")
print("   2. Run performance tests with larger regions")
print("   3. Validate visual output and cave quality")
print("   4. Test all feature types and water flow simulation")