--[[
====================================================================================================
                                    Initialize Cave Generation
                      Comprehensive orchestration script for procedural cave generation
====================================================================================================

This script provides a complete API for generating caves using the three-tier generation system:
- Tier 1: Foundation (chambers, passages, vertical shafts)
- Tier 2: Complexity (branches, sub-chambers, collapse rooms, hidden pockets)
- Tier 3: Micro-features (fracture veins, pinch points, seam layers)

API Functions:
- generateCave(region, config, options): Main generation function
- generateQuickCave(position, size): Simple cave with defaults
- generateAdvancedCave(region, customConfig): Full customization
- generateTestCave(): Generate test cave for debugging

====================================================================================================
]]

local InitializeCaveGeneration = {}

-- ================================================================================================
--                                    DEPENDENCIES
-- ================================================================================================

local Core = require(game.ReplicatedStorage.CaveGen.Core)
local Config = require(game.ReplicatedStorage.CaveGen.Config)
local Tier1 = require(game.ReplicatedStorage.CaveGen.Tier1)
local Tier2 = require(game.ReplicatedStorage.CaveGen.Tier2)
local Tier3 = require(game.ReplicatedStorage.CaveGen.Tier3)
local NoiseLib = require(script.Parent.NoiseLib)

-- ================================================================================================
--                                    CONSTANTS & TYPES
-- ================================================================================================

local GENERATION_VERSION = "1.0.0"
local MAX_TOTAL_GENERATION_TIME = 300 -- 5 minutes absolute maximum
local DEFAULT_PROGRESS_INTERVAL = 5 -- seconds between progress reports

export type GenerationOptions = {
	enableTier1: boolean?,
	enableTier2: boolean?,
	enableTier3: boolean?,
	progressCallback: ((progress: number, stage: string, details: string?) -> ())?,
	timeout: number?, -- generation timeout in seconds
	enableDebugVisualization: boolean?,
	enablePerformanceLogging: boolean?,
	yieldInterval: number?, -- override default yield interval
}

export type GenerationResult = {
	success: boolean,
	generationTime: number,
	totalVoxels: number,
	memoryUsed: number,
	features: {
		chambers: number,
		passages: number,
		verticalShafts: number,
		branches: number,
		subChambers: number,
		collapseRooms: number,
		hiddenPockets: number,
		microFeatures: number,
	},
	errorMessage: string?,
	metadata: any
}

-- ================================================================================================
--                                    PRIVATE STATE
-- ================================================================================================

local isGenerating = false
local currentGenerationId = ""
local generationStats = {
	totalGenerations = 0,
	successfulGenerations = 0,
	totalGenerationTime = 0,
	averageGenerationTime = 0
}

-- ================================================================================================
--                                    LOGGING & ERROR HANDLING
-- ================================================================================================

local function log(level: string, message: string, details: any?)
	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s] CaveInit:", timestamp, level)
	
	if details then
		print(prefix, message, details)
	else
		print(prefix, message)
	end
	
	if level == "ERROR" then
		warn(prefix, message)
	end
end

local function handleError(errorMessage: string, context: string?, fallbackAction: (() -> ())?): boolean
	log("ERROR", string.format("Error in %s: %s", context or "generation", errorMessage))
	
	if fallbackAction then
		local success, fallbackResult = pcall(fallbackAction)
		if success then
			log("INFO", "Fallback action executed successfully")
			return true
		else
			log("ERROR", "Fallback action failed: " .. tostring(fallbackResult))
		end
	end
	
	return false
end

-- ================================================================================================
--                                    CONFIGURATION MANAGEMENT
-- ================================================================================================

