--[[
====================================================================================================
                                    CaveGen Configuration
                        Centralized configuration for cave generation system
====================================================================================================
]]

local Config = {}

-- ================================================================================================
--                                    CORE SETTINGS
-- ================================================================================================

Config.Core = {
	-- Generation Settings
	seed = nil, -- nil = random seed, number = specific seed for reproducible generation
	chunkSize = 526, -- Size of processing chunks (studs)
	maxGenerationTime = 30.0, -- Target max generation time in seconds
	yieldInterval = 100, -- Yield every N voxels processed

	-- Terrain Settings
	terrainResolution = 4, -- Terrain voxel resolution
	materialAir = Enum.Material.Air,
	materialRock = Enum.Material.Rock,

	-- Logging Settings
	logLevel = "DEBUG", -- "DEBUG", "INFO", "WARNING", "ERROR"
	enablePerformanceLogging = true,
	enableDetailedLogging = false
}

-- ================================================================================================
--                                    NOISE SETTINGS
-- ================================================================================================

Config.Noise = {
	-- Primary noise settings for cave structure
	primary = {
		scale = 0.02,
		octaves = 6,
		lacunarity = 2.0,
		persistence = 0.5,
		threshold = 0.3 -- Values above this create air
	},

	-- Secondary noise for chamber detection
	chambers = {
		scale = 0.05,
		octaves = 4,
		lacunarity = 2.2,
		persistence = 0.6,
		jitter = 0.8,
		mode = "F1"
	},

	-- Detail noise for surface roughness
	detail = {
		scale = 0.15,
		octaves = 3,
		lacunarity = 2.5,
		persistence = 0.3,
		strength = 0.1
	}
}

-- ================================================================================================
--                                    TIER 1: FOUNDATION
-- ================================================================================================

Config.Tier1 = {
	enabled = true,

	-- Main Chambers
	mainChambers = {
		enabled = true,
		minSize = 8, -- studs
		maxSize = 24,
		densityThreshold = 0.15, -- Lower = more chambers
		asymmetryFactor = 0.3,
		heightVariation = 0.4
	},

	-- Passages
	passages = {
		enabled = true,
		minWidth = 3,
		maxWidth = 8,
		curvature = 0.25, -- 0 = straight, 1 = very curved
		pathfindingSteps = 50,
		smoothingPasses = 3,
		branchProbability = 0.15
	},

	-- Vertical Shafts
	verticalShafts = {
		enabled = true,
		minHeight = 10,
		maxHeight = 40,
		angleVariation = 15, -- degrees from vertical
		density = 0.05, -- probability per chamber
		radiusVariation = 0.3
	}
}

-- ================================================================================================
--                                    TIER 2: COMPLEXITY
-- ================================================================================================

Config.Tier2 = {
	enabled = true,

	-- Branches
	branches = {
		enabled = true,
		probability = 0.25, -- per passage segment
		minLength = 5,
		maxLength = 15,
		tapering = 0.7, -- width reduction factor
		deadEndChance = 0.3
	},

	-- Sub-Chambers
	subChambers = {
		enabled = true,
		probability = 0.4, -- per main chamber
		sizeRatio = 0.6, -- relative to parent chamber
		distance = 8, -- studs from parent
		connectionWidth = 4
	},

	-- Collapse Rooms
	collapseRooms = {
		enabled = true,
		probability = 0.1, -- per generation area
		minSize = 15,
		maxSize = 35,
		irregularityFactor = 0.5,
		debrisAmount = 0.3
	},

	-- Hidden Pockets
	hiddenPockets = {
		enabled = true,
		density = 0.08,
		minSize = 2,
		maxSize = 6,
		discoveryRadius = 3 -- studs - intersect to discover
	},

	-- Tectonic Intersections
	tectonicIntersections = {
		enabled = true,
		probability = 0.15,
		chaosRadius = 12,
		noiseOffset = 100,
		blendFactor = 0.6
	},

	-- Crustal Overhangs
	crustalOverhangs = {
		enabled = true,
		probability = 0.3, -- per chamber
		overhangDepth = 4,
		thickness = 2,
		supportProbability = 0.7
	},

	-- Tilted Floors
	tiltedFloors = {
		enabled = true,
		probability = 0.4, -- per chamber
		maxTiltAngle = 25, -- degrees
		gradientStrength = 0.3
	},

	-- False Passages & Dead-End Seals
	falsePassages = {
		enabled = true,
		probability = 0.2, -- per branch
		taperLength = 8,
		sealMaterial = Enum.Material.Rock
	},

	deadEndSeals = {
		enabled = false, -- Set to true to seal some passages
		probability = 0.15,
		sealDepth = 3,
		sealMaterial = Enum.Material.Rock
	}
}

-- ================================================================================================
--                                    TIER 3: MICRO-FEATURES
-- ================================================================================================

