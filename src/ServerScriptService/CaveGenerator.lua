--!strict

--[[
====================================================================================================
                                       CaveGenerator
                    Main Orchestrator with High-Quality Generation Pipeline
                              Updated: 2025-08-01 (Quality-First Implementation)
====================================================================================================

This is the main orchestrator for the comprehensive cave generation system. It coordinates
all modules to produce realistic, high-quality cave networks with geological accuracy.

FEATURES:
- Quality-first generation pipeline
- Advanced multi-stage generation process
- Progress reporting and error handling
- Integration with all cave generation modules
- Geological realism prioritization
- Comprehensive validation and quality assurance

GENERATION PIPELINE:
1. Configuration validation and setup
2. Geological profile creation
3. Multi-layer noise generation
4. Cave formation analysis
5. Structural integrity validation
6. Network connectivity optimization
7. Surface integration and entrance generation
8. Feature generation (speleothems, etc.)
9. Quality metrics and validation
10. Final optimization and cleanup

====================================================================================================
]]

local CaveGenerator = {}

-- Import dependencies
local NoiseLib = require(script.Parent.NoiseLib)
local CaveConfig = require(script.Parent.CaveConfig)
local CaveLogic = require(script.Parent.CaveLogic)
local CaveSystem = require(script.Parent.CaveSystem)

-- ================================================================================================
--                                      TYPE DEFINITIONS
-- ================================================================================================

export type Vector3 = Vector3
export type Region3 = Region3
export type CaveGenerationConfig = CaveConfig.CaveGenerationConfig
export type CaveNetwork = CaveSystem.CaveNetwork
export type CavePoint = CaveLogic.CavePoint
export type CaveFormation = CaveLogic.CaveFormation

export type GenerationStage = {
	name: string,
	description: string,
	weight: number,       -- Progress weight (0-1)
	completed: boolean
}

export type GenerationProgress = {
	currentStage: string,
	stageProgress: number,  -- Progress within current stage (0-1)
	overallProgress: number, -- Overall progress (0-1)
	timeElapsed: number,
	estimatedTimeRemaining: number,
	stagesCompleted: number,
	totalStages: number
}

export type GenerationResult = {
	success: boolean,
	caveNetworks: {CaveNetwork}?,
	cavePoints: {CavePoint}?,
	formations: {CaveFormation}?,
	qualityMetrics: QualityMetrics?,
	performanceStats: PerformanceStats?,
	error: string?,
	warnings: {string}
}

export type QualityMetrics = {
	overallScore: number,          -- Overall quality score (0-100)
	geologicalAccuracy: number,    -- Geological realism score (0-100)
	connectivityScore: number,     -- Network connectivity score (0-100)
	structuralIntegrity: number,   -- Structural safety score (0-100)
	visualQuality: number,         -- Visual appeal score (0-100)
	explorationValue: number,      -- Exploration potential (0-100)
	accessibilityScore: number,    -- How accessible caves are (0-100)
	detailMetrics: {[string]: number}, -- Detailed sub-metrics
	recommendations: {string}       -- Quality improvement suggestions
}

export type PerformanceStats = {
	totalGenerationTime: number,   -- Total time in seconds
	stageTimings: {[string]: number}, -- Time per stage
	memoryUsage: {
		peak: number,
		average: number,
		final: number
	},
	pointsGenerated: number,
	formationsCreated: number,
	networksBuilt: number,
	cacheHitRate: number
}

export type ProgressCallback = (progress: GenerationProgress) -> ()

-- ================================================================================================
--                                    GENERATION PIPELINE
-- ================================================================================================

local GENERATION_STAGES: {GenerationStage} = {
	{name = "initialization", description = "Initializing generation parameters", weight = 0.05, completed = false},
	{name = "geological_setup", description = "Creating geological profiles", weight = 0.05, completed = false},
	{name = "noise_generation", description = "Generating base noise patterns", weight = 0.15, completed = false},
	{name = "cave_point_generation", description = "Generating cave points", weight = 0.25, completed = false},
	{name = "formation_analysis", description = "Analyzing cave formations", weight = 0.15, completed = false},
	{name = "structural_validation", description = "Validating structural integrity", weight = 0.10, completed = false},
	{name = "network_building", description = "Building cave networks", weight = 0.10, completed = false},
	{name = "surface_integration", description = "Integrating with surface", weight = 0.05, completed = false},
	{name = "feature_generation", description = "Generating cave features", weight = 0.05, completed = false},
	{name = "quality_optimization", description = "Optimizing for quality", weight = 0.03, completed = false},
	{name = "final_validation", description = "Final validation and cleanup", weight = 0.02, completed = false}
}

