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
	chunkSize = 256, -- Size of processing chunks (studs) - optimized for performance
	maxGenerationTime = 30.0, -- Target max generation time in seconds
	yieldInterval = 500, -- Yield every N voxels processed - reduced frequency for better performance

	-- Terrain Settings
	terrainResolution = 4, -- Terrain voxel resolution
	materialAir = Enum.Material.Air,
	materialRock = Enum.Material.Rock,

	-- Logging Settings
	logLevel = "INFO", -- "DEBUG", "INFO", "WARNING", "ERROR" - reduced verbosity
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
		minSize = 15, -- studs (increased for larger caves)
		maxSize = 45, -- increased for larger caves
		densityThreshold = 0.15, -- Lower = more chambers (increased for more chamber generation)
		asymmetryFactor = 0.3,
		heightVariation = 0.4
	},

	-- Passages
	passages = {
		enabled = true,
		minWidth = 4, -- increased for better connectivity
		maxWidth = 12, -- increased for larger passages
		curvature = 0.25, -- 0 = straight, 1 = very curved
		pathfindingSteps = 25, -- reduced for performance
		smoothingPasses = 2, -- reduced for performance
		branchProbability = 0.15,
		maxConnections = 3, -- limit connections per chamber
		timeoutPerPassage = 3 -- reduced timeout for faster generation
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

Config.Performance = {
	-- Optimized performance targets for faster generation
	maxGenerationTime = 30, -- Target maximum total generation time in seconds
	targetVoxelsPerSecond = 75000, -- Increased target voxel processing rate
	
	-- Caching settings
	enableCaching = true,
	cacheSize = 2000, -- increased cache size
	
	-- Chunked processing - optimized for better performance
	chunkSize = 256, -- Reduced chunk size for better yielding
	maxChunksPerFrame = 5, -- Reduced for stability
	yieldEveryNChunks = 2, -- Yield more frequently for smoother generation
	
	-- Memory management
	maxMemoryUsage = 6000, -- MB - increased for larger caves
	garbageCollectInterval = 50, -- chunks - more frequent cleanup
	
	-- Threading
	useMultipleThreads = true,
	maxConcurrentOperations = 2, -- Reduced for stability
	threadTimeout = 10, -- seconds per thread
}

-- ================================================================================================
--                                    CAVE PRESETS
-- ================================================================================================

Config.Presets = {
	-- Quick small caves for testing
	small = {
		Core = { chunkSize = 128, maxGenerationTime = 15 },
		Tier1 = {
			mainChambers = { densityThreshold = 0.12, minSize = 10, maxSize = 25 },
			passages = { minWidth = 3, maxWidth = 8, pathfindingSteps = 15 }
		},
		Tier2 = { enabled = false },
		Tier3 = { enabled = false }
	},
	
	-- Medium interconnected cave systems
	medium = {
		Core = { chunkSize = 256, maxGenerationTime = 30 },
		Tier1 = {
			mainChambers = { densityThreshold = 0.08, minSize = 15, maxSize = 45 },
			passages = { minWidth = 4, maxWidth = 12, pathfindingSteps = 25 }
		},
		Tier2 = { enabled = true },
		Tier3 = { enabled = false }
	},
	
	-- Large complex cave networks with all features
	large = {
		Core = { chunkSize = 512, maxGenerationTime = 60 },
		Tier1 = {
			mainChambers = { densityThreshold = 0.06, minSize = 20, maxSize = 60 },
			passages = { minWidth = 6, maxWidth = 16, pathfindingSteps = 35 }
		},
		Tier2 = { enabled = true },
		Tier3 = { enabled = true }
	}
}

-- ================================================================================================
--                                    REGION SIZE CONFIGURATION
-- ================================================================================================

Config.Region = {
	-- Active region configuration (priority: customRegion > activePreset > defaultSize)
	activePreset = nil, -- "TINY", "SMALL", "MEDIUM", "LARGE", "GIGANTIC", etc.
	customRegion = nil, -- {size = Vector3, center = Vector3} - highest priority
	
	-- Default fallback settings
	defaultSize = Vector3.new(100, 50, 100),
	defaultCenter = Vector3.new(0, -25, 0),
	
	-- Region presets
	presets = {
		TINY = {
			size = Vector3.new(30, 20, 30),
			center = Vector3.new(0, -15, 0)
		},
		SMALL = {
			size = Vector3.new(60, 30, 60),
			center = Vector3.new(0, -20, 0)
		},
		MEDIUM = {
			size = Vector3.new(100, 50, 100),
			center = Vector3.new(0, -25, 0)
		},
		LARGE = {
			size = Vector3.new(300, 80, 300),
			center = Vector3.new(0, -40, 0)
		},
		GIGANTIC = {
			size = Vector3.new(1200, 150, 1200),
			center = Vector3.new(0, -80, 0)
		}
	}
}

-- ================================================================================================
--                                    DEBUGGING
-- ================================================================================================

Config.Debug = {
	-- Visualization
	visualizeChunks = true,
	visualizePathfinding = true,
	visualizeNoise = true,

	-- Metrics
	collectMetrics = true,
	printGenerationStats = true,
	saveDebugData = false
}

-- ================================================================================================
--                                    REGION CONFIGURATION UTILITIES
-- ================================================================================================

-- Get the active region configuration based on priority system
function Config.getActiveRegion(): {size: Vector3, center: Vector3}
	-- Priority 1: Custom region (highest priority)
	if Config.Region.customRegion then
		local custom = Config.Region.customRegion
		if custom.size and custom.center then
			print("📍 Using CUSTOM region:", custom.size, "at", custom.center)
			return {
				size = custom.size,
				center = custom.center
			}
		else
			warn("Invalid customRegion configuration - missing size or center")
		end
	end
	
	-- Priority 2: Active preset
	if Config.Region.activePreset then
		local presetName = Config.Region.activePreset
		local preset = Config.Region.presets[presetName]
		if preset then
			print("📍 Using PRESET region:", presetName, preset.size, "at", preset.center)
			return {
				size = preset.size,
				center = preset.center
			}
		else
			warn("Unknown region preset:", presetName)
		end
	end
	
	-- Priority 3: Default fallback
	print("📍 Using DEFAULT region:", Config.Region.defaultSize, "at", Config.Region.defaultCenter)
	return {
		size = Config.Region.defaultSize,
		center = Config.Region.defaultCenter
	}
end

-- Set the active region preset
function Config.setActiveRegionPreset(presetName: string): boolean
	if Config.Region.presets[presetName] then
		Config.Region.activePreset = presetName
		Config.Region.customRegion = nil -- Clear custom region when setting preset
		print("✅ Set active region preset to:", presetName)
		return true
	else
		warn("Unknown region preset:", presetName)
		return false
	end
end

-- Set a custom region
function Config.setCustomRegion(size: Vector3, center: Vector3): ()
	Config.Region.customRegion = {
		size = size,
		center = center
	}
	Config.Region.activePreset = nil -- Clear preset when setting custom region
	print("✅ Set custom region:", size, "at", center)
end

-- Clear region configuration (use defaults)
function Config.clearRegionConfig(): ()
	Config.Region.activePreset = nil
	Config.Region.customRegion = nil
	print("✅ Cleared region configuration - using defaults")
end

-- ================================================================================================
--                                    CONFIGURATION UTILITIES
-- ================================================================================================

-- Apply a preset configuration
function Config.applyPreset(presetName)
	local preset = Config.Presets[presetName]
	if not preset then
		warn("Unknown preset:", presetName)
		return false
	end
	
	print("🎛️ Applying preset configuration:", presetName)
	
	-- Deep merge preset with existing config
	for sectionName, sectionConfig in pairs(preset) do
		if Config[sectionName] then
			for key, value in pairs(sectionConfig) do
				if type(value) == "table" and type(Config[sectionName][key]) == "table" then
					-- Merge sub-tables
					for subKey, subValue in pairs(value) do
						Config[sectionName][key][subKey] = subValue
					end
				else
					Config[sectionName][key] = value
				end
			end
		end
	end
	
	print("✅ Applied preset:", presetName)
	return true
end

-- Get a merged configuration with a preset
function Config.withPreset(presetName)
	local baseConfig = Config
	local preset = Config.Presets[presetName]
	
	if not preset then
		warn("Unknown preset:", presetName)
		return baseConfig
	end
	
	-- Create a deep copy and merge
	local merged = {}
	for k, v in pairs(baseConfig) do
		if type(v) == "table" then
			merged[k] = {}
			for k2, v2 in pairs(v) do
				merged[k][k2] = v2
			end
		else
			merged[k] = v
		end
	end
	
	-- Apply preset overrides
	for sectionName, sectionConfig in pairs(preset) do
		if merged[sectionName] then
			for key, value in pairs(sectionConfig) do
				merged[sectionName][key] = value
			end
		end
	end
	
	return merged
end

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