Config.Tier3 = {
	enabled = true,

	-- Fracture Veins
	fractureVeins = {
		enabled = true,
		density = 0.2,
		minLength = 3,
		maxLength = 12,
		zigzagIntensity = 0.4,
		width = 0.5
	},

	-- Pinch Points
	pinchPoints = {
		enabled = true,
		probability = 0.25, -- per passage
		minWidth = 1.5,
		transitionLength = 4,
		frequency = 0.1 -- along passage
	},

	-- Seam Layers
	seamLayers = {
		enabled = true,
		density = 0.15,
		thickness = 0.3,
		horizontalVariation = 0.2,
		layerSpacing = 3
	},

	-- Shelf Layers
	shelfLayers = {
		enabled = true,
		probability = 0.3, -- per chamber wall
		shelfDepth = 1.5,
		verticalSpacing = 4,
		widthVariation = 0.4
	},

	-- Plate Gaps
	plateGaps = {
		enabled = true,
		density = 0.1,
		minDepth = 5,
		maxDepth = 20,
		width = 0.8,
		verticalBias = 0.8
	},

	-- Pressure Funnels
	pressureFunnels = {
		enabled = true,
		probability = 0.15, -- per chamber
		funnelRatio = 0.6, -- narrowest/widest point
		transitionSmoothness = 0.7
	},

	-- Concretion Domes
	concretionDomes = {
		enabled = true,
		probability = 0.2, -- per chamber ceiling
		radius = 3,
		height = 2,
		smoothness = 0.8
	}
}

-- ================================================================================================
--                                    ENVIRONMENTAL
-- ================================================================================================

Config.Environment = {
	-- Water and Lava
	waterLevel = -50, -- Y coordinate below which water may appear
	lavaLevel = -150, -- Y coordinate below which lava may appear
	waterProbability = 0.3,
	lavaProbability = 0.1,

	-- Lighting
	ambientLighting = 0.2,

	-- Materials
	materials = {
		stalactite = Enum.Material.Rock,
		stalagmite = Enum.Material.Rock,
		water = Enum.Material.Water,
		lava = Enum.Material.Neon -- For lava effect
	}
}

-- ================================================================================================
--                                    CONNECTIVITY
-- ================================================================================================

Config.Connectivity = {
	-- Pathfinding
	pathfinding = {
		algorithm = "AStar", -- "AStar" or "Dijkstra"
		maxIterations = 1000,
		heuristicWeight = 1.2,
		allowDiagonal = true
	},

	-- Network Analysis
	minNetworkSize = 3, -- Minimum chambers for a valid network
	isolationRadius = 50, -- studs - max distance to consider connected
	bridgeProbability = 0.8, -- chance to create bridge between close networks

	-- Quality Control
	ensureConnectivity = true, -- Force all major features to connect
	maxIsolatedFeatures = 2 -- Max number of isolated chambers allowed
}

-- ================================================================================================
--                                    PERFORMANCE
-- ================================================================================================

Performance = {
	-- Relaxed performance targets (<30 seconds instead of <1 second)
	maxGenerationTime = 60, -- Maximum total generation time in seconds
	targetVoxelsPerSecond = 50000, -- Target voxel processing rate

	-- Chunked processing
	chunkSize = 526, -- Voxels per chunk
	maxChunksPerFrame = 10, -- Reduced for stability
	yieldEveryNChunks = 5, -- Yield more frequently

	-- Memory management
	maxMemoryUsage = 4000, -- MB
	garbageCollectInterval = 100, -- chunks

	-- Threading
	useMultipleThreads = true,
	maxConcurrentOperations = 3, -- Reduced
	threadTimeout = 15, -- seconds per thread
}

-- ================================================================================================
--                                    DEBUGGING
-- ================================================================================================

Config.Debug = {
	-- Visualization
	visualizeChunks = true,
	visualizePathfinding = true,
	visualizeNoise = true,

	-- Testing
	generateTestCave = false,
	testCaveSize = Vector3.new(50, 30, 50),
	testCavePosition = Vector3.new(0, -25, 0),

	-- Metrics
	collectMetrics = true,
	printGenerationStats = true,
	saveDebugData = false
}

-- ================================================================================================
--                                    VALIDATION
-- ================================================================================================

-- Validate configuration on load
local function validateConfig()
	-- Ensure required fields exist
	assert(Config.Core, "Core configuration missing")
	assert(Config.Noise, "Noise configuration missing")
	assert(Config.Tier1, "Tier1 configuration missing")

	-- Validate ranges
	assert(Config.Core.chunkSize > 0, "Chunk size must be positive")
	assert(Config.Core.maxGenerationTime > 0, "Max generation time must be positive")
	assert(Config.Noise.primary.threshold >= -1 and Config.Noise.primary.threshold <= 1, "Noise threshold must be between -1 and 1")

	-- Validate Tier settings
	for tierName, tierConfig in pairs({Config.Tier1, Config.Tier2, Config.Tier3}) do
		if tierConfig.enabled == nil then
			tierConfig.enabled = true
		end
	end

	print("✅ Cave generation configuration validated successfully")
end

-- Auto-validate on require
validateConfig()

return Config