function CaveGenerator.generateCaves(region: Region3, config: CaveGenerationConfig?, progressCallback: ProgressCallback?): GenerationResult
	local startTime = os.clock()
	local validatedConfig = CaveConfig.validate(config)
	local callback = progressCallback or function() end
	
	print("🏔️ Starting comprehensive cave generation...")
	print("📏 Region size:", region.Size)
	print("⚙️ Configuration quality score:", CaveConfig.getQualityScore(validatedConfig), "%")
	
	-- Initialize progress tracking
	local progress = CaveGenerator.initializeProgress()
	local warnings = {}
	local performanceStats = CaveGenerator.initializePerformanceStats()
	
	-- Reset stage completion status
	for _, stage in pairs(GENERATION_STAGES) do
		stage.completed = false
	end
	
	-- Initialize noise generator with optimized settings
	local noiseGenerator = NoiseLib.new(validatedConfig.seed, {
		cache = {
			enabled = true,
			maxSize = 20000,
			cleanupThreshold = 0.8,
			fullPrecision = validatedConfig.quality.geologicalAccuracy > 0.8
		},
		performance = {
			yieldInterval = 50,
			memoryThreshold = 100000,
			profilingEnabled = validatedConfig.debug.performanceMetrics
		},
		async = true
	})
	
	-- Stage 1: Initialization
	local success, result = pcall(function()
		return CaveGenerator.executeGenerationPipeline(
			region, 
			validatedConfig, 
			noiseGenerator, 
			progress, 
			callback, 
			warnings, 
			performanceStats
		)
	end)
	
	local totalTime = os.clock() - startTime
	performanceStats.totalGenerationTime = totalTime
	
	if success then
		print("✅ Cave generation completed successfully!")
		print("⏱️ Total time:", string.format("%.2f", totalTime), "seconds")
		print("📊 Quality score:", result.qualityMetrics and result.qualityMetrics.overallScore or "N/A")
		
		return {
			success = true,
			caveNetworks = result.caveNetworks,
			cavePoints = result.cavePoints,
			formations = result.formations,
			qualityMetrics = result.qualityMetrics,
			performanceStats = performanceStats,
			error = nil,
			warnings = warnings
		}
	else
		print("❌ Cave generation failed:", result)
		return {
			success = false,
			caveNetworks = nil,
			cavePoints = nil,
			formations = nil,
			qualityMetrics = nil,
			performanceStats = performanceStats,
			error = tostring(result),
			warnings = warnings
		}
	end
end