local function validateConfig(config: any): (boolean, string?)
	if not config then
		return false, "Configuration is nil"
	end
	
	-- Check required sections
	local requiredSections = {"Core", "Noise", "Tier1", "Tier2", "Tier3"}
	for _, section in ipairs(requiredSections) do
		if not config[section] then
			return false, string.format("Missing required section: %s", section)
		end
	end
	
	-- Validate core settings
	if config.Core.chunkSize and config.Core.chunkSize <= 0 then
		return false, "Core.chunkSize must be positive"
	end
	
	if config.Core.maxGenerationTime and config.Core.maxGenerationTime <= 0 then
		return false, "Core.maxGenerationTime must be positive"
	end
	
	-- Validate noise settings
	if config.Noise.primary.threshold < -1 or config.Noise.primary.threshold > 1 then
		return false, "Noise.primary.threshold must be between -1 and 1"
	end
	
	log("DEBUG", "Configuration validation passed")
	return true, nil
end

local function mergeConfigs(baseConfig: any, customConfig: any?): any
	if not customConfig then
		return baseConfig
	end
	
	local merged = {}
	
	-- Deep copy base config
	for key, value in pairs(baseConfig) do
		if type(value) == "table" then
			merged[key] = {}
			for subKey, subValue in pairs(value) do
				merged[key][subKey] = subValue
			end
		else
			merged[key] = value
		end
	end
	
	-- Merge custom config
	for key, value in pairs(customConfig) do
		if type(value) == "table" and merged[key] then
			for subKey, subValue in pairs(value) do
				merged[key][subKey] = subValue
			end
		else
			merged[key] = value
		end
	end
	
	return merged
end

-- ================================================================================================
--                                    PERFORMANCE MONITORING
-- ================================================================================================

local function reportProgress(options: GenerationOptions?, progress: number, stage: string, details: string?)
	if options and options.progressCallback then
		options.progressCallback(progress, stage, details)
	end
	
	log("INFO", string.format("Progress: %d%% - %s", math.floor(progress * 100), stage), details)
end

local function startPerformanceMonitoring(): number
	local startTime = tick()
	collectgarbage("collect") -- Clean up before starting
	log("DEBUG", "Performance monitoring started")
	return startTime
end

local function endPerformanceMonitoring(startTime: number): {generationTime: number, memoryUsed: number}
	local endTime = tick()
	local generationTime = endTime - startTime
	
	local memoryAfter = collectgarbage("count")
	log("INFO", string.format("Generation completed in %.3f seconds", generationTime))
	log("INFO", string.format("Memory usage: %.2f KB", memoryAfter))
	
	-- Update global stats
	generationStats.totalGenerations = generationStats.totalGenerations + 1
	generationStats.totalGenerationTime = generationStats.totalGenerationTime + generationTime
	generationStats.averageGenerationTime = generationStats.totalGenerationTime / generationStats.totalGenerations
	
	return {
		generationTime = generationTime,
		memoryUsed = memoryAfter
	}
end

-- ================================================================================================
--                                    GENERATION ORCHESTRATION
-- ================================================================================================

local function executeWithTimeout(func: () -> any, timeout: number): (boolean, any)
	local startTime = tick()
	local result = nil
	local success = false
	local errorMessage = ""
	
	local co = coroutine.create(function()
		local ok, res = pcall(func)
		success = ok
		if ok then
			result = res
		else
			errorMessage = tostring(res)
		end
	end)
	
	while coroutine.status(co) ~= "dead" do
		local ok, err = coroutine.resume(co)
		if not ok then
			return false, "Coroutine error: " .. tostring(err)
		end
		
		-- Check timeout
		if tick() - startTime > timeout then
			return false, "Generation timeout after " .. timeout .. " seconds"
		end
		
		task.wait() -- Yield to prevent freezing
	end
	
	if success then
		return true, result
	else
		return false, errorMessage
	end
end

local function runGenerationTier(tierFunc: (any, any) -> any, tierName: string, region: Region3, config: any, options: GenerationOptions?): (boolean, any)
	log("INFO", string.format("Starting %s generation", tierName))
	
	local timeout = (options and options.timeout) or config.Core.maxGenerationTime or 60
	local success, result = executeWithTimeout(function()
		return tierFunc(region, config)
	end, timeout)
	
	if success then
		log("INFO", string.format("%s generation completed successfully", tierName))
		return true, result
	else
		log("ERROR", string.format("%s generation failed: %s", tierName, tostring(result)))
		return false, result
	end
