--!strict

--[[
====================================================================================================
                                         CaveConfig
                      Comprehensive Cave Generation Configuration System
                              Updated: 2025-08-01 (Quality-First Implementation)
====================================================================================================

This module provides comprehensive configuration management for the cave generation system.
It includes quality presets, validation, and advanced configuration options for realistic
cave generation with geological accuracy.

FEATURES:
- Quality presets (Realistic, Cinematic, Geological Survey)
- Comprehensive cave parameter validation
- Geological realism settings
- Advanced noise configuration
- Debug and visualization options
- Performance tuning parameters

====================================================================================================
]]

local CaveConfig = {}

-- ================================================================================================
--                                      TYPE DEFINITIONS
-- ================================================================================================

export type CaveStructureSettings = {
	-- Main Chamber Configuration
	mainChamberFrequency: number?,    -- How often large chambers appear (0.0-1.0)
	mainChamberMinSize: number?,      -- Minimum chamber radius in studs
	mainChamberMaxSize: number?,      -- Maximum chamber radius in studs
	mainChamberHeight: number?,       -- Average chamber height multiplier
	
	-- Connecting Passage Configuration
	passageWidth: number?,            -- Average passage width in studs
	passageWidthVariation: number?,   -- Variation in passage width (0.0-1.0)
	passageCurvature: number?,        -- How winding passages are (0.0-1.0)
	passageSmoothing: number?,        -- Smoothing level for passage walls (0.0-1.0)
	
	-- Branching Tunnel Configuration
	branchingProbability: number?,    -- Chance of tunnel branching (0.0-1.0)
	branchingAngle: number?,          -- Maximum branching angle in degrees
	maxBranchDepth: number?,          -- Maximum recursive branching depth
	deadEndProbability: number?,      -- Chance branches end in dead ends (0.0-1.0)
	
	-- Sub-Chamber Configuration
	subChamberFrequency: number?,     -- Frequency of small pockets (0.0-1.0)
	subChamberSize: number?,          -- Size range for sub-chambers
	hiddenRoomProbability: number?,   -- Chance of hidden chambers (0.0-1.0)
	
	-- Vertical Shaft Configuration
	verticalShaftFrequency: number?,  -- How often vertical connections appear
	shaftMinHeight: number?,          -- Minimum shaft height in studs
	shaftMaxHeight: number?,          -- Maximum shaft height in studs
	chimneyProbability: number?,      -- Chance of chimney-like formations
	
	-- Squeeze Passage Configuration
	squeezePassageFrequency: number?, -- Frequency of tight crawlspaces
	squeezeWidth: number?,            -- Width of squeeze passages in studs
	squeezeLength: number?,           -- Average length of squeeze sections
	
	-- Elevation Change Configuration
	slopeTunnelFrequency: number?,    -- Frequency of sloped passages
	maxSlope: number?,                -- Maximum slope angle in degrees
	ledgeFrequency: number?,          -- Frequency of natural ledges
	naturalRampProbability: number?   -- Chance of natural ramps forming
}

export type GeologicalSettings = {
	-- Rock Formation Settings
	rockHardness: number?,            -- Affects erosion patterns (0.0-1.0)
	stratification: number?,          -- Geological layering strength (0.0-1.0)
	faultLines: number?,              -- Frequency of geological faults
	jointSets: number?,               -- Natural rock joint patterns
	
	-- Erosion Simulation
	waterErosionStrength: number?,    -- How aggressively water erodes rock
	chemicalErosion: number?,         -- Chemical weathering effects
	mechanicalErosion: number?,       -- Physical weathering effects
	erosionTimescale: number?,        -- Simulated erosion duration
	
	-- Structural Integrity
	collapseSimulation: boolean?,     -- Enable collapse simulation
	supportStructures: boolean?,      -- Natural support formations
	ceilingStability: number?,        -- How stable cave ceilings are
	
	-- Speleothem Formation
	stalactiteFrequency: number?,     -- Frequency of stalactites
	stalagmiteFrequency: number?,     -- Frequency of stalagmites
	flowstoneFormation: number?,      -- Flowstone and rimstone formation
	crystallization: number?          -- Crystal formation in chambers
}