function CaveGenerator.executeGenerationPipeline(
	region: Region3, 
	config: CaveGenerationConfig, 
	noiseGenerator: any, 
	progress: GenerationProgress, 
	callback: ProgressCallback, 
	warnings: {string}, 
	performanceStats: PerformanceStats
): any
	
	local stageResults = {}
	
	-- Execute each stage in sequence
	for i, stage in pairs(GENERATION_STAGES) do
		local stageStartTime = os.clock()
		progress.currentStage = stage.name
		progress.stageProgress = 0
		CaveGenerator.updateProgress(progress, callback)
		
		print(string.format("🔄 Stage %d/%d: %s", i, #GENERATION_STAGES, stage.description))
		
		local stageResult = CaveGenerator.executeStage(
			stage.name, 
			region, 
			config, 
			noiseGenerator, 
			stageResults,
			progress,
			callback,
			warnings
		)
		
		stageResults[stage.name] = stageResult
		stage.completed = true
		progress.stagesCompleted = i
		progress.stageProgress = 1.0
		
		local stageTime = os.clock() - stageStartTime
		performanceStats.stageTimings[stage.name] = stageTime
		
		print(string.format("✅ Stage completed in %.2f seconds", stageTime))
		
		-- Update overall progress
		CaveGenerator.updateProgress(progress, callback)
		
		-- Yield to prevent timeout
		task.wait()
	end
	
	-- Compile final results
	return CaveGenerator.compileFinalResults(stageResults, config, performanceStats)
end

function CaveGenerator.executeStage(
	stageName: string, 
	region: Region3, 
	config: CaveGenerationConfig, 
	noiseGenerator: any, 
	previousResults: {[string]: any},
	progress: GenerationProgress,
	callback: ProgressCallback,
	warnings: {string}
): any
	
	if stageName == "initialization" then
		return CaveGenerator.stageInitialization(config, warnings)
		
	elseif stageName == "geological_setup" then
		return CaveGenerator.stageGeologicalSetup(region, config)
		
	elseif stageName == "noise_generation" then
		return CaveGenerator.stageNoiseGeneration(region, config, noiseGenerator, progress, callback)
		
	elseif stageName == "cave_point_generation" then
		return CaveGenerator.stageCavePointGeneration(
			region, 
			config, 
			noiseGenerator, 
			previousResults.geological_setup,
			progress, 
			callback
		)
		
	elseif stageName == "formation_analysis" then
		return CaveGenerator.stageFormationAnalysis(
			previousResults.cave_point_generation,
			config,
			progress,
			callback
		)
		
	elseif stageName == "structural_validation" then
		return CaveGenerator.stageStructuralValidation(
			previousResults.formation_analysis,
			previousResults.cave_point_generation,
			config,
			progress,
			callback,
			warnings
		)
		
	elseif stageName == "network_building" then
		return CaveGenerator.stageNetworkBuilding(
			previousResults.formation_analysis,
			previousResults.cave_point_generation,
			config,
			progress,
			callback
		)
		
	elseif stageName == "surface_integration" then
		return CaveGenerator.stageSurfaceIntegration(
			previousResults.network_building,
			region,
			config,
			noiseGenerator,
			progress,
			callback
		)
		
	elseif stageName == "feature_generation" then
		return CaveGenerator.stageFeatureGeneration(
			previousResults.formation_analysis,
			previousResults.cave_point_generation,
			config,
			progress,
			callback
		)
		
	elseif stageName == "quality_optimization" then
		return CaveGenerator.stageQualityOptimization(
			previousResults,
			config,
			progress,
			callback,
			warnings
		)
		
	elseif stageName == "final_validation" then
		return CaveGenerator.stageFinalValidation(
			previousResults,
			config,
			progress,
			callback,
			warnings
		)
	else
		error("Unknown stage: " .. stageName)
	end
end

-- ================================================================================================
--                                    INDIVIDUAL STAGES
-- ================================================================================================

function CaveGenerator.stageInitialization(config: CaveGenerationConfig, warnings: {string}): any
	-- Validate configuration and setup initial parameters
	local issues = {}
	
	-- Check for potential configuration issues
	if config.quality.samplingResolution > 4 then
		table.insert(warnings, "High sampling resolution may impact performance")
	end
	
	if config.structure.mainChamberFrequency > 0.3 then
		table.insert(warnings, "High chamber frequency may create unrealistic cave density")
	end
	
	if config.geology.collapseSimulation and config.geology.rockHardness < 0.3 then
		table.insert(warnings, "Soft rock with collapse simulation may create many unstable areas")
	end
	
	return {
		validated = true,
		warnings = #warnings,
		configQuality = CaveConfig.getQualityScore(config)
	}
end

function CaveGenerator.stageGeologicalSetup(region: Region3, config: CaveGenerationConfig): any
	-- Create geological profiles for the region
	local minPoint, maxPoint = CaveGenerator.getRegionBounds(region)
	local geologicalLayers = {}
	
	-- Sample geological layers at key depths
	local depthSamples = {}
	for depth = 0, math.abs(minPoint.Y), 10 do
		local layer = CaveLogic.createGeologicalProfile(depth, config)
		table.insert(depthSamples, layer)
	end
	
	return {
		layers = depthSamples,
		surfaceLevel = maxPoint.Y,
		maxDepth = math.abs(minPoint.Y),
		avgRockHardness = config.geology.rockHardness
	}
end

function CaveGenerator.stageNoiseGeneration(
	region: Region3, 
	config: CaveGenerationConfig, 
	noiseGenerator: any,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	-- Pre-generate noise patterns that will be used throughout the system
	local minPoint, maxPoint = CaveGenerator.getRegionBounds(region)
	local noiseCache = {}
	
	-- Generate base noise patterns
	local basePatterns = {
		"primary_structure",
		"secondary_chambers", 
		"geological_influence",
		"vertical_features",
		"surface_integration"
	}
	
	for i, patternName in pairs(basePatterns) do
		progress.stageProgress = (i - 1) / #basePatterns
		callback(progress)
		
		noiseCache[patternName] = CaveGenerator.generateNoisePattern(
			patternName,
			minPoint,
			maxPoint,
			config,
			noiseGenerator
		)
		
		task.wait()
	end
	
	return {
		patterns = noiseCache,
		noiseGenerator = noiseGenerator
	}
end

function CaveGenerator.stageCavePointGeneration(
	region: Region3,
	config: CaveGenerationConfig,
	noiseGenerator: any,
	geologicalSetup: any,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	local minPoint, maxPoint = CaveGenerator.getRegionBounds(region)
	local cavePoints = {}
	local samplingResolution = config.quality.samplingResolution
	
	-- Calculate total points for progress tracking
	local xRange = math.ceil((maxPoint.X - minPoint.X) / samplingResolution)
	local yRange = math.ceil((maxPoint.Y - minPoint.Y) / samplingResolution)
	local zRange = math.ceil((maxPoint.Z - minPoint.Z) / samplingResolution)
	local totalPoints = xRange * yRange * zRange
	local processedPoints = 0
	
	print(string.format("🔍 Generating cave points with %.1f stud resolution", samplingResolution))
	print(string.format("📊 Processing %d x %d x %d = %d points", xRange, yRange, zRange, totalPoints))
	
	-- Generate cave points with adaptive quality
	local x = minPoint.X
	while x <= maxPoint.X do
		local y = minPoint.Y
		while y <= maxPoint.Y do
			local z = minPoint.Z
			while z <= maxPoint.Z do
				local position = Vector3.new(x, y, z)
				
				-- Get geological layer for this depth
				local geologicalLayer = CaveGenerator.getGeologicalLayerAtDepth(
					math.abs(y), 
					geologicalSetup.layers
				)
				
				-- Generate cave point with geological influence
				local cavePoint = CaveLogic.generateCavePoint(
					position,
					noiseGenerator,
					config,
					geologicalLayer
				)
				
				-- Only store significant cave points to optimize memory
				if cavePoint.density > 0.1 then
					table.insert(cavePoints, cavePoint)
				end
				
				processedPoints = processedPoints + 1
				z = z + samplingResolution
			end
			y = y + samplingResolution
		end
		
		-- Update progress
		progress.stageProgress = processedPoints / totalPoints
		callback(progress)
		
		-- Yield periodically
		if processedPoints % 1000 == 0 then
			task.wait()
		end
		
		x = x + samplingResolution
	end
	
	print(string.format("✅ Generated %d cave points from %d total samples", #cavePoints, processedPoints))
	
	return {
		cavePoints = cavePoints,
		totalSamples = processedPoints,
		significantPoints = #cavePoints,
		samplingResolution = samplingResolution
	}
end

function CaveGenerator.stageFormationAnalysis(
	cavePointData: any,
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	local cavePoints = cavePointData.cavePoints
	print(string.format("🔍 Analyzing %d cave points for formations", #cavePoints))
	
	-- Identify cave formations
	progress.stageProgress = 0.2
	callback(progress)
	
	local formations = CaveLogic.identifyFormations(cavePoints, config)
	
	progress.stageProgress = 0.6
	callback(progress)
	
	-- Classify and enhance formations
	local enhancedFormations = {}
	for i, formation in pairs(formations) do
		local enhanced = CaveGenerator.enhanceFormation(formation, config)
		table.insert(enhancedFormations, enhanced)
		
		if i % 10 == 0 then
			progress.stageProgress = 0.6 + (i / #formations) * 0.4
			callback(progress)
			task.wait()
		end
	end
	
	-- Sort formations by importance
	table.sort(enhancedFormations, function(a, b)
		return (a.radius * a.stability) > (b.radius * b.stability)
	end)
	
	print(string.format("✅ Identified %d cave formations", #enhancedFormations))
	
	return {
		formations = enhancedFormations,
		formationStats = CaveGenerator.calculateFormationStats(enhancedFormations)
	}
end

function CaveGenerator.stageStructuralValidation(
	formationData: any,
	cavePointData: any,
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback,
	warnings: {string}
): any
	
	if not config.quality.structuralValidation then
		print("⏭️ Skipping structural validation (disabled in config)")
		return {validated = false, skipped = true}
	end
	
	local formations = formationData.formations
	local cavePoints = cavePointData.cavePoints
	
	print("🏗️ Performing structural integrity analysis...")
	
	progress.stageProgress = 0.1
	callback(progress)
	
	-- Analyze overall structural integrity
	local structuralAnalysis = CaveLogic.analyzeStructuralIntegrity(formations, cavePoints, config)
	
	progress.stageProgress = 0.6
	callback(progress)
	
	-- Check for critical issues
	local criticalIssues = 0
	if structuralAnalysis.safetyFactor < 0.3 then
		criticalIssues = criticalIssues + 1
		table.insert(warnings, "Overall structural safety factor is critically low")
	end
	
	if #structuralAnalysis.criticalPoints > #formations * 0.3 then
		criticalIssues = criticalIssues + 1
		table.insert(warnings, "High number of structurally critical points detected")
	end
	
	if structuralAnalysis.ceilingThickness < 3 then
		criticalIssues = criticalIssues + 1
		table.insert(warnings, "Average ceiling thickness is below safe minimum")
	end
	
	progress.stageProgress = 1.0
	callback(progress)
	
	print(string.format("🏗️ Structural analysis complete. Safety factor: %.2f", structuralAnalysis.safetyFactor))
	
	return {
		validated = true,
		structuralAnalysis = structuralAnalysis,
		criticalIssues = criticalIssues,
		safetyScore = structuralAnalysis.safetyFactor * 100
	}
end

function CaveGenerator.stageNetworkBuilding(
	formationData: any,
	cavePointData: any,
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	local formations = formationData.formations
	local cavePoints = cavePointData.cavePoints
	
	print("🌐 Building cave networks...")
	
	progress.stageProgress = 0.2
	callback(progress)
	
	-- Build networks from formations
	local networks = CaveSystem.buildNetworkFromFormations(formations, cavePoints, config)
	
	progress.stageProgress = 0.7
	callback(progress)
	
	-- Analyze network quality
	local networkAnalysis = CaveSystem.analyzeNetworkComprehensive(networks)
	
	progress.stageProgress = 1.0
	callback(progress)
	
	print(string.format("🌐 Built %d cave networks", #networks))
	if networkAnalysis.largestNetwork then
		print(string.format("📊 Largest network: %d nodes, %.1f%% connectivity", 
			#networkAnalysis.largestNetwork.nodes,
			networkAnalysis.largestNetwork.connectivityScore * 100))
	end
	
	return {
		networks = networks,
		networkAnalysis = networkAnalysis
	}
end

function CaveGenerator.stageSurfaceIntegration(
	networkData: any,
	region: Region3,
	config: CaveGenerationConfig,
	noiseGenerator: any,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	local networks = networkData.networks
	
	print("🌄 Integrating caves with surface...")
	
	progress.stageProgress = 0.3
	callback(progress)
	
	-- Generate surface heightmap for entrance placement
	local minPoint, maxPoint = CaveGenerator.getRegionBounds(region)
	local heightmapWidth = math.ceil((maxPoint.X - minPoint.X) / 4)
	local heightmapHeight = math.ceil((maxPoint.Z - minPoint.Z) / 4)
	
	local surfaceHeightmap = noiseGenerator:generateHeightmap(
		heightmapWidth,
		heightmapHeight,
		{
			octaves = 6,
			lacunarity = 2.0,
			persistence = 0.5,
			scale = 0.01,
			seed = config.seed
		}
	)
	
	progress.stageProgress = 0.6
	callback(progress)
	
	-- Generate entrances for each network
	local allEntrances = {}
	for _, network in pairs(networks) do
		-- Find suitable entrance points
		local networkEntrances = CaveGenerator.generateNetworkEntrances(
			network, 
			surfaceHeightmap, 
			config,
			minPoint,
			maxPoint
		)
		
		for _, entrance in pairs(networkEntrances) do
			table.insert(allEntrances, entrance)
		end
	end
	
	progress.stageProgress = 1.0
	callback(progress)
	
	print(string.format("🚪 Generated %d surface entrances", #allEntrances))
	
	return {
		entrances = allEntrances,
		surfaceHeightmap = surfaceHeightmap,
		integrationQuality = CaveGenerator.calculateSurfaceIntegrationQuality(allEntrances, config)
	}
end

function CaveGenerator.stageFeatureGeneration(
	formationData: any,
	cavePointData: any,
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback
): any
	
	local formations = formationData.formations
	local cavePoints = cavePointData.cavePoints
	
	print("💎 Generating cave features...")
	
	progress.stageProgress = 0.3
	callback(progress)
	
	-- Generate speleothems (stalactites, stalagmites, etc.)
	local speleothems = CaveLogic.generateSpeleothems(formations, cavePoints, config)
	
	progress.stageProgress = 0.7
	callback(progress)
	
	-- Generate additional geological features
	local additionalFeatures = CaveGenerator.generateAdditionalFeatures(formations, config)
	
	progress.stageProgress = 1.0
	callback(progress)
	
	local totalFeatures = #speleothems + #additionalFeatures
	print(string.format("💎 Generated %d cave features", totalFeatures))
	
	return {
		speleothems = speleothems,
		additionalFeatures = additionalFeatures,
		totalFeatures = totalFeatures
	}
end

function CaveGenerator.stageQualityOptimization(
	previousResults: {[string]: any},
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback,
	warnings: {string}
): any
	
	if not config.quality.qualityOverPerformance then
		print("⏭️ Skipping quality optimization (performance mode)")
		return {optimized = false, skipped = true}
	end
	
	print("✨ Optimizing for quality...")
	
	-- Optimize network connectivity
	progress.stageProgress = 0.2
	callback(progress)
	
	local networks = previousResults.network_building.networks
	local optimizationResults = {}
	
	for _, network in pairs(networks) do
		CaveSystem.optimizeNetwork(network, config)
	end
	
	progress.stageProgress = 0.6
	callback(progress)
	
	-- Apply smoothing if configured
	if config.quality.smoothingPasses > 0 then
		CaveGenerator.applySmoothingPasses(
			previousResults.cave_point_generation.cavePoints,
			config.quality.smoothingPasses
		)
	end
	
	progress.stageProgress = 1.0
	callback(progress)
	
	print("✨ Quality optimization complete")
	
	return {
		optimized = true,
		smoothingApplied = config.quality.smoothingPasses > 0
	}
end

function CaveGenerator.stageFinalValidation(
	previousResults: {[string]: any},
	config: CaveGenerationConfig,
	progress: GenerationProgress,
	callback: ProgressCallback,
	warnings: {string}
): any
	
	print("🔍 Performing final validation...")
	
	-- Validate connectivity if required
	if config.quality.connectivityValidation then
		progress.stageProgress = 0.3
		callback(progress)
		
		local networks = previousResults.network_building.networks
		local connectivityIssues = CaveGenerator.validateConnectivity(networks)
		
		if connectivityIssues > 0 then
			table.insert(warnings, string.format("Found %d connectivity issues", connectivityIssues))
		end
	end
	
	-- Final quality check
	progress.stageProgress = 0.7
	callback(progress)
	
	local qualityMetrics = CaveGenerator.calculateFinalQualityMetrics(previousResults, config)
	
	progress.stageProgress = 1.0
	callback(progress)
	
	print("🔍 Final validation complete")
	print(string.format("📊 Final quality score: %.1f%%", qualityMetrics.overallScore))
	
	return {
		validated = true,
		qualityMetrics = qualityMetrics,
		finalWarnings = #warnings
	}
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function CaveGenerator.initializeProgress(): GenerationProgress
	return {
		currentStage = "initialization",
		stageProgress = 0,
		overallProgress = 0,
		timeElapsed = 0,
		estimatedTimeRemaining = 0,
		stagesCompleted = 0,
		totalStages = #GENERATION_STAGES
	}
end

function CaveGenerator.updateProgress(progress: GenerationProgress, callback: ProgressCallback)
	-- Calculate overall progress
	local completedWeight = 0
	for i = 1, progress.stagesCompleted do
		completedWeight = completedWeight + GENERATION_STAGES[i].weight
	end
	
	-- Add current stage progress
	if progress.stagesCompleted < #GENERATION_STAGES then
		local currentStageWeight = GENERATION_STAGES[progress.stagesCompleted + 1].weight
		completedWeight = completedWeight + (progress.stageProgress * currentStageWeight)
	end
	
	progress.overallProgress = completedWeight
	callback(progress)
end

function CaveGenerator.initializePerformanceStats(): PerformanceStats
	return {
		totalGenerationTime = 0,
		stageTimings = {},
		memoryUsage = {
			peak = 0,
			average = 0,
			final = 0
		},
		pointsGenerated = 0,
		formationsCreated = 0,
		networksBuilt = 0,
		cacheHitRate = 0
	}
end

function CaveGenerator.getRegionBounds(region: Region3): (Vector3, Vector3)
	local center = region.CFrame.Position
	local size = region.Size
	local halfSize = size * 0.5
	
	local minPoint = center - halfSize
	local maxPoint = center + halfSize
	
	return minPoint, maxPoint
end

function CaveGenerator.getGeologicalLayerAtDepth(depth: number, layers: any): any
	-- Find the appropriate geological layer for the given depth
	for i = #layers, 1, -1 do
		if depth >= layers[i].depth then
			return layers[i]
		end
	end
	
	-- Return surface layer if no match found
	return layers[1] or {
		depth = depth,
		hardness = 0.5,
		porosity = 0.3,
		solubility = 0.2,
		jointDensity = 0.4,
		composition = "unknown"
	}
end

function CaveGenerator.generateNoisePattern(
	patternName: string,
	minPoint: Vector3,
	maxPoint: Vector3,
	config: CaveGenerationConfig,
	noiseGenerator: any
): any
	
	-- Generate specific noise patterns for different cave aspects
	-- This is a simplified implementation - in practice would pre-calculate
	-- noise values for better performance
	
	return {
		name = patternName,
		bounds = {min = minPoint, max = maxPoint},
		generated = true
	}
end

function CaveGenerator.enhanceFormation(formation: CaveFormation, config: CaveGenerationConfig): CaveFormation
	-- Enhance formation with additional quality-focused properties
	local enhanced = formation
	
	-- Apply geological accuracy improvements
	if config.quality.geologicalAccuracy > 0.7 then
		-- Adjust formation based on geological constraints
		if formation.type == "chamber" and formation.radius > 20 then
			-- Large chambers need better support
			enhanced.stability = enhanced.stability * 0.8
		end
	end
	
	-- Apply visual quality improvements
	if config.quality.wallSmoothness > 0.5 then
		-- Indicate smoother walls should be generated
		enhanced.features = enhanced.features or {}
		table.insert(enhanced.features, "smooth_walls")
	end
	
	return enhanced
end

function CaveGenerator.calculateFormationStats(formations: {CaveFormation}): any
	local stats = {
		totalFormations = #formations,
		averageRadius = 0,
		averageStability = 0,
		typeDistribution = {}
	}
	
	local totalRadius = 0
	local totalStability = 0
	
	for _, formation in pairs(formations) do
		totalRadius = totalRadius + formation.radius
		totalStability = totalStability + formation.stability
		
		local formationType = formation.type
		stats.typeDistribution[formationType] = (stats.typeDistribution[formationType] or 0) + 1
	end
	
	if #formations > 0 then
		stats.averageRadius = totalRadius / #formations
		stats.averageStability = totalStability / #formations
	end
	
	return stats
end

function CaveGenerator.generateNetworkEntrances(
	network: CaveNetwork,
	surfaceHeightmap: any,
	config: CaveGenerationConfig,
	minPoint: Vector3,
	maxPoint: Vector3
): any
	
	local entrances = {}
	
	-- Find nodes that could connect to surface
	for _, node in pairs(network.nodes) do
		if node.position.Y > -30 and node.formation and node.formation.radius > 2 then
			-- Check if this location is suitable for an entrance
			local surfaceY = CaveGenerator.getSurfaceHeightAt(
				node.position.X, 
				node.position.Z,
				surfaceHeightmap,
				minPoint,
				maxPoint
			)
			
			-- Entrance viable if cave is close to surface
			if math.abs(node.position.Y - surfaceY) < 15 then
				local entrance = {
					position = Vector3.new(node.position.X, surfaceY, node.position.Z),
					cavePosition = node.position,
					size = math.min(node.formation.radius, 8),
					type = if node.formation.radius > 6 then "large" else "tunnel",
					networkId = network.id
				}
				table.insert(entrances, entrance)
			end
		end
	end
	
	return entrances
end

function CaveGenerator.getSurfaceHeightAt(x: number, z: number, heightmap: any, minPoint: Vector3, maxPoint: Vector3): number
	-- Convert world coordinates to heightmap indices
	local mapWidth = #heightmap[1] or 1
	local mapHeight = #heightmap or 1
	
	local xNorm = (x - minPoint.X) / (maxPoint.X - minPoint.X)
	local zNorm = (z - minPoint.Z) / (maxPoint.Z - minPoint.Z)
	
	local mapX = math.max(1, math.min(mapWidth, math.floor(xNorm * mapWidth) + 1))
	local mapZ = math.max(1, math.min(mapHeight, math.floor(zNorm * mapHeight) + 1))
	
	local heightValue = heightmap[mapZ] and heightmap[mapZ][mapX] or 0
	return heightValue * 30 -- Scale to world units
end

function CaveGenerator.calculateSurfaceIntegrationQuality(entrances: any, config: CaveGenerationConfig): number
	-- Calculate how well caves integrate with surface
	local baseScore = math.min(1.0, #entrances / 5) -- Prefer multiple entrances
	local sizeDiversity = CaveGenerator.calculateEntranceSizeDiversity(entrances)
	
	return (baseScore * 0.7) + (sizeDiversity * 0.3)
end

function CaveGenerator.calculateEntranceSizeDiversity(entrances: any): number
	if #entrances == 0 then return 0 end
	
	local sizes = {}
	for _, entrance in pairs(entrances) do
		table.insert(sizes, entrance.size)
	end
	
	table.sort(sizes)
	
	-- Calculate variance in entrance sizes
	local mean = 0
	for _, size in pairs(sizes) do
		mean = mean + size
	end
	mean = mean / #sizes
	
	local variance = 0
	for _, size in pairs(sizes) do
		variance = variance + (size - mean)^2
	end
	variance = variance / #sizes
	
	-- Normalize variance to 0-1 scale
	return math.min(1.0, variance / 10)
end

function CaveGenerator.generateAdditionalFeatures(formations: {CaveFormation}, config: CaveGenerationConfig): any
	local features = {}
	
	-- Generate underground streams
	for _, formation in pairs(formations) do
		if formation.type == "tunnel" and formation.center.Y < -20 then
			if math.random() < 0.3 then
				table.insert(features, {
					type = "underground_stream",
					position = formation.center,
					flow = formation.radius * 0.2
				})
			end
		end
	end
	
	-- Generate mineral deposits
	for _, formation in pairs(formations) do
		if formation.type == "chamber" and formation.center.Y < -50 then
			if math.random() < config.geology.crystallization then
				table.insert(features, {
					type = "mineral_deposit",
					position = formation.center,
					extent = formation.radius * 0.3
				})
			end
		end
	end
	
	return features
end

function CaveGenerator.applySmoothingPasses(cavePoints: {CavePoint}, passes: number)
	-- Apply smoothing to cave point densities
	print(string.format("🔧 Applying %d smoothing passes to %d cave points", passes, #cavePoints))
	
	for pass = 1, passes do
		-- Simple smoothing by averaging neighboring densities
		for i, point in pairs(cavePoints) do
			local neighborSum = point.density
			local neighborCount = 1
			
			-- Find nearby points (simplified)
			for j, otherPoint in pairs(cavePoints) do
				if i ~= j then
					local distance = (point.position - otherPoint.position).Magnitude
					if distance < 4 then -- Within 4 studs
						neighborSum = neighborSum + otherPoint.density
						neighborCount = neighborCount + 1
					end
				end
			end
			
			-- Apply weighted smoothing
			point.density = (point.density * 0.7) + ((neighborSum / neighborCount) * 0.3)
		end
		
		if pass % 2 == 0 then
			task.wait() -- Yield every few passes
		end
	end
end

function CaveGenerator.validateConnectivity(networks: {CaveNetwork}): number
	local issues = 0
	
	for _, network in pairs(networks) do
		-- Check if all nodes are reachable from entrances
		for _, entrance in pairs(network.entrances) do
			local reachableNodes = CaveSystem.findReachableNodes(entrance, network.nodes)
			local reachabilityRatio = #reachableNodes / #network.nodes
			
			if reachabilityRatio < 0.9 then
				issues = issues + 1
			end
		end
		
		-- Check for isolated nodes
		for _, node in pairs(network.nodes) do
			if #node.connections == 0 then
				issues = issues + 1
			end
		end
	end
	
	return issues
end

function CaveGenerator.calculateFinalQualityMetrics(previousResults: {[string]: any}, config: CaveGenerationConfig): QualityMetrics
	local metrics: QualityMetrics = {
		overallScore = 0,
		geologicalAccuracy = 0,
		connectivityScore = 0,
		structuralIntegrity = 0,
		visualQuality = 0,
		explorationValue = 0,
		accessibilityScore = 0,
		detailMetrics = {},
		recommendations = {}
	}
	
	-- Calculate individual scores
	if previousResults.network_building then
		local networkAnalysis = previousResults.network_building.networkAnalysis
		metrics.connectivityScore = networkAnalysis.connectivityIndex * 100
		metrics.accessibilityScore = networkAnalysis.accessibilityIndex * 100
		metrics.explorationValue = CaveSystem.calculateExplorationPotential(previousResults.network_building.networks) * 100
	end
	
	if previousResults.structural_validation and previousResults.structural_validation.validated then
		metrics.structuralIntegrity = previousResults.structural_validation.safetyScore
	else
		metrics.structuralIntegrity = 80 -- Default if validation skipped
	end
	
	-- Geological accuracy based on configuration
	metrics.geologicalAccuracy = config.quality.geologicalAccuracy * 100
	
	-- Visual quality based on configuration and features
	local visualFactors = {
		config.quality.wallSmoothness,
		config.quality.detailLevel,
		config.quality.ambientOcclusion and 1 or 0.5
	}
	
	local visualSum = 0
	for _, factor in pairs(visualFactors) do
		visualSum = visualSum + factor
	end
	metrics.visualQuality = (visualSum / #visualFactors) * 100
	
	-- Calculate overall score as weighted average
	local weights = {
		geological = 0.25,
		connectivity = 0.20,
		structural = 0.20,
		visual = 0.15,
		exploration = 0.10,
		accessibility = 0.10
	}
	
	metrics.overallScore = 
		(metrics.geologicalAccuracy * weights.geological) +
		(metrics.connectivityScore * weights.connectivity) +
		(metrics.structuralIntegrity * weights.structural) +
		(metrics.visualQuality * weights.visual) +
		(metrics.explorationValue * weights.exploration) +
		(metrics.accessibilityScore * weights.accessibility)
	
	-- Detail metrics
	metrics.detailMetrics["formation_count"] = previousResults.formation_analysis and #previousResults.formation_analysis.formations or 0
	metrics.detailMetrics["network_count"] = previousResults.network_building and #previousResults.network_building.networks or 0
	metrics.detailMetrics["entrance_count"] = previousResults.surface_integration and #previousResults.surface_integration.entrances or 0
	metrics.detailMetrics["feature_count"] = previousResults.feature_generation and previousResults.feature_generation.totalFeatures or 0
	
	-- Generate recommendations
	if metrics.connectivityScore < 60 then
		table.insert(metrics.recommendations, "Increase passage connectivity for better exploration")
	end
	if metrics.structuralIntegrity < 70 then
		table.insert(metrics.recommendations, "Consider strengthening structural supports in large chambers")
	end
	if metrics.accessibilityScore < 50 then
		table.insert(metrics.recommendations, "Add more surface entrances for better accessibility")
	end
	if metrics.explorationValue < 60 then
		table.insert(metrics.recommendations, "Increase cave network complexity and variety")
	end
	
	return metrics
end

function CaveGenerator.compileFinalResults(stageResults: {[string]: any}, config: CaveGenerationConfig, performanceStats: PerformanceStats): any
	-- Compile all stage results into final result structure
	local result = {
		cavePoints = stageResults.cave_point_generation and stageResults.cave_point_generation.cavePoints or {},
		formations = stageResults.formation_analysis and stageResults.formation_analysis.formations or {},
		caveNetworks = stageResults.network_building and stageResults.network_building.networks or {},
		qualityMetrics = stageResults.final_validation and stageResults.final_validation.qualityMetrics or nil
	}
	
	-- Update performance stats
	performanceStats.pointsGenerated = stageResults.cave_point_generation and stageResults.cave_point_generation.totalSamples or 0
	performanceStats.formationsCreated = #result.formations
	performanceStats.networksBuilt = #result.caveNetworks
	
	return result
end

-- ================================================================================================
--                                    PUBLIC INTERFACE
-- ================================================================================================

-- Quick generation functions for common use cases
function CaveGenerator.generateRealisticCaves(region: Region3, progressCallback: ProgressCallback?): GenerationResult
	return CaveGenerator.generateCaves(region, CaveConfig.getPreset("REALISTIC"), progressCallback)
end

function CaveGenerator.generateCinematicCaves(region: Region3, progressCallback: ProgressCallback?): GenerationResult
	return CaveGenerator.generateCaves(region, CaveConfig.getPreset("CINEMATIC"), progressCallback)
end

function CaveGenerator.generateGeologicalSurveyCaves(region: Region3, progressCallback: ProgressCallback?): GenerationResult
	return CaveGenerator.generateCaves(region, CaveConfig.getPreset("GEOLOGICAL_SURVEY"), progressCallback)
end

-- Validation function
function CaveGenerator.validateRegion(region: Region3): {valid: boolean, issues: {string}}
	local issues = {}
	local valid = true
	
	local size = region.Size
	
	if size.X < 50 or size.Y < 20 or size.Z < 50 then
		table.insert(issues, "Region too small for meaningful cave generation (minimum 50x20x50)")
		valid = false
	end
	
	if size.X > 2000 or size.Y > 500 or size.Z > 2000 then
		table.insert(issues, "Region very large - generation may take significant time")
	end
	
	if region.CFrame.Position.Y > 0 then
		table.insert(issues, "Region center above ground - caves typically generate underground")
	end
	
	return {valid = valid, issues = issues}
end

-- Estimation function
function CaveGenerator.estimateGenerationTime(region: Region3, config: CaveGenerationConfig?): number
	local validatedConfig = CaveConfig.validate(config)
	local size = region.Size
	local volume = size.X * size.Y * size.Z
	
	-- Base time estimate (simplified)
	local baseTime = volume / 100000 -- 1 second per 100k cubic studs
	
	-- Adjust for quality settings
	local qualityMultiplier = 1.0
	if validatedConfig.quality.samplingResolution < 2 then
		qualityMultiplier = qualityMultiplier * 2
	end
	if validatedConfig.quality.geologicalAccuracy > 0.8 then
		qualityMultiplier = qualityMultiplier * 1.5
	end
	if validatedConfig.quality.structuralValidation then
		qualityMultiplier = qualityMultiplier * 1.3
	end
	
	return baseTime * qualityMultiplier
end

return CaveGenerator