end

-- ================================================================================================
--                                    MAIN GENERATION FUNCTION
-- ================================================================================================

function InitializeCaveGeneration.generateCave(region: Region3, customConfig: any?, options: GenerationOptions?): GenerationResult
	-- Prevent concurrent generations
	if isGenerating then
		return {
			success = false,
			generationTime = 0,
			totalVoxels = 0,
			memoryUsed = 0,
			features = {chambers = 0, passages = 0, verticalShafts = 0, branches = 0, subChambers = 0, collapseRooms = 0, hiddenPockets = 0, microFeatures = 0},
			errorMessage = "Cave generation already in progress",
			metadata = {}
		}
	end
	
	isGenerating = true
	currentGenerationId = tostring(tick())
	
	local startTime = startPerformanceMonitoring()
	
	-- Initialize result structure
	local result: GenerationResult = {
		success = false,
		generationTime = 0,
		totalVoxels = 0,
		memoryUsed = 0,
		features = {
			chambers = 0,
			passages = 0,
			verticalShafts = 0,
			branches = 0,
			subChambers = 0,
			collapseRooms = 0,
			hiddenPockets = 0,
			microFeatures = 0
		},
		errorMessage = nil,
		metadata = {
			version = GENERATION_VERSION,
			generationId = currentGenerationId,
			regionSize = region.Size,
			regionPosition = region.CFrame.Position
		}
	}
	
	local success, error = pcall(function()
		log("INFO", "=== STARTING CAVE GENERATION ===")
		reportProgress(options, 0, "Initializing", "Setting up generation environment")
		
		-- Merge and validate configuration
		local config = mergeConfigs(Config, customConfig)
		local configValid, configError = validateConfig(config)
		if not configValid then
			error("Configuration validation failed: " .. tostring(configError))
		end
		
		reportProgress(options, 0.05, "Configuration", "Configuration validated successfully")
		
		-- Initialize Core system
		if not Core.initialize(config) then
			error("Failed to initialize Core system")
		end
		
		reportProgress(options, 0.1, "Core Initialized", "Core system ready")
		
		-- Clear any previous cave data
		Core.clearCaveData()
		
		-- Initialize terrain buffer
		Core.initializeTerrainBuffer(region)
		reportProgress(options, 0.15, "Terrain Buffer", "Terrain buffer initialized")
		
		-- Start performance monitoring
		Core.startPerformanceMonitoring()
		
		-- TIER 1: Foundation Generation
		if (options == nil or options.enableTier1 ~= false) and config.Tier1.enabled then
			reportProgress(options, 0.2, "Tier 1", "Generating foundation features")
			
			local tier1Success, tier1Result = runGenerationTier(Tier1.generate, "Tier 1", region, config, options)
			if tier1Success and tier1Result then
				result.features.chambers = #(tier1Result.chambers or {})
				result.features.passages = #(tier1Result.passages or {})
				result.features.verticalShafts = #(tier1Result.verticalShafts or {})
				reportProgress(options, 0.4, "Tier 1 Complete", string.format("Generated %d chambers, %d passages, %d shafts", 
					result.features.chambers, result.features.passages, result.features.verticalShafts))
			else
				log("WARNING", "Tier 1 generation failed, continuing with fallback")
			end
		else
			reportProgress(options, 0.4, "Tier 1 Skipped", "Tier 1 generation disabled")
		end
		
		-- TIER 2: Complexity Generation
		if (options == nil or options.enableTier2 ~= false) and config.Tier2.enabled then
			reportProgress(options, 0.5, "Tier 2", "Generating complexity features")
			
			local tier2Success, tier2Result = runGenerationTier(Tier2.generate, "Tier 2", region, config, options)
			if tier2Success and tier2Result then
				result.features.branches = tier2Result.branchCount or 0
				result.features.subChambers = tier2Result.subChamberCount or 0
				result.features.collapseRooms = tier2Result.collapseRoomCount or 0
				result.features.hiddenPockets = tier2Result.hiddenPocketCount or 0
				reportProgress(options, 0.7, "Tier 2 Complete", string.format("Generated %d branches, %d sub-chambers", 
					result.features.branches, result.features.subChambers))
			else
				log("WARNING", "Tier 2 generation failed, continuing with available features")
			end
		else
			reportProgress(options, 0.7, "Tier 2 Skipped", "Tier 2 generation disabled")
		end
		
		-- TIER 3: Micro-features Generation
		if (options == nil or options.enableTier3 ~= false) and config.Tier3.enabled then
			reportProgress(options, 0.75, "Tier 3", "Generating micro-features")
			
			local tier3Success, tier3Result = runGenerationTier(Tier3.generate, "Tier 3", region, config, options)
			if tier3Success and tier3Result then
				result.features.microFeatures = tier3Result.featureCount or 0
				reportProgress(options, 0.85, "Tier 3 Complete", string.format("Generated %d micro-features", 
					result.features.microFeatures))
			else
				log("WARNING", "Tier 3 generation failed, continuing with basic features")
			end
		else
			reportProgress(options, 0.85, "Tier 3 Skipped", "Tier 3 generation disabled")
		end
		
		-- Ensure connectivity between features
		reportProgress(options, 0.9, "Connectivity", "Analyzing and ensuring cave connectivity")
		Core.ensureConnectivity()
		
		-- Apply terrain changes
		reportProgress(options, 0.95, "Terrain", "Applying changes to Roblox terrain")
		Core.applyTerrainChanges(region)
		
		-- Finalize performance monitoring
		Core.endPerformanceMonitoring()
		reportProgress(options, 1.0, "Complete", "Cave generation finished successfully")
		
		result.success = true
		generationStats.successfulGenerations = generationStats.successfulGenerations + 1
	end)
	
	-- Finalize result
	local performanceData = endPerformanceMonitoring(startTime)
	result.generationTime = performanceData.generationTime
	result.memoryUsed = performanceData.memoryUsed
	
	-- Get final cave data for metadata
	local caveData = Core.getCaveData()
	result.totalVoxels = caveData.metadata.totalVoxels or 0
	result.metadata.seed = caveData.metadata.seed
	
	if not success then
		result.errorMessage = tostring(error)
		result.success = false
		log("ERROR", "Cave generation failed: " .. tostring(error))
	end
	
	isGenerating = false
	
	log("INFO", "=== CAVE GENERATION COMPLETE ===")
	log("INFO", string.format("Success: %s, Time: %.3f seconds, Features: %d chambers, %d passages", 
		tostring(result.success), result.generationTime, result.features.chambers, result.features.passages))
	
	return result