export type SurfaceIntegrationSettings = {
	-- Surface Entrance Settings
	entranceFrequency: number?,       -- How many entrances per area
	entranceSize: number?,            -- Size variation of entrances
	entranceBlending: number?,        -- How smoothly entrances blend with terrain
	naturalEntranceOnly: boolean?,    -- Only realistic natural entrances
	
	-- Terrain Integration
	surfaceInfluence: number?,        -- How surface topology affects caves
	drainagePatterns: boolean?,       -- Align caves with surface drainage
	topographicControl: number?,      -- Surface elevation influence on caves
	
	-- Environmental Integration
	vegetationHiding: boolean?,       -- Vegetation concealing entrances
	weatheringEffects: boolean?,      -- Surface weathering simulation
	seasonalChanges: number?          -- Seasonal entrance modifications
}

export type QualitySettings = {
	-- Generation Quality
	samplingResolution: number?,      -- Voxel sampling density (studs)
	noiseOctaves: number?,            -- Noise detail levels
	smoothingPasses: number?,         -- Post-generation smoothing
	detailLevel: number?,             -- Overall detail complexity (0.0-1.0)
	
	-- Realism Settings
	geologicalAccuracy: number?,      -- Geological realism level (0.0-1.0)
	physicalConstraints: boolean?,    -- Enforce physical limitations
	connectivityValidation: boolean?, -- Ensure all areas are reachable
	structuralValidation: boolean?,   -- Check structural soundness
	
	-- Visual Quality
	wallSmoothness: number?,          -- Cave wall smoothness (0.0-1.0)
	ceilingVariation: number?,        -- Ceiling height variation
	floorRoughness: number?,          -- Floor surface roughness
	ambientOcclusion: boolean?,       -- Generate ambient occlusion hints
	
	-- Performance vs Quality
	qualityOverPerformance: boolean?, -- Prioritize quality over speed
	progressiveDetail: boolean?,      -- Progressive detail enhancement
	adaptiveResolution: boolean?      -- Adaptive sampling based on complexity
}

export type DebugSettings = {
	-- Visualization Options
	showCaveNetworks: boolean?,       -- Visualize cave connectivity
	showFlowPaths: boolean?,          -- Show water flow simulation
	showStressFractures: boolean?,    -- Display geological stress
	showErosionPatterns: boolean?,    -- Highlight erosion effects
	
	-- Analysis Modes
	connectivityAnalysis: boolean?,   -- Analyze cave network connectivity
	structuralAnalysis: boolean?,     -- Check structural integrity
	flowAnalysis: boolean?,           -- Water flow analysis
	geologicalAnalysis: boolean?,     -- Geological formation analysis
	
	-- Performance Monitoring
	performanceMetrics: boolean?,     -- Collect performance data
	memoryTracking: boolean?,         -- Track memory usage
	generationProfiling: boolean?,    -- Profile generation stages
	qualityMetrics: boolean?,         -- Measure quality scores
	
	-- Export Options
	exportMeshes: boolean?,           -- Export cave meshes
	exportAnalytics: boolean?,        -- Export analysis data
	exportVisualization: boolean?     -- Export debug visualizations
}

export type CaveGenerationConfig = {
	-- Core Structure Settings
	structure: CaveStructureSettings?,
	
	-- Geological Realism
	geology: GeologicalSettings?,
	
	-- Surface Integration
	surface: SurfaceIntegrationSettings?,
	
	-- Quality Control
	quality: QualitySettings?,
	
	-- Debug and Analysis
	debug: DebugSettings?,
	
	-- Global Settings
	seed: number?,                    -- Random seed for reproducibility
	region: Region3?,                 -- Generation region
	maxDepth: number?,                -- Maximum cave depth below surface
	minDepth: number?,                -- Minimum cave depth
	waterLevel: number?,              -- Global water table level
	temperatureGradient: number?      -- Temperature change with depth
}

-- ================================================================================================
--                                     QUALITY PRESETS
-- ================================================================================================

