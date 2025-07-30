--!strict

--[[
====================================================================================================
                               Cave Generation Example & Testing
                                 Complete Usage Demonstration
====================================================================================================

This script demonstrates how to use the ProceduralCaveGenerator to create complex, realistic
cave systems in Roblox. It includes multiple examples showcasing different features and scales.

FEATURES DEMONSTRATED:
- Basic cave generation with all stages
- Advanced feature placement (stalactites, crystals, pools)
- Water flow simulation and visualization
- Cave entrance detection and creation
- Performance monitoring and optimization
- Debug visualization tools
- Error handling and progress reporting

====================================================================================================
]]

local ProceduralCaveGenerator = require(script.Parent.ProceduralCaveGenerator)
local NoiseLib = require(script.Parent.NoiseLib)

local CaveExample = {}

-- ================================================================================================
--                                   EXAMPLE CONFIGURATIONS
-- ================================================================================================

-- Example 1: Small Test Cave (Great for development and testing)
local SMALL_TEST_CONFIG = {
	region = Region3.new(Vector3.new(-64, -96, -64), Vector3.new(64, -16, 64)),
	chunkSize = 32,
	resolution = 4,
	caveSettings = {
		threshold = 0.4,
		optimalDepth = -60,
		depthRange = 30,
		tunnelScale = 0.025,
		chamberScale = 0.06,
		connectivity = 0.8,
		waterLevel = -40,
		lavaLevel = -120,
		weightMainTunnels = 0.6,
		weightChambers = 0.3,
		weightVerticalShafts = 0.1
	},
	generateFeatures = true,
	generateWaterFlow = true,
	generateEntrances = true,
	enableProgressReporting = true
}

-- Example 2: Realistic Underground Cave Network
local REALISTIC_NETWORK_CONFIG = {
	region = Region3.new(Vector3.new(-128, -160, -128), Vector3.new(128, -16, 128)),
	chunkSize = 64,
	resolution = 4,
	caveSettings = {
		threshold = 0.35,
		optimalDepth = -80,
		depthRange = 50,
		tunnelScale = 0.02,
		chamberScale = 0.05,
		connectivity = 0.7,
		waterLevel = -50,
		lavaLevel = -140,
		weightMainTunnels = 0.5,
		weightChambers = 0.4,
		weightVerticalShafts = 0.1,
		scaleVerticality = 0.012,
		scaleDetail = 0.25
	},
	generateFeatures = true,
	generateWaterFlow = true,
	generateEntrances = true,
	enableProgressReporting = true
}

-- Example 3: Dense Lava Cave System (Deep underground)
local LAVA_CAVE_CONFIG = {
	region = Region3.new(Vector3.new(-96, -200, -96), Vector3.new(96, -100, 96)),
	chunkSize = 48,
	resolution = 4,
	caveSettings = {
		threshold = 0.45,
		optimalDepth = -150,
		depthRange = 40,
		tunnelScale = 0.03,
		chamberScale = 0.07,
		connectivity = 0.6,
		waterLevel = -80,
		lavaLevel = -120, -- Lava level above optimal depth
		weightMainTunnels = 0.7,
		weightChambers = 0.2,
		weightVerticalShafts = 0.1
	},
	generateFeatures = true,
	generateWaterFlow = true,
	generateEntrances = false, -- Deep caves rarely have surface entrances
	enableProgressReporting = true
}

-- Example 4: Performance Optimized (Minimal features for large areas)
local PERFORMANCE_CONFIG = {
	region = Region3.new(Vector3.new(-256, -128, -256), Vector3.new(256, 0, 256)),
	chunkSize = 128,
	resolution = 8, -- Lower resolution for performance
	caveSettings = {
		threshold = 0.4,
		optimalDepth = -64,
		depthRange = 32,
		tunnelScale = 0.015,
		chamberScale = 0.04,
		connectivity = 0.5
	},
	generateFeatures = false, -- Disable features for performance
	generateWaterFlow = false,
	generateEntrances = true,
	enableProgressReporting = true,
	memoryOptimized = true
}