end

-- ================================================================================================
--                                    CONVENIENCE FUNCTIONS
-- ================================================================================================

function InitializeCaveGeneration.generateQuickCave(position: Vector3, size: Vector3?): GenerationResult
	local caveSize = size or Vector3.new(100, 50, 100)
	local region = Region3.new(position - caveSize/2, position + caveSize/2)
	
	-- Use default configuration optimized for quick generation
	local quickConfig = {
		Core = {
			seed = nil, -- Random seed
			chunkSize = 64, -- Smaller chunks for speed
			maxGenerationTime = 30,
			yieldInterval = 50,
			enablePerformanceLogging = false
		},
		Tier1 = {
			enabled = true,
			mainChambers = {
				enabled = true,
				densityThreshold = 0.2, -- Fewer chambers for speed
			},
			passages = {
				enabled = true,
				maxConnections = 2, -- Simpler connectivity
			},
			verticalShafts = {
				enabled = true,
				density = 0.03 -- Fewer shafts
			}
		},
		Tier2 = {
			enabled = false -- Disable for quick generation
		},
		Tier3 = {
			enabled = false -- Disable for quick generation
		}
	}
	
	local options: GenerationOptions = {
		enableTier1 = true,
		enableTier2 = false,
		enableTier3 = false,
		timeout = 30,
		enablePerformanceLogging = false
	}
	
	log("INFO", "Generating quick cave", {position = position, size = caveSize})
	return InitializeCaveGeneration.generateCave(region, quickConfig, options)