CaveConfig.Presets = {
	-- Realistic caves prioritizing geological accuracy
	REALISTIC = {
		structure = {
			mainChamberFrequency = 0.15,
			mainChamberMinSize = 8,
			mainChamberMaxSize = 25,
			mainChamberHeight = 1.2,
			passageWidth = 3,
			passageWidthVariation = 0.4,
			passageCurvature = 0.3,
			passageSmoothing = 0.7,
			branchingProbability = 0.25,
			branchingAngle = 45,
			maxBranchDepth = 4,
			deadEndProbability = 0.3,
			subChamberFrequency = 0.1,
			subChamberSize = 4,
			hiddenRoomProbability = 0.05,
			verticalShaftFrequency = 0.08,
			shaftMinHeight = 10,
			shaftMaxHeight = 30,
			chimneyProbability = 0.2,
			squeezePassageFrequency = 0.12,
			squeezeWidth = 1.5,
			squeezeLength = 8,
			slopeTunnelFrequency = 0.2,
			maxSlope = 30,
			ledgeFrequency = 0.15,
			naturalRampProbability = 0.25
		},
		geology = {
			rockHardness = 0.6,
			stratification = 0.7,
			faultLines = 0.3,
			jointSets = 0.5,
			waterErosionStrength = 0.8,
			chemicalErosion = 0.6,
			mechanicalErosion = 0.4,
			erosionTimescale = 0.7,
			collapseSimulation = true,
			supportStructures = true,
			ceilingStability = 0.7,
			stalactiteFrequency = 0.3,
			stalagmiteFrequency = 0.25,
			flowstoneFormation = 0.2,
			crystallization = 0.1
		},
		surface = {
			entranceFrequency = 0.02,
			entranceSize = 0.5,
			entranceBlending = 0.8,
			naturalEntranceOnly = true,
			surfaceInfluence = 0.6,
			drainagePatterns = true,
			topographicControl = 0.7,
			vegetationHiding = true,
			weatheringEffects = true,
			seasonalChanges = 0.1
		},
		quality = {
			samplingResolution = 2.0,
			noiseOctaves = 8,
			smoothingPasses = 3,
			detailLevel = 0.8,
			geologicalAccuracy = 0.9,
			physicalConstraints = true,
			connectivityValidation = true,
			structuralValidation = true,
			wallSmoothness = 0.6,
			ceilingVariation = 0.7,
			floorRoughness = 0.4,
			ambientOcclusion = true,
			qualityOverPerformance = true,
			progressiveDetail = false,
			adaptiveResolution = true
		},
		debug = {
			showCaveNetworks = false,
			showFlowPaths = false,
			showStressFractures = false,
			showErosionPatterns = false,
			connectivityAnalysis = false,
			structuralAnalysis = false,
			flowAnalysis = false,
			geologicalAnalysis = false,
			performanceMetrics = false,
			memoryTracking = false,
			generationProfiling = false,
			qualityMetrics = true,
			exportMeshes = false,
			exportAnalytics = false,
			exportVisualization = false
		}
	},
	
	-- Cinematic caves optimized for visual appeal
	CINEMATIC = {
		structure = {
			mainChamberFrequency = 0.25,
			mainChamberMinSize = 15,
			mainChamberMaxSize = 50,
			mainChamberHeight = 1.8,
			passageWidth = 5,
			passageWidthVariation = 0.6,
			passageCurvature = 0.5,
			passageSmoothing = 0.9,
			branchingProbability = 0.35,
			branchingAngle = 60,
			maxBranchDepth = 6,
			deadEndProbability = 0.2,
			subChamberFrequency = 0.15,
			subChamberSize = 8,
			hiddenRoomProbability = 0.15,
			verticalShaftFrequency = 0.15,
			shaftMinHeight = 15,
			shaftMaxHeight = 60,
			chimneyProbability = 0.3,
			squeezePassageFrequency = 0.08,
			squeezeWidth = 2.0,
			squeezeLength = 5,
			slopeTunnelFrequency = 0.3,
			maxSlope = 25,
			ledgeFrequency = 0.25,
			naturalRampProbability = 0.4
		},
		geology = {
			rockHardness = 0.4,
			stratification = 0.5,
			faultLines = 0.4,
			jointSets = 0.6,
			waterErosionStrength = 0.9,
			chemicalErosion = 0.7,
			mechanicalErosion = 0.3,
			erosionTimescale = 0.9,
			collapseSimulation = false,
			supportStructures = true,
			ceilingStability = 0.9,
			stalactiteFrequency = 0.5,
			stalagmiteFrequency = 0.4,
			flowstoneFormation = 0.4,
			crystallization = 0.3
		},
		surface = {
			entranceFrequency = 0.04,
			entranceSize = 0.8,
			entranceBlending = 0.9,
			naturalEntranceOnly = false,
			surfaceInfluence = 0.4,
			drainagePatterns = false,
			topographicControl = 0.5,
			vegetationHiding = false,
			weatheringEffects = false,
			seasonalChanges = 0.0
		},
		quality = {
			samplingResolution = 1.5,
			noiseOctaves = 10,
			smoothingPasses = 5,
			detailLevel = 1.0,
			geologicalAccuracy = 0.6,
			physicalConstraints = false,
			connectivityValidation = true,
			structuralValidation = false,
			wallSmoothness = 0.9,
			ceilingVariation = 0.8,
			floorRoughness = 0.2,
			ambientOcclusion = true,
			qualityOverPerformance = true,
			progressiveDetail = true,
			adaptiveResolution = true
		},
		debug = {
			showCaveNetworks = false,
			showFlowPaths = false,
			showStressFractures = false,
			showErosionPatterns = false,
			connectivityAnalysis = false,
			structuralAnalysis = false,
			flowAnalysis = false,
			geologicalAnalysis = false,
			performanceMetrics = false,
			memoryTracking = false,
			generationProfiling = false,
			qualityMetrics = true,
			exportMeshes = true,
			exportAnalytics = false,
			exportVisualization = false
		}
	},
	
	-- Geological Survey level accuracy and detail
	GEOLOGICAL_SURVEY = {
		structure = {
			mainChamberFrequency = 0.12,
			mainChamberMinSize = 5,
			mainChamberMaxSize = 30,
			mainChamberHeight = 1.1,
			passageWidth = 2.5,
			passageWidthVariation = 0.3,
			passageCurvature = 0.2,
			passageSmoothing = 0.5,
			branchingProbability = 0.2,
			branchingAngle = 30,
			maxBranchDepth = 3,
			deadEndProbability = 0.4,
			subChamberFrequency = 0.08,
			subChamberSize = 3,
			hiddenRoomProbability = 0.03,
			verticalShaftFrequency = 0.05,
			shaftMinHeight = 8,
			shaftMaxHeight = 25,
			chimneyProbability = 0.15,
			squeezePassageFrequency = 0.15,
			squeezeWidth = 1.2,
			squeezeLength = 12,
			slopeTunnelFrequency = 0.15,
			maxSlope = 20,
			ledgeFrequency = 0.1,
			naturalRampProbability = 0.15
		},
		geology = {
			rockHardness = 0.8,
			stratification = 0.9,
			faultLines = 0.4,
			jointSets = 0.7,
			waterErosionStrength = 0.7,
			chemicalErosion = 0.8,
			mechanicalErosion = 0.5,
			erosionTimescale = 0.5,
			collapseSimulation = true,
			supportStructures = true,
			ceilingStability = 0.6,
			stalactiteFrequency = 0.2,
			stalagmiteFrequency = 0.18,
			flowstoneFormation = 0.15,
			crystallization = 0.05
		},
		surface = {
			entranceFrequency = 0.015,
			entranceSize = 0.3,
			entranceBlending = 0.7,
			naturalEntranceOnly = true,
			surfaceInfluence = 0.8,
			drainagePatterns = true,
			topographicControl = 0.9,
			vegetationHiding = true,
			weatheringEffects = true,
			seasonalChanges = 0.2
		},
		quality = {
			samplingResolution = 1.0,
			noiseOctaves = 12,
			smoothingPasses = 2,
			detailLevel = 1.0,
			geologicalAccuracy = 1.0,
			physicalConstraints = true,
			connectivityValidation = true,
			structuralValidation = true,
			wallSmoothness = 0.4,
			ceilingVariation = 0.6,
			floorRoughness = 0.6,
			ambientOcclusion = true,
			qualityOverPerformance = true,
			progressiveDetail = false,
			adaptiveResolution = true
		},
		debug = {
			showCaveNetworks = true,
			showFlowPaths = true,
			showStressFractures = true,
			showErosionPatterns = true,
			connectivityAnalysis = true,
			structuralAnalysis = true,
			flowAnalysis = true,
			geologicalAnalysis = true,
			performanceMetrics = true,
			memoryTracking = true,
			generationProfiling = true,
			qualityMetrics = true,
			exportMeshes = true,
			exportAnalytics = true,
			exportVisualization = true
		}
	}
}