-- ================================================================================================
--                                 PROGRESS REPORTING SYSTEM
-- ================================================================================================

local function createProgressGUI(player: Player): (ScreenGui, Frame, TextLabel, TextLabel)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CaveGenerationProgress"
	screenGui.Parent = player.PlayerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 100)
	frame.Position = UDim2.new(0.5, -200, 0.5, -50)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	frame.Parent = screenGui
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🕳️ Generating Cave System..."
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0.9, 0, 0.2, 0)
	progressBar.Position = UDim2.new(0.05, 0, 0.45, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	progressBar.BorderSizePixel = 1
	progressBar.Parent = frame
	
	local details = Instance.new("TextLabel")
	details.Size = UDim2.new(1, 0, 0.3, 0)
	details.Position = UDim2.new(0, 0, 0.7, 0)
	details.BackgroundTransparency = 1
	details.Text = "Initializing..."
	details.TextColor3 = Color3.fromRGB(200, 200, 200)
	details.TextScaled = true
	details.Font = Enum.Font.Gotham
	details.Parent = frame
	
	return screenGui, progressBar, title, details
end

local function updateProgressGUI(progressBar: Frame, title: TextLabel, details: TextLabel, progress: number, stage: string, detail: string?)
	-- Update progress bar
	progressBar.Size = UDim2.new(0.9 * progress, 0, 0.2, 0)
	
	-- Update color based on progress
	local color = if progress < 0.33 then Color3.fromRGB(150, 50, 50)
		elseif progress < 0.66 then Color3.fromRGB(150, 150, 50)
		else Color3.fromRGB(50, 150, 50)
	progressBar.BackgroundColor3 = color
	
	-- Update text
	title.Text = string.format("🕳️ %s (%.1f%%)", stage, progress * 100)
	details.Text = detail or "Processing..."
end

-- ================================================================================================
--                                    MAIN EXAMPLE FUNCTIONS
-- ================================================================================================

function CaveExample.generateSmallTestCave(terrain: Terrain, player: Player?): ProceduralCaveGenerator.GenerationResult
	print("🧪 Starting Small Test Cave Generation...")
	
	local gui, progressBar, title, details = nil, nil, nil, nil
	if player then
		gui, progressBar, title, details = createProgressGUI(player)
	end
	
	local result = ProceduralCaveGenerator.generateCaveSystem(terrain, SMALL_TEST_CONFIG, function(progress, stage, detail)
		print(string.format("📊 %s: %.1f%% - %s", stage, progress * 100, detail or ""))
		if progressBar and title and details then
			updateProgressGUI(progressBar, title, details, progress, stage, detail)
		end
	end)
	
	-- Cleanup GUI
	if gui then
		wait(2)
		gui:Destroy()
	end
	
	if result.success then
		print("🎉 Small test cave generation completed successfully!")
		CaveExample.printResults(result)
	else
		warn("❌ Small test cave generation failed:", result.error)
	end
	
	return result
end

function CaveExample.generateRealisticNetwork(terrain: Terrain, player: Player?): ProceduralCaveGenerator.GenerationResult
	print("🗻 Starting Realistic Cave Network Generation...")
	
	-- Estimate memory usage first
	local estimatedMemory = ProceduralCaveGenerator.estimateMemoryUsage(REALISTIC_NETWORK_CONFIG)
	print("💾 Estimated memory usage:", string.format("%.2f MB", estimatedMemory / 1024 / 1024))
	
	local gui, progressBar, title, details = nil, nil, nil, nil
	if player then
		gui, progressBar, title, details = createProgressGUI(player)
	end
	
	local result = ProceduralCaveGenerator.generateCaveSystem(terrain, REALISTIC_NETWORK_CONFIG, function(progress, stage, detail)
		print(string.format("📊 %s: %.1f%% - %s", stage, progress * 100, detail or ""))
		if progressBar and title and details then
			updateProgressGUI(progressBar, title, details, progress, stage, detail)
		end
	end)
	
	-- Cleanup GUI
	if gui then
		wait(3)
		gui:Destroy()
	end
	
	if result.success then
		print("🎉 Realistic cave network generation completed successfully!")
		CaveExample.printResults(result)
		
		-- Generate debug visualization
		local viz = ProceduralCaveGenerator.generateDebugVisualization(result)
		if viz then
			CaveExample.createDebugVisualization(viz)
		end
	else
		warn("❌ Realistic cave network generation failed:", result.error)
	end
	
	return result
end

function CaveExample.generateLavaCaves(terrain: Terrain, player: Player?): ProceduralCaveGenerator.GenerationResult
	print("🔥 Starting Lava Cave System Generation...")
	
	local gui, progressBar, title, details = nil, nil, nil, nil
	if player then
		gui, progressBar, title, details = createProgressGUI(player)
	end
	
	local result = ProceduralCaveGenerator.generateCaveSystem(terrain, LAVA_CAVE_CONFIG, function(progress, stage, detail)
		print(string.format("📊 %s: %.1f%% - %s", stage, progress * 100, detail or ""))
		if progressBar and title and details then
			updateProgressGUI(progressBar, title, details, progress, stage, detail)
		end
	end)
	
	-- Cleanup GUI  
	if gui then
		wait(2)
		gui:Destroy()
	end
	
	if result.success then
		print("🎉 Lava cave system generation completed successfully!")
		CaveExample.printResults(result)
	else
		warn("❌ Lava cave system generation failed:", result.error)
	end
	
	return result
end

function CaveExample.generatePerformanceOptimized(terrain: Terrain, player: Player?): ProceduralCaveGenerator.GenerationResult
	print("⚡ Starting Performance Optimized Generation...")
	
	local startTime = os.clock()
	
	local gui, progressBar, title, details = nil, nil, nil, nil
	if player then
		gui, progressBar, title, details = createProgressGUI(player)
	end
	
	local result = ProceduralCaveGenerator.generateCaveSystem(terrain, PERFORMANCE_CONFIG, function(progress, stage, detail)
		print(string.format("📊 %s: %.1f%% - %s", stage, progress * 100, detail or ""))
		if progressBar and title and details then
			updateProgressGUI(progressBar, title, details, progress, stage, detail)
		end
	end)
	
	local endTime = os.clock()
	
	-- Cleanup GUI
	if gui then
		wait(2)
		gui:Destroy()
	end
	
	if result.success then
		print("🎉 Performance optimized generation completed successfully!")
		print("⏱️ Total generation time:", string.format("%.2f seconds", endTime - startTime))
		CaveExample.printResults(result)
	else
		warn("❌ Performance optimized generation failed:", result.error)
	end
	
	return result
end

-- ================================================================================================
--                                 VISUALIZATION & DEBUGGING
-- ================================================================================================

function CaveExample.createDebugVisualization(viz: ProceduralCaveGenerator.DebugVisualization): Folder
	local folder = Instance.new("Folder")
	folder.Name = "CaveDebugVisualization"
	folder.Parent = workspace
	
	-- Visualize cave points
	local caveFolder = Instance.new("Folder")
	caveFolder.Name = "CavePoints"
	caveFolder.Parent = folder
	
	for i, position in pairs(viz.cavePoints) do
		if i <= 1000 then -- Limit visualization points for performance
			local part = Instance.new("Part")
			part.Name = "CavePoint_" .. i
			part.Size = Vector3.new(2, 2, 2)
			part.Position = position
			part.Anchored = true
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.BrickColor = BrickColor.new("Bright blue")
			part.Shape = Enum.PartType.Ball
			part.Parent = caveFolder
		end
	end
	
	-- Visualize entrance points
	local entranceFolder = Instance.new("Folder")
	entranceFolder.Name = "EntrancePoints"
	entranceFolder.Parent = folder
	
	for i, position in pairs(viz.entrancePoints) do
		local part = Instance.new("Part")
		part.Name = "Entrance_" .. i
		part.Size = Vector3.new(6, 6, 6)
		part.Position = position
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.BrickColor = BrickColor.new("Bright green")
		part.Shape = Enum.PartType.Ball
		part.Parent = entranceFolder
	end
	
	-- Visualize feature points
	local featureFolder = Instance.new("Folder")
	featureFolder.Name = "FeaturePoints"
	featureFolder.Parent = folder
	
	for i, position in pairs(viz.featurePoints) do
		if i <= 500 then -- Limit feature visualization
			local part = Instance.new("Part")
			part.Name = "Feature_" .. i
			part.Size = Vector3.new(1, 3, 1)
			part.Position = position
			part.Anchored = true
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.BrickColor = BrickColor.new("Bright yellow")
			part.Parent = featureFolder
		end
	end
	
	-- Visualize water flow lines
	local flowFolder = Instance.new("Folder")
	flowFolder.Name = "WaterFlowLines"
	flowFolder.Parent = folder
	
	for i, flowPath in pairs(viz.waterFlowLines) do
		if i <= 50 then -- Limit flow line visualization
			for j = 1, #flowPath - 1 do
				local startPos = flowPath[j]
				local endPos = flowPath[j + 1]
				
				local distance = (endPos - startPos).Magnitude
				local midpoint = (startPos + endPos) * 0.5
				
				local part = Instance.new("Part")
				part.Name = "FlowSegment_" .. i .. "_" .. j
				part.Size = Vector3.new(0.5, 0.5, distance)
				part.CFrame = CFrame.lookAt(midpoint, endPos)
				part.Anchored = true
				part.CanCollide = false
				part.Material = Enum.Material.Neon
				part.BrickColor = BrickColor.new("Cyan")
				part.Parent = flowFolder
			end
		end
	end
	
	print("🎨 Debug visualization created with", #viz.cavePoints, "cave points,", #viz.entrancePoints, "entrances,", #viz.featurePoints, "features")
	
	return folder
end

function CaveExample.printResults(result: ProceduralCaveGenerator.GenerationResult): ()
	if not result.success then
		print("❌ Generation failed:", result.error)
		return
	end
	
	print("=" .. string.rep("=", 50))
	print("📊 CAVE GENERATION RESULTS")
	print("=" .. string.rep("=", 50))
	print("✅ Success:", result.success)
	print("🕳️ Total Caves:", result.totalCaves)
	print("💎 Total Features:", result.totalFeatures)
	print("🚪 Total Entrances:", result.totalEntrances)
	print("📦 Total Chunks:", result.chunks and #result.chunks or 0)
	print("💧 Water Flow Paths:", result.waterFlowPaths and #result.waterFlowPaths or 0)
	
	if result.performanceStats then
		print("⚡ Performance Stats:")
		print("   • Cache Hit Rate:", string.format("%.1f%%", (result.performanceStats.cacheStats.hits / (result.performanceStats.cacheStats.hits + result.performanceStats.cacheStats.misses)) * 100))
		print("   • Peak Memory:", string.format("%.2f KB", result.performanceStats.peakMemoryUsage))
		print("   • Avg Execution Time:", string.format("%.2f ms", result.performanceStats.averageExecutionTime))
	end
	
	print("=" .. string.rep("=", 50))
end

-- ================================================================================================
--                                 ADVANCED USAGE EXAMPLES
-- ================================================================================================

function CaveExample.generateCustomCaveSystem(terrain: Terrain, customSettings: ProceduralCaveGenerator.CaveGenerationSettings, player: Player?): ProceduralCaveGenerator.GenerationResult
	print("🛠️ Starting Custom Cave System Generation...")
	print("📝 Custom Settings:")
	print("   • Region Size:", customSettings.region.Size)
	print("   • Chunk Size:", customSettings.chunkSize or "default")
	print("   • Resolution:", customSettings.resolution or "default")
	
	-- Validate settings
	if not ProceduralCaveGenerator.validateSettings(customSettings) then
		warn("❌ Invalid settings provided")
		return {success = false, error = "Invalid settings"}
	end
	
	local gui, progressBar, title, details = nil, nil, nil, nil
	if player then
		gui, progressBar, title, details = createProgressGUI(player)
	end
	
	local result = ProceduralCaveGenerator.generateCaveSystem(terrain, customSettings, function(progress, stage, detail)
		print(string.format("📊 %s: %.1f%% - %s", stage, progress * 100, detail or ""))
		if progressBar and title and details then
			updateProgressGUI(progressBar, title, details, progress, stage, detail)
		end
	end)
	
	-- Cleanup GUI
	if gui then
		wait(2)
		gui:Destroy()
	end
	
	if result.success then
		print("🎉 Custom cave system generation completed successfully!")
		CaveExample.printResults(result)
	else
		warn("❌ Custom cave system generation failed:", result.error)
	end
	
	return result
end

function CaveExample.benchmarkGeneration(terrain: Terrain): {[string]: number}
	print("📊 Starting Cave Generation Benchmarks...")
	
	local results = {}
	
	-- Benchmark small cave
	print("🧪 Benchmarking small cave...")
	local startTime = os.clock()
	local smallResult = ProceduralCaveGenerator.generateCaveSystem(terrain, SMALL_TEST_CONFIG)
	results["Small Cave"] = os.clock() - startTime
	
	-- Clean up
	terrain:FillRegion(SMALL_TEST_CONFIG.region, 4, Enum.Material.Air)
	
	-- Benchmark with different resolutions
	local function cloneTable(original)
		local copy = {}
		for key, value in pairs(original) do
			if type(value) == "table" then
				copy[key] = cloneTable(value)
			else
				copy[key] = value
			end
		end
		return copy
	end
	
	local resolutionTest = cloneTable(SMALL_TEST_CONFIG)
	
	for _, resolution in pairs({2, 4, 8}) do
		resolutionTest.resolution = resolution
		print(string.format("📏 Benchmarking resolution %d...", resolution))
		
		startTime = os.clock()
		local resResult = ProceduralCaveGenerator.generateCaveSystem(terrain, resolutionTest)
		results[string.format("Resolution_%d", resolution)] = os.clock() - startTime
		
		-- Clean up
		terrain:FillRegion(resolutionTest.region, 4, Enum.Material.Air)
	end
	
	print("📊 Benchmark Results:")
	for testName, time in pairs(results) do
		print(string.format("   • %s: %.2f seconds", testName, time))
	end
	
	return results
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function CaveExample.clearTerrain(terrain: Terrain, region: Region3): ()
	print("🧹 Clearing terrain in region:", region.Size)
	terrain:FillRegion(region, 4, Enum.Material.Air)
	print("✅ Terrain cleared")
end

function CaveExample.showUsageInstructions(): ()
	print("=" .. string.rep("=", 60))
	print("🕳️ PROCEDURAL CAVE GENERATOR - USAGE INSTRUCTIONS")
	print("=" .. string.rep("=", 60))
	print("")
	print("📖 Available Functions:")
	print("   • CaveExample.generateSmallTestCave(terrain, player?)")
	print("   • CaveExample.generateRealisticNetwork(terrain, player?)")
	print("   • CaveExample.generateLavaCaves(terrain, player?)")
	print("   • CaveExample.generatePerformanceOptimized(terrain, player?)")
	print("   • CaveExample.generateCustomCaveSystem(terrain, settings, player?)")
	print("   • CaveExample.benchmarkGeneration(terrain)")
	print("   • CaveExample.clearTerrain(terrain, region)")
	print("")
	print("🎯 Quick Start:")
	print("   local terrain = workspace.Terrain")
	print("   local result = CaveExample.generateSmallTestCave(terrain)")
	print("")
	print("🛠️ Custom Configuration:")
	print("   local settings = ProceduralCaveGenerator.Presets.REALISTIC_CAVE_SYSTEM")
	print("   local result = CaveExample.generateCustomCaveSystem(terrain, settings)")
	print("")
	print("=" .. string.rep("=", 60))
end

-- Show instructions when module is loaded
CaveExample.showUsageInstructions()

return CaveExample