end

function InitializeCaveGeneration.generateAdvancedCave(region: Region3, customConfig: any, progressCallback: ((progress: number, stage: string, details: string?) -> ())?): GenerationResult
	local options: GenerationOptions = {
		enableTier1 = true,
		enableTier2 = true,
		enableTier3 = true,
		progressCallback = progressCallback,
		timeout = 120, -- Extended timeout for complex generation
		enableDebugVisualization = true,
		enablePerformanceLogging = true
	}
	
	log("INFO", "Generating advanced cave with full feature set")
	return InitializeCaveGeneration.generateCave(region, customConfig, options)
end

function InitializeCaveGeneration.generateTestCave(): GenerationResult
	local testPosition = Vector3.new(0, -25, 0)
	local testSize = Vector3.new(50, 30, 50)
	local region = Region3.new(testPosition - testSize/2, testPosition + testSize/2)
	
	-- Test configuration with debug features enabled
	local testConfig = {
		Core = {
			seed = 12345, -- Fixed seed for reproducible testing
			enablePerformanceLogging = true,
			logLevel = "DEBUG"
		},
		Debug = {
			generateTestCave = true,
			collectMetrics = true,
			printGenerationStats = true
		}
	}
	
	local options: GenerationOptions = {
		enableTier1 = true,
		enableTier2 = true,
		enableTier3 = true,
		enableDebugVisualization = true,
		enablePerformanceLogging = true,
		progressCallback = function(progress, stage, details)
			print(string.format("[TEST] %d%% - %s: %s", math.floor(progress * 100), stage, details or ""))
		end
	}
	
	log("INFO", "Generating test cave for debugging and validation")
	return InitializeCaveGeneration.generateCave(region, testConfig, options)
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function InitializeCaveGeneration.isGenerating(): boolean
	return isGenerating
end

function InitializeCaveGeneration.getGenerationStats(): any
	return {
		totalGenerations = generationStats.totalGenerations,
		successfulGenerations = generationStats.successfulGenerations,
		successRate = generationStats.totalGenerations > 0 and 
			generationStats.successfulGenerations / generationStats.totalGenerations or 0,
		averageGenerationTime = generationStats.averageGenerationTime,
		totalGenerationTime = generationStats.totalGenerationTime
	}
end

function InitializeCaveGeneration.cleanup(): ()
	if isGenerating then
		log("WARNING", "Cleanup called during active generation")
		return
	end
	
	-- Clear cave data
	Core.clearCaveData()
	
	-- Force garbage collection
	collectgarbage("collect")
	
	log("INFO", "Cave generation cleanup completed")
end

function InitializeCaveGeneration.getVersion(): string
	return GENERATION_VERSION
end

-- ================================================================================================
--                                    DEBUG & TESTING
-- ================================================================================================

function InitializeCaveGeneration.validateModules(): boolean
	local modules = {
		{name = "Core", module = Core},
		{name = "Config", module = Config},
		{name = "Tier1", module = Tier1},
		{name = "Tier2", module = Tier2},
		{name = "Tier3", module = Tier3},
		{name = "NoiseLib", module = NoiseLib}
	}
	
	for _, moduleInfo in ipairs(modules) do
		if not moduleInfo.module then
			log("ERROR", "Module validation failed: " .. moduleInfo.name .. " is not available")
			return false
		end
	end
	
	log("INFO", "All required modules validated successfully")
	return true
end

-- Auto-validate modules on script load
if not InitializeCaveGeneration.validateModules() then
	warn("InitializeCaveGeneration: Module validation failed - some features may not work")
end

log("INFO", "InitializeCaveGeneration v" .. GENERATION_VERSION .. " loaded successfully")

return InitializeCaveGeneration