-- ================================================================================================
--                                 CONFIGURATION VALIDATION
-- ================================================================================================

local function validateRange(value: number?, min: number, max: number, default: number, name: string): number
	if value == nil then return default end
	assert(type(value) == "number", name .. " must be a number")
	assert(value >= min and value <= max, name .. " must be between " .. min .. " and " .. max)
	return value
end

local function validateBool(value: boolean?, default: boolean, name: string): boolean
	if value == nil then return default end
	assert(type(value) == "boolean", name .. " must be a boolean")
	return value
end

local function validateStructureSettings(structure: CaveStructureSettings?): CaveStructureSettings
	local s = structure or {}
	return {
		mainChamberFrequency = validateRange(s.mainChamberFrequency, 0.0, 1.0, 0.15, "mainChamberFrequency"),
		mainChamberMinSize = validateRange(s.mainChamberMinSize, 1, 100, 8, "mainChamberMinSize"),
		mainChamberMaxSize = validateRange(s.mainChamberMaxSize, 5, 200, 25, "mainChamberMaxSize"),
		mainChamberHeight = validateRange(s.mainChamberHeight, 0.5, 5.0, 1.2, "mainChamberHeight"),
		
		passageWidth = validateRange(s.passageWidth, 0.5, 20, 3, "passageWidth"),
		passageWidthVariation = validateRange(s.passageWidthVariation, 0.0, 1.0, 0.4, "passageWidthVariation"),
		passageCurvature = validateRange(s.passageCurvature, 0.0, 1.0, 0.3, "passageCurvature"),
		passageSmoothing = validateRange(s.passageSmoothing, 0.0, 1.0, 0.7, "passageSmoothing"),
		
		branchingProbability = validateRange(s.branchingProbability, 0.0, 1.0, 0.25, "branchingProbability"),
		branchingAngle = validateRange(s.branchingAngle, 0, 90, 45, "branchingAngle"),
		maxBranchDepth = validateRange(s.maxBranchDepth, 1, 10, 4, "maxBranchDepth"),
		deadEndProbability = validateRange(s.deadEndProbability, 0.0, 1.0, 0.3, "deadEndProbability"),
		
		subChamberFrequency = validateRange(s.subChamberFrequency, 0.0, 1.0, 0.1, "subChamberFrequency"),
		subChamberSize = validateRange(s.subChamberSize, 1, 50, 4, "subChamberSize"),
		hiddenRoomProbability = validateRange(s.hiddenRoomProbability, 0.0, 1.0, 0.05, "hiddenRoomProbability"),
		
		verticalShaftFrequency = validateRange(s.verticalShaftFrequency, 0.0, 1.0, 0.08, "verticalShaftFrequency"),
		shaftMinHeight = validateRange(s.shaftMinHeight, 2, 100, 10, "shaftMinHeight"),
		shaftMaxHeight = validateRange(s.shaftMaxHeight, 5, 200, 30, "shaftMaxHeight"),
		chimneyProbability = validateRange(s.chimneyProbability, 0.0, 1.0, 0.2, "chimneyProbability"),
		
		squeezePassageFrequency = validateRange(s.squeezePassageFrequency, 0.0, 1.0, 0.12, "squeezePassageFrequency"),
		squeezeWidth = validateRange(s.squeezeWidth, 0.5, 5.0, 1.5, "squeezeWidth"),
		squeezeLength = validateRange(s.squeezeLength, 2, 50, 8, "squeezeLength"),
		
		slopeTunnelFrequency = validateRange(s.slopeTunnelFrequency, 0.0, 1.0, 0.2, "slopeTunnelFrequency"),
		maxSlope = validateRange(s.maxSlope, 0, 60, 30, "maxSlope"),
		ledgeFrequency = validateRange(s.ledgeFrequency, 0.0, 1.0, 0.15, "ledgeFrequency"),
		naturalRampProbability = validateRange(s.naturalRampProbability, 0.0, 1.0, 0.25, "naturalRampProbability")
	}
end

local function validateGeologicalSettings(geology: GeologicalSettings?): GeologicalSettings
	local g = geology or {}
	return {
		rockHardness = validateRange(g.rockHardness, 0.0, 1.0, 0.6, "rockHardness"),
		stratification = validateRange(g.stratification, 0.0, 1.0, 0.7, "stratification"),
		faultLines = validateRange(g.faultLines, 0.0, 1.0, 0.3, "faultLines"),
		jointSets = validateRange(g.jointSets, 0.0, 1.0, 0.5, "jointSets"),
		
		waterErosionStrength = validateRange(g.waterErosionStrength, 0.0, 1.0, 0.8, "waterErosionStrength"),
		chemicalErosion = validateRange(g.chemicalErosion, 0.0, 1.0, 0.6, "chemicalErosion"),
		mechanicalErosion = validateRange(g.mechanicalErosion, 0.0, 1.0, 0.4, "mechanicalErosion"),
		erosionTimescale = validateRange(g.erosionTimescale, 0.0, 1.0, 0.7, "erosionTimescale"),
		
		collapseSimulation = validateBool(g.collapseSimulation, true, "collapseSimulation"),
		supportStructures = validateBool(g.supportStructures, true, "supportStructures"),
		ceilingStability = validateRange(g.ceilingStability, 0.0, 1.0, 0.7, "ceilingStability"),
		
		stalactiteFrequency = validateRange(g.stalactiteFrequency, 0.0, 1.0, 0.3, "stalactiteFrequency"),
		stalagmiteFrequency = validateRange(g.stalagmiteFrequency, 0.0, 1.0, 0.25, "stalagmiteFrequency"),
		flowstoneFormation = validateRange(g.flowstoneFormation, 0.0, 1.0, 0.2, "flowstoneFormation"),
		crystallization = validateRange(g.crystallization, 0.0, 1.0, 0.1, "crystallization")
	}
end

local function validateSurfaceSettings(surface: SurfaceIntegrationSettings?): SurfaceIntegrationSettings
	local s = surface or {}
	return {
		entranceFrequency = validateRange(s.entranceFrequency, 0.0, 1.0, 0.02, "entranceFrequency"),
		entranceSize = validateRange(s.entranceSize, 0.1, 2.0, 0.5, "entranceSize"),
		entranceBlending = validateRange(s.entranceBlending, 0.0, 1.0, 0.8, "entranceBlending"),
		naturalEntranceOnly = validateBool(s.naturalEntranceOnly, true, "naturalEntranceOnly"),
		
		surfaceInfluence = validateRange(s.surfaceInfluence, 0.0, 1.0, 0.6, "surfaceInfluence"),
		drainagePatterns = validateBool(s.drainagePatterns, true, "drainagePatterns"),
		topographicControl = validateRange(s.topographicControl, 0.0, 1.0, 0.7, "topographicControl"),
		
		vegetationHiding = validateBool(s.vegetationHiding, true, "vegetationHiding"),
		weatheringEffects = validateBool(s.weatheringEffects, true, "weatheringEffects"),
		seasonalChanges = validateRange(s.seasonalChanges, 0.0, 1.0, 0.1, "seasonalChanges")
	}
end

local function validateQualitySettings(quality: QualitySettings?): QualitySettings
	local q = quality or {}
	return {
		samplingResolution = validateRange(q.samplingResolution, 0.1, 10.0, 2.0, "samplingResolution"),
		noiseOctaves = validateRange(q.noiseOctaves, 1, 20, 8, "noiseOctaves"),
		smoothingPasses = validateRange(q.smoothingPasses, 0, 10, 3, "smoothingPasses"),
		detailLevel = validateRange(q.detailLevel, 0.0, 1.0, 0.8, "detailLevel"),
		
		geologicalAccuracy = validateRange(q.geologicalAccuracy, 0.0, 1.0, 0.9, "geologicalAccuracy"),
		physicalConstraints = validateBool(q.physicalConstraints, true, "physicalConstraints"),
		connectivityValidation = validateBool(q.connectivityValidation, true, "connectivityValidation"),
		structuralValidation = validateBool(q.structuralValidation, true, "structuralValidation"),
		
		wallSmoothness = validateRange(q.wallSmoothness, 0.0, 1.0, 0.6, "wallSmoothness"),
		ceilingVariation = validateRange(q.ceilingVariation, 0.0, 1.0, 0.7, "ceilingVariation"),
		floorRoughness = validateRange(q.floorRoughness, 0.0, 1.0, 0.4, "floorRoughness"),
		ambientOcclusion = validateBool(q.ambientOcclusion, true, "ambientOcclusion"),
		
		qualityOverPerformance = validateBool(q.qualityOverPerformance, true, "qualityOverPerformance"),
		progressiveDetail = validateBool(q.progressiveDetail, false, "progressiveDetail"),
		adaptiveResolution = validateBool(q.adaptiveResolution, true, "adaptiveResolution")
	}
end

local function validateDebugSettings(debug: DebugSettings?): DebugSettings
	local d = debug or {}
	return {
		showCaveNetworks = validateBool(d.showCaveNetworks, false, "showCaveNetworks"),
		showFlowPaths = validateBool(d.showFlowPaths, false, "showFlowPaths"),
		showStressFractures = validateBool(d.showStressFractures, false, "showStressFractures"),
		showErosionPatterns = validateBool(d.showErosionPatterns, false, "showErosionPatterns"),
		
		connectivityAnalysis = validateBool(d.connectivityAnalysis, false, "connectivityAnalysis"),
		structuralAnalysis = validateBool(d.structuralAnalysis, false, "structuralAnalysis"),
		flowAnalysis = validateBool(d.flowAnalysis, false, "flowAnalysis"),
		geologicalAnalysis = validateBool(d.geologicalAnalysis, false, "geologicalAnalysis"),
		
		performanceMetrics = validateBool(d.performanceMetrics, false, "performanceMetrics"),
		memoryTracking = validateBool(d.memoryTracking, false, "memoryTracking"),
		generationProfiling = validateBool(d.generationProfiling, false, "generationProfiling"),
		qualityMetrics = validateBool(d.qualityMetrics, true, "qualityMetrics"),
		
		exportMeshes = validateBool(d.exportMeshes, false, "exportMeshes"),
		exportAnalytics = validateBool(d.exportAnalytics, false, "exportAnalytics"),
		exportVisualization = validateBool(d.exportVisualization, false, "exportVisualization")
	}
end

-- ================================================================================================
--                                    PUBLIC INTERFACE
-- ================================================================================================

function CaveConfig.validate(config: CaveGenerationConfig?): CaveGenerationConfig
	if config == nil then
		-- Return realistic preset as default
		return CaveConfig.Presets.REALISTIC
	end
	
	assert(type(config) == "table", "Configuration must be a table")
	
	local validated = {
		structure = validateStructureSettings(config.structure),
		geology = validateGeologicalSettings(config.geology),
		surface = validateSurfaceSettings(config.surface),
		quality = validateQualitySettings(config.quality),
		debug = validateDebugSettings(config.debug),
		
		seed = if config.seed then config.seed else math.random(1, 1000000),
		region = config.region,
		maxDepth = validateRange(config.maxDepth, 10, 1000, 200, "maxDepth"),
		minDepth = validateRange(config.minDepth, 1, 500, 10, "minDepth"),
		waterLevel = validateRange(config.waterLevel, -1000, 0, -50, "waterLevel"),
		temperatureGradient = validateRange(config.temperatureGradient, 0.0, 100.0, 25.0, "temperatureGradient")
	}
	
	-- Validation checks
	assert(validated.maxDepth > validated.minDepth, "maxDepth must be greater than minDepth")
	assert(validated.structure.mainChamberMaxSize > validated.structure.mainChamberMinSize, 
		"mainChamberMaxSize must be greater than mainChamberMinSize")
	assert(validated.structure.shaftMaxHeight > validated.structure.shaftMinHeight,
		"shaftMaxHeight must be greater than shaftMinHeight")
	
	return validated
end

function CaveConfig.getPreset(presetName: string): CaveGenerationConfig
	assert(type(presetName) == "string", "Preset name must be a string")
	
	local preset = CaveConfig.Presets[presetName:upper()]
	assert(preset ~= nil, "Unknown preset: " .. presetName)
	
	return CaveConfig.validate(preset)
end

function CaveConfig.createCustom(basePreset: string?, overrides: CaveGenerationConfig?): CaveGenerationConfig
	local base = if basePreset then CaveConfig.getPreset(basePreset) else CaveConfig.Presets.REALISTIC
	
	if overrides == nil then
		return base
	end
	
	-- Deep merge overrides into base configuration
	local function deepMerge(target: any, source: any): any
		if type(source) ~= "table" then
			return source
		end
		
		if type(target) ~= "table" then
			target = {}
		end
		
		for key, value in pairs(source) do
			target[key] = deepMerge(target[key], value)
		end
		
		return target
	end
	
	local merged = deepMerge(base, overrides)
	return CaveConfig.validate(merged)
end

function CaveConfig.getQualityScore(config: CaveGenerationConfig): number
	local score = 0.0
	local maxScore = 0.0
	
	-- Quality factors and their weights
	local factors = {
		{config.quality.geologicalAccuracy, 0.25, "Geological Accuracy"},
		{config.quality.detailLevel, 0.20, "Detail Level"},
		{config.quality.samplingResolution >= 2.0 and 1.0 or config.quality.samplingResolution / 2.0, 0.15, "Sampling Resolution"},
		{config.quality.noiseOctaves >= 8 and 1.0 or config.quality.noiseOctaves / 8.0, 0.10, "Noise Octaves"},
		{config.quality.wallSmoothness, 0.10, "Wall Smoothness"},
		{config.geology.erosionTimescale, 0.10, "Erosion Simulation"},
		{config.structure.passageSmoothing, 0.05, "Passage Smoothing"},
		{config.surface.entranceBlending, 0.05, "Surface Integration"}
	}
	
	for _, factor in pairs(factors) do
		local value, weight, name = factor[1], factor[2], factor[3]
		score = score + (value * weight)
		maxScore = maxScore + weight
	end
	
	return (score / maxScore) * 100 -- Return as percentage
end

function CaveConfig.describeConfig(config: CaveGenerationConfig): string
	local qualityScore = CaveConfig.getQualityScore(config)
	
	local description = string.format([[
=== Cave Generation Configuration ===
Quality Score: %.1f%%
Sampling Resolution: %.1f studs
Geological Accuracy: %.0f%%
Detail Level: %.0f%%

Structure:
- Main Chambers: %.0f%% frequency, %d-%d studs
- Passage Width: %.1f studs (±%.0f%%)
- Branching: %.0f%% probability, max %d levels
- Vertical Shafts: %.0f%% frequency, %d-%d studs height

Geology:
- Rock Hardness: %.0f%%
- Erosion Strength: %.0f%%
- Speleothem Formation: %.0f%%

Surface Integration:
- Entrance Frequency: %.1f%%
- Surface Influence: %.0f%%
- Natural Entrances Only: %s

Debug Features: %s
=====================================]],
		qualityScore,
		config.quality.samplingResolution,
		config.quality.geologicalAccuracy * 100,
		config.quality.detailLevel * 100,
		
		config.structure.mainChamberFrequency * 100,
		config.structure.mainChamberMinSize,
		config.structure.mainChamberMaxSize,
		config.structure.passageWidth,
		config.structure.passageWidthVariation * 100,
		config.structure.branchingProbability * 100,
		config.structure.maxBranchDepth,
		config.structure.verticalShaftFrequency * 100,
		config.structure.shaftMinHeight,
		config.structure.shaftMaxHeight,
		
		config.geology.rockHardness * 100,
		config.geology.waterErosionStrength * 100,
		config.geology.stalactiteFrequency * 100,
		
		config.surface.entranceFrequency * 100,
		config.surface.surfaceInfluence * 100,
		config.surface.naturalEntranceOnly and "Yes" or "No",
		
		config.debug.connectivityAnalysis and "Enabled" or "Disabled"
	)
	
	return description
end

return CaveConfig