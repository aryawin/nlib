--!strict

--[[
====================================================================================================
                                         NoiseLib
                            Enhanced Procedural Noise Library for Cave Generation
                      Updated: 2025-08-01 (Modular Architecture Enhancement)
====================================================================================================

ENHANCED FEATURES v3.0:
- Core noise functions optimized for cave generation quality
- Enhanced multi-layer noise generation for realistic geological structures
- Improved domain warping for complex cave formations
- Advanced noise combination techniques for natural patterns
- Optimized caching and performance monitoring
- Integration with modular cave generation system
- Backward compatibility with existing NoiseLib usage
- Quality-first noise generation with geological accuracy
- Enhanced turbulence and ridge noise for realistic rock formations
- Improved Worley noise for chamber and void generation

ARCHITECTURE:
- Focuses on core noise generation capabilities
- Integrates seamlessly with CaveGenerator, CaveLogic, CaveSystem modules
- Maintains existing API for backward compatibility
- Enhanced for geological realism and cave formation quality

====================================================================================================
]]

local NoiseLib = {}

-- ================================================================================================
--                                      CONSTANTS & TYPES
-- ================================================================================================

-- Mathematical constants
local F2: number = 0.5 * (math.sqrt(3.0) - 1.0)
local G2: number = (3.0 - math.sqrt(3.0)) / 6.0
local F3: number = 1/3
local G3: number = 1/6
local G3_2: number = 2.0 * G3
local G3_3: number = 1.0 - 3.0 * G3
local F4: number = (math.sqrt(5.0) - 1.0) / 4.0
local G4: number = (5.0 - math.sqrt(5.0)) / 20.0

-- Performance constants
local DEFAULT_CACHE_SIZE: number = 10000
local DEFAULT_YIELD_INTERVAL: number = 100
local MEMORY_CLEANUP_THRESHOLD: number = 50000 -- KB

-- Type definitions
export type NoiseSettings = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	scale: number?,
	seed: number?,
	offset: {x: number?, y: number?, z: number?}?
}

export type WarpSettings = {
	octaves: number,
	lacunarity: number,
	persistence: number,
	scale: number,
	strength: number?
}

export type CaveSettings = {
	threshold: number?,
	optimalDepth: number?,
	depthRange: number?,
	tunnelScale: number?,
	chamberScale: number?,
	connectivity: number?,
	waterLevel: number?,
	lavaLevel: number?,
	weightMainTunnels: number?,
	weightChambers: number?,
	weightVerticalShafts: number?,
	scaleVerticality: number?,
	scaleDetail: number?
}

export type ValidatedCaveSettings = {
	threshold: number,
	optimalDepth: number,
	depthRange: number,
	tunnelScale: number,
	chamberScale: number,
	connectivity: number,
	waterLevel: number,
	lavaLevel: number,
	weightMainTunnels: number,
	weightChambers: number,
	weightVerticalShafts: number,
	scaleVerticality: number,
	scaleDetail: number
}

export type CacheConfig = {
	enabled: boolean?,
	maxSize: number?,
	cleanupThreshold: number?,
	fullPrecision: boolean?
}

export type PerformanceConfig = {
	yieldInterval: number?,
	memoryThreshold: number?,
	profilingEnabled: boolean?
}

export type GenerationConfig = {
	cache: CacheConfig?,
	performance: PerformanceConfig?,
	async: boolean?
}

export type ProgressCallback = (progress: number, stage: string, details: string?) -> ()

export type ProfileData = {
	functionName: string,
	executionTime: number,
	memoryUsed: number,
	timestamp: number
}

export type CacheStats = {
	hits: number,
	misses: number,
	size: number,
	maxSize: number
}

export type PerformanceStats = {
	totalExecutions: number,
	averageExecutionTime: number,
	peakMemoryUsage: number,
	cacheStats: CacheStats
}

export type CaveData = {
	isAir: boolean,
	tunnelStrength: number,
	chamberStrength: number,
	roughness: number,
	position: Vector3,
	contents: string,
	size: number,
	isMainTunnel: boolean
}

export type CaveFeature = {
	type: string,
	position: Vector3,
	length: number?,
	thickness: number?,
	radius: number?,
	depth: number?,
	count: number?,
	color: Color3?
}

export type CaveEntrance = {
	position: Vector3,
	cavePosition: Vector3,
	size: number,
	type: string
}

export type FlowPath = {
	source: Vector3,
	path: {Vector3},
	flowRate: number
}

export type CaveSystemData = {
	caves: {CaveData},
	entrances: {CaveEntrance},
	networks: {{CaveData}}
}

export type UndergroundSettings = {
	caves: CaveSettings,
	surface: NoiseSettings
}

export type UndergroundSystem = {
	caves: CaveSystemData,
	waterFlow: {FlowPath},
	features: {CaveFeature},
	entrances: {CaveEntrance},
	stats: {
		totalCaves: number,
		totalEntrances: number,
		totalFeatures: number
	}
}

export type GenerationResult<T> = {
	success: boolean,
	data: T?,
	error: string?,
	performanceStats: PerformanceStats?
}

-- Enhanced NoiseGenerator type with all methods properly typed
export type NoiseGenerator = {
	_perm: {number},
	_seed: number,
	_cache: {[string]: number},
	_cacheStats: CacheStats,
	_performanceStats: PerformanceStats,
	_profiles: {ProfileData},
	_config: GenerationConfig,
	_tempArrays: {any},
	_lastCleanupTime: number,

	-- Core methods
	setSeed: (self: NoiseGenerator, seed: number) -> (),
	simplex2D: (self: NoiseGenerator, x: number, y: number) -> number,
	simplex3D: (self: NoiseGenerator, x: number, y: number, z: number) -> number,
	simplex4D: (self: NoiseGenerator, x: number, y: number, z: number, w: number) -> number,
	perlin3D: (self: NoiseGenerator, x: number, y: number, z: number) -> number,
	worley3D: (self: NoiseGenerator, x: number, y: number, z: number, jitter: number?, mode: string?) -> number,
	FBM: (self: NoiseGenerator, x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number) -> number,
	getFBM: (self: NoiseGenerator, x: number, y: number, z: number, settings: NoiseSettings?) -> number,

	-- Advanced noise methods
	advancedDomainWarp: (self: NoiseGenerator, x: number, y: number, z: number, warpSettings: WarpSettings, sourceSettings: WarpSettings) -> number,
	curl3D: (self: NoiseGenerator, x: number, y: number, z: number, epsilon: number?) -> (number, number, number),
	ridge3D: (self: NoiseGenerator, x: number, y: number, z: number) -> number,
	turbulence3D: (self: NoiseGenerator, x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number) -> number,
	billow: (self: NoiseGenerator, x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number) -> number,
	animatedNoise: (self: NoiseGenerator, x: number, y: number, z: number, time: number, timeScale: number?) -> number,

	-- Generation methods
	generateHeightmap: (self: NoiseGenerator, width: number, height: number, settings: NoiseSettings) -> {{number}},
	generateCaves: (self: NoiseGenerator, x: number, y: number, z: number, settings: {scale: number, threshold: number, jitter: number?}) -> number,

	-- Enhanced cave generation methods
	generateRealisticCaves: (self: NoiseGenerator, x: number, y: number, z: number, settings: ValidatedCaveSettings) -> CaveData,
	generateCaveSystem: (self: NoiseGenerator, region: Region3, settings: ValidatedCaveSettings) -> CaveSystemData,
	generateCaveSystemSafe: (self: NoiseGenerator, region: Region3, settings: CaveSettings) -> GenerationResult<CaveSystemData>,
	generateCaveSystemWithProgress: (self: NoiseGenerator, region: Region3, settings: CaveSettings, progressCallback: ProgressCallback?) -> CaveSystemData,

	-- Cave analysis methods
	getDepthProbability: (self: NoiseGenerator, y: number, optimalDepth: number, range: number) -> number,
	generateCaveFeatures: (self: NoiseGenerator, cave: CaveData, position: Vector3) -> {CaveFeature},
	simulateWaterFlow: (self: NoiseGenerator, caves: {CaveData}, iterations: number?) -> {FlowPath},
	calculateCaveDensityGradient: (self: NoiseGenerator, pos: Vector3, settings: ValidatedCaveSettings, memoCache: {[Vector3]: CaveData}?) -> Vector3,
	generateCaveEntrances: (self: NoiseGenerator, heightmap: {{number}}, caves: {CaveData}) -> {CaveEntrance},
	analyzeCaveNetworks: (self: NoiseGenerator, caves: {CaveData}, settings: ValidatedCaveSettings) -> {{CaveData}},
	findCaveEntrances: (self: NoiseGenerator, caves: {CaveData}) -> {CaveEntrance},
	generateCompleteUnderground: (self: NoiseGenerator, region: Region3, settings: UndergroundSettings, progressCallback: ProgressCallback?) -> UndergroundSystem,

	-- Enhanced utility methods
	normalize: (value: number, newMin: number, newMax: number, oldMin: number?, oldMax: number?) -> number,
	benchmark: (self: NoiseGenerator, iterations: number?) -> {[string]: number},

	-- New enhanced methods
	cleanup: (self: NoiseGenerator) -> (),
	getCachedNoise: (self: NoiseGenerator, key: string, generator: () -> number) -> number,
	profileFunction: <T>(self: NoiseGenerator, name: string, func: () -> T) -> T,
	getPerformanceStats: (self: NoiseGenerator) -> PerformanceStats,
	clearCache: (self: NoiseGenerator) -> (),
	setConfig: (self: NoiseGenerator, config: GenerationConfig) -> (),
	validateMemoryUsage: (self: NoiseGenerator) -> boolean
}

-- ================================================================================================
--                                  VALIDATION & CONFIGURATION
-- ================================================================================================

local function validateNoiseSettings(settings: NoiseSettings?): NoiseSettings
	local s: NoiseSettings = settings or {}
	local octaves: number = s.octaves or 6
	local lacunarity: number = s.lacunarity or 2.0
	local persistence: number = s.persistence or 0.5
	local scale: number = s.scale or 1.0
	local offset = s.offset or {x = 0, y = 0, z = 0}

	return {
		octaves = math.max(1, math.min(20, math.floor(octaves))),
		lacunarity = math.max(0.1, lacunarity),
		persistence = math.max(0, math.min(1, persistence)),
		scale = math.max(0.001, scale),
		seed = s.seed,
		offset = {
			x = offset.x or 0,
			y = offset.y or 0,
			z = offset.z or 0
		}
	}
end

local function validateCaveSettings(settings: CaveSettings?): ValidatedCaveSettings
	local s: CaveSettings = settings or {}

	-- Validate ranges with proper nil checks
	if s.threshold then
		assert(s.threshold >= -1 and s.threshold <= 1, "Threshold must be between -1 and 1")
	end
	if s.optimalDepth then
		assert(s.optimalDepth < 0, "Optimal depth must be below surface (negative)")
	end
	if s.depthRange then
		assert(s.depthRange > 0, "Depth range must be positive")
	end
	if s.connectivity then
		assert(s.connectivity >= 0 and s.connectivity <= 1, "Connectivity must be between 0 and 1")
	end

	return {
		threshold = s.threshold or 0.3,
		optimalDepth = s.optimalDepth or -60,
		depthRange = s.depthRange or 40,
		tunnelScale = math.max(0.001, s.tunnelScale or 0.02),
		chamberScale = math.max(0.001, s.chamberScale or 0.05),
		connectivity = math.max(0, math.min(1, s.connectivity or 0.7)),
		waterLevel = s.waterLevel or -50,
		lavaLevel = s.lavaLevel or -150,
		weightMainTunnels = s.weightMainTunnels or 0.6,
		weightChambers = s.weightChambers or 0.3,
		weightVerticalShafts = s.weightVerticalShafts or 0.1,
		scaleVerticality = s.scaleVerticality or 0.015,
		scaleDetail = s.scaleDetail or 0.2,
	}
end

local function validateGenerationConfig(config: GenerationConfig?): GenerationConfig
	local c: GenerationConfig = config or {}
	local cache: CacheConfig = c.cache or {}
	local performance: PerformanceConfig = c.performance or {}

	return {
		cache = {
			enabled = if cache.enabled ~= nil then cache.enabled else true,
			maxSize = math.max(100, cache.maxSize or DEFAULT_CACHE_SIZE),
			cleanupThreshold = math.max(0.5, math.min(1.0, cache.cleanupThreshold or 0.8)),
			fullPrecision = if cache.fullPrecision ~= nil then cache.fullPrecision else false
		},
		performance = {
			yieldInterval = math.max(10, performance.yieldInterval or DEFAULT_YIELD_INTERVAL),
			memoryThreshold = math.max(1000, performance.memoryThreshold or MEMORY_CLEANUP_THRESHOLD),
			profilingEnabled = if performance.profilingEnabled ~= nil then performance.profilingEnabled else false
		},
		async = if c.async ~= nil then c.async else true
	}
end

-- ================================================================================================
--                                  OPTIMIZED GRADIENT TABLES
-- ================================================================================================

local grad2_x: {number} = {1, -1, 1, -1, 1, -1, 0, 0}
local grad2_y: {number} = {1, 1, -1, -1, 0, 0, 1, -1}

local grad3_x: {number} = {1, -1, 1, -1, 1, -1, 1, -1, 0, 0, 0, 0}
local grad3_y: {number} = {1, 1, -1, -1, 0, 0, 0, 0, 1, -1, 1, -1}
local grad3_z: {number} = {0, 0, 0, 0, 1, 1, -1, -1, 1, 1, -1, -1}

local grad4_x: {number} = {0,0,0,0,0,0,0,0,1,1,1,1,-1,-1,-1,-1,1,1,1,1,-1,-1,-1,-1,1,1,1,1,-1,-1,-1,-1}
local grad4_y: {number} = {1,1,1,1,-1,-1,-1,-1,0,0,0,0,0,0,0,0,1,1,1,1,-1,-1,-1,-1,1,1,1,1,-1,-1,-1,-1}
local grad4_z: {number} = {1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,0,0,0,0,0,0,0,0,1,1,-1,-1,1,1,-1,-1}
local grad4_w: {number} = {1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,0,0,0,0,0,0,0,0}

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

-- private helper for fast cache key generation
local function generateCacheKey(prefix: string, fullPrecision: boolean, ...): string
	local parts: {string} = {prefix}
	local args: {any} = {...}
	for i: number = 1, #args do
		local num: any = args[i]
		local valStr: string
		if fullPrecision then
			valStr = tostring(num)
		else
			-- Using floor(n * 1000) creates an integer-like key that's fast and clusters nearby floats
			valStr = tostring(math.floor(num * 1000))
		end
		parts[#parts + 1] = valStr
	end
	return table.concat(parts, "_")
end

local function fastFloor(x: number): number
	local xi: number = math.floor(x)
	return if x < xi then xi - 1 else xi
end

local function dot2_packed(gi: number, x: number, y: number): number
	return grad2_x[gi] * x + grad2_y[gi] * y
end

local function dot3_packed(gi: number, x: number, y: number, z: number): number
	return grad3_x[gi] * x + grad3_y[gi] * y + grad3_z[gi] * z
end

local function dot4_packed(gi: number, x: number, y: number, z: number, w: number): number
	return grad4_x[gi] * x + grad4_y[gi] * y + grad4_z[gi] * z + grad4_w[gi] * w
end

local function smoothstep(t: number): number
	return t * t * (3.0 - 2.0 * t)
end

local function quintic(t: number): number
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
end

local function lerp(a: number, b: number, t: number): number
	return a + t * (b - a)
end

local function distance3D(x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): number
	local dx: number = x2 - x1
	local dy: number = y2 - y1
	local dz: number = z2 - z1
	return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function normalizeRange(value: number, newMin: number, newMax: number, oldMin: number?, oldMax: number?): number
	local oldMinVal: number = oldMin or -1.0
	local oldMaxVal: number = oldMax or 1.0

	local normalizedValue: number = (value - oldMinVal) / (oldMaxVal - oldMinVal)
	return newMin + normalizedValue * (newMax - newMin)
end

-- Helper function to get Region3 bounds
local function getRegionBounds(region: Region3): (Vector3, Vector3)
	local center: Vector3 = region.CFrame.Position
	local size: Vector3 = region.Size
	local halfSize: Vector3 = size * 0.5

	local minPoint: Vector3 = center - halfSize
	local maxPoint: Vector3 = center + halfSize

	return minPoint, maxPoint
end

-- Enhanced memory monitoring
local function getMemoryUsage(): number
	return gcinfo()
end

-- ================================================================================================
--                                  NOISE GENERATOR CLASS
-- ================================================================================================

local NoiseGenerator = {}
NoiseGenerator.__index = NoiseGenerator

function NoiseGenerator.new(seed: number?, config: GenerationConfig?): NoiseGenerator
	local self: any = setmetatable({}, NoiseGenerator)

	-- Core properties
	self._perm = {} :: {number}
	self._seed = seed or 12345
	self._rng = nil :: Random? -- Will be set by setSeed

	-- Enhanced properties with proper initialization
	self._cache = {} :: {[string]: number}
	self._cacheStats = {
		hits = 0,
		misses = 0,
		size = 0,
		maxSize = DEFAULT_CACHE_SIZE
	} :: CacheStats

	self._performanceStats = {
		totalExecutions = 0,
		averageExecutionTime = 0,
		peakMemoryUsage = 0,
		cacheStats = self._cacheStats
	} :: PerformanceStats

	self._profiles = {} :: {ProfileData}
	self._config = validateGenerationConfig(config)
	self._tempArrays = {} :: {any}
	self._lastCleanupTime = os.clock()

	-- Update cache max size from config
	self._cacheStats.maxSize = self._config.cache.maxSize

	self:setSeed(self._seed)

	return self :: NoiseGenerator
end

-- ================================================================================================
--                                    SEEDING & HASHING
-- ================================================================================================

function NoiseGenerator:setSeed(seed: number): ()
	assert(type(seed) == "number", "Seed must be a number")

	self._seed = seed
	self._rng = Random.new(seed) -- Create the deterministic random object here

	-- Clear cache when seed changes
	self:clearCache()

	for i: number = 1, 256 do
		self._perm[i] = i - 1
	end

	-- Shuffle the permutation table using the deterministic generator
	for i: number = 256, 2, -1 do
		local j: number = self._rng:NextInteger(1, i)
		self._perm[i], self._perm[j] = self._perm[j], self._perm[i]
	end

end

local function hash(perm: {number}, i: number): number
	local index: number = (bit32.band(i, 255) + 1)
	return perm[index] or 0
end

local function gradIndex2(perm: {number}, i: number): number
	return (hash(perm, i) % 8) + 1
end

local function gradIndex3(perm: {number}, i: number): number
	return (hash(perm, i) % 12) + 1
end

local function gradIndex4(perm: {number}, i: number): number
	return (hash(perm, i) % 32) + 1
end

-- ================================================================================================
--                                 ENHANCED UTILITY METHODS
-- ================================================================================================

function NoiseGenerator:cleanup(): ()
	-- Clear temporary arrays with nil check
	if self._tempArrays then
		for i: number = 1, #self._tempArrays do
			self._tempArrays[i] = nil
		end
		table.clear(self._tempArrays)
	end

	-- Clear old profiles (keep only last 1000)
	if #self._profiles > 1000 then
		local newProfiles: {ProfileData} = {}
		local startIndex: number = math.max(1, #self._profiles - 999)
		for i: number = startIndex, #self._profiles do
			local profile: ProfileData? = self._profiles[i]
			if profile then
				newProfiles[#newProfiles + 1] = profile
			end
		end
		self._profiles = newProfiles
	end

	-- Force garbage collection if memory usage is high
	local currentMemory: number = getMemoryUsage()
	if currentMemory > self._config.performance.memoryThreshold then
		gcinfo()
		print("🧹 NoiseLib: Performed garbage collection. Memory:", currentMemory, "KB")
	end

	self._lastCleanupTime = os.clock()
end

function NoiseGenerator:validateMemoryUsage(): boolean
	local currentMemory: number = getMemoryUsage()
	self._performanceStats.peakMemoryUsage = math.max(self._performanceStats.peakMemoryUsage, currentMemory)

	-- Automatic cleanup if threshold exceeded
	if currentMemory > self._config.performance.memoryThreshold then
		local timeSinceLastCleanup: number = os.clock() - self._lastCleanupTime
		if timeSinceLastCleanup > 5 then -- Minimum 5 seconds between cleanups
			self:cleanup()
			return false
		end
	end

	return true
end

function NoiseGenerator:clearCache(): ()
	table.clear(self._cache)
	self._cacheStats.size = 0
	self._cacheStats.hits = 0
	self._cacheStats.misses = 0
end

function NoiseGenerator:setConfig(config: GenerationConfig): ()
	self._config = validateGenerationConfig(config)
	self._cacheStats.maxSize = self._config.cache.maxSize

	-- Clear cache if disabled
	if not self._config.cache.enabled then
		self:clearCache()
	end
end

function NoiseGenerator:getCachedNoise(key: string, generator: () -> number): number
	if not self._config.cache.enabled then
		return generator()
	end

	local cachedValue: number? = self._cache[key]
	if cachedValue then
		self._cacheStats.hits += 1
		return cachedValue
	end

	self._cacheStats.misses += 1
	local value: number = generator()

	-- Add to cache if there's space
	if self._cacheStats.size < self._cacheStats.maxSize then
		self._cache[key] = value
		self._cacheStats.size += 1
	elseif self._cacheStats.size >= self._cacheStats.maxSize * self._config.cache.cleanupThreshold then
		-- IMPLEMENTED: Optimized Cache Eviction Policy
		-- Clean up cache by randomly evicting a percentage of entries without rebuilding the table.
		local keysToRemoveFrom: {string} = {}
		for k: string, _: number in pairs(self._cache) do
			keysToRemoveFrom[#keysToRemoveFrom + 1] = k
		end

		local keepCount: number = math.floor(self._cacheStats.maxSize * 0.5) -- Keep 50%
		local evictCount: number = math.max(0, self._cacheStats.size - keepCount)

		for i: number = 1, evictCount do
			local randomIndex: number = self._rng:NextInteger(1, #keysToRemoveFrom)
			local keyToRemove: string = keysToRemoveFrom[randomIndex]

			self._cache[keyToRemove] = nil
			table.remove(keysToRemoveFrom, randomIndex)
		end

		self._cacheStats.size = keepCount

		-- Add the new entry after making space
		self._cache[key] = value
		self._cacheStats.size += 1
	end

	return value
end

function NoiseGenerator:profileFunction<T>(name: string, func: () -> T): T
	if not self._config.performance.profilingEnabled then
		return func()
	end

	local startTime: number = os.clock()
	local startMemory: number = getMemoryUsage()

	local result: T = func()

	local endTime: number = os.clock()
	local endMemory: number = getMemoryUsage()

	local profile: ProfileData = {
		functionName = name,
		executionTime = (endTime - startTime) * 1000, -- Convert to milliseconds
		memoryUsed = endMemory - startMemory,
		timestamp = endTime
	}

	self._profiles[#self._profiles + 1] = profile

	-- Update performance stats
	self._performanceStats.totalExecutions += 1
	local totalTime: number = 0
	for _, p: ProfileData in pairs(self._profiles) do
		totalTime += p.executionTime
	end
	self._performanceStats.averageExecutionTime = totalTime / #self._profiles

	return result
end

function NoiseGenerator:getPerformanceStats(): PerformanceStats
	return {
		totalExecutions = self._performanceStats.totalExecutions,
		averageExecutionTime = self._performanceStats.averageExecutionTime,
		peakMemoryUsage = self._performanceStats.peakMemoryUsage,
		cacheStats = {
			hits = self._cacheStats.hits,
			misses = self._cacheStats.misses,
			size = self._cacheStats.size,
			maxSize = self._cacheStats.maxSize
		}
	}
end

-- ================================================================================================
--                            ENHANCED CORE NOISE FUNCTIONS
-- ================================================================================================

function NoiseGenerator:simplex2D(x: number, y: number): number
	assert(type(x) == "number" and type(y) == "number", "Coordinates must be numbers")

	return self:profileFunction("simplex2D", function(): number
		local cacheKey: string = generateCacheKey("s2d", self._config.cache.fullPrecision, x, y)
		return self:getCachedNoise(cacheKey, function(): number
			local n0: number, n1: number, n2: number

			local s: number = (x + y) * F2
			local i: number = fastFloor(x + s)
			local j: number = fastFloor(y + s)

			local t: number = (i + j) * G2
			local x0: number = x - (i - t)
			local y0: number = y - (j - t)

			local i1: number, j1: number
			if x0 > y0 then
				i1, j1 = 1, 0
			else
				i1, j1 = 0, 1
			end

			local x1: number = x0 - i1 + G2
			local y1: number = y0 - j1 + G2
			local x2: number = x0 - 1.0 + 2.0 * G2
			local y2: number = y0 - 1.0 + 2.0 * G2

			local ii: number = fastFloor(i) -- Ensure integer for hash
			local jj: number = fastFloor(j)
			local gi0: number = gradIndex2(self._perm, ii + hash(self._perm, jj))
			local gi1: number = gradIndex2(self._perm, ii + i1 + hash(self._perm, jj + j1))
			local gi2: number = gradIndex2(self._perm, ii + 1 + hash(self._perm, jj + 1))

			local t0: number = 0.5 - x0*x0 - y0*y0
			n0 = if t0 < 0 then 0.0 else (t0 * t0) * (t0 * t0) * dot2_packed(gi0, x0, y0)

			local t1: number = 0.5 - x1*x1 - y1*y1
			n1 = if t1 < 0 then 0.0 else (t1 * t1) * (t1 * t1) * dot2_packed(gi1, x1, y1)

			local t2: number = 0.5 - x2*x2 - y2*y2
			n2 = if t2 < 0 then 0.0 else (t2 * t2) * (t2 * t2) * dot2_packed(gi2, x2, y2)

			local result: number = 70.0 * (n0 + n1 + n2)
			return math.max(-1, math.min(1, result))
		end)
	end)
end

function NoiseGenerator:simplex3D(x: number, y: number, z: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")

	return self:profileFunction("simplex3D", function(): number
		-- Memory validation
		self:validateMemoryUsage()

		local cacheKey: string = generateCacheKey("s3d", self._config.cache.fullPrecision, x, y, z)
		return self:getCachedNoise(cacheKey, function(): number
			local s: number = (x + y + z) * F3
			local i: number = fastFloor(x + s)
			local j: number = fastFloor(y + s)
			local k: number = fastFloor(z + s)

			local t: number = (i + j + k) * G3
			local x0: number = x - (i - t)
			local y0: number = y - (j - t)
			local z0: number = z - (k - t)

			local i1: number, j1: number, k1: number, i2: number, j2: number, k2: number
			if x0 >= y0 then
				if y0 >= z0 then
					i1, j1, k1, i2, j2, k2 = 1, 0, 0, 1, 1, 0
				elseif x0 >= z0 then
					i1, j1, k1, i2, j2, k2 = 1, 0, 0, 1, 0, 1
				else
					i1, j1, k1, i2, j2, k2 = 0, 0, 1, 1, 0, 1
				end
			else
				if y0 < z0 then
					i1, j1, k1, i2, j2, k2 = 0, 0, 1, 0, 1, 1
				elseif x0 < z0 then
					i1, j1, k1, i2, j2, k2 = 0, 1, 0, 0, 1, 1
				else
					i1, j1, k1, i2, j2, k2 = 0, 1, 0, 1, 1, 0
				end
			end

			local x1: number = x0 - i1 + G3
			local y1: number = y0 - j1 + G3
			local z1: number = z0 - k1 + G3
			local x2: number = x0 - i2 + G3_2
			local y2: number = y0 - j2 + G3_2
			local z2: number = z0 - k2 + G3_2
			local x3: number = x0 + G3_3
			local y3: number = y0 + G3_3
			local z3: number = z0 + G3_3

			local ii: number = fastFloor(i)
			local jj: number = fastFloor(j)
			local kk: number = fastFloor(k)
			local gi0: number = gradIndex3(self._perm, ii + hash(self._perm, jj + hash(self._perm, kk)))
			local gi1: number = gradIndex3(self._perm, ii + i1 + hash(self._perm, jj + j1 + hash(self._perm, kk + k1)))
			local gi2: number = gradIndex3(self._perm, ii + i2 + hash(self._perm, jj + j2 + hash(self._perm, kk + k2)))
			local gi3: number = gradIndex3(self._perm, ii + 1 + hash(self._perm, jj + 1 + hash(self._perm, kk + 1)))

			local n0: number, n1: number, n2: number, n3: number = 0, 0, 0, 0

			local t0: number = 0.6 - x0*x0 - y0*y0 - z0*z0
			if t0 > 0 then
				t0 = t0 * t0
				n0 = t0 * t0 * dot3_packed(gi0, x0, y0, z0)
			end

			local t1: number = 0.6 - x1*x1 - y1*y1 - z1*z1
			if t1 > 0 then
				t1 = t1 * t1
				n1 = t1 * t1 * dot3_packed(gi1, x1, y1, z1)
			end

			local t2: number = 0.6 - x2*x2 - y2*y2 - z2*z2
			if t2 > 0 then
				t2 = t2 * t2
				n2 = t2 * t2 * dot3_packed(gi2, x2, y2, z2)
			end

			local t3: number = 0.6 - x3*x3 - y3*y3 - z3*z3
			if t3 > 0 then
				t3 = t3 * t3
				n3 = t3 * t3 * dot3_packed(gi3, x3, y3, z3)
			end

			local result: number = 32.0 * (n0 + n1 + n2 + n3)
			return math.max(-1, math.min(1, result))
		end)
	end)
end

function NoiseGenerator:simplex4D(x: number, y: number, z: number, w: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number" and type(w) == "number", "Coordinates must be numbers")

	return self:profileFunction("simplex4D", function(): number
		local cacheKey: string = generateCacheKey("s4d", self._config.cache.fullPrecision, x, y, z, w)
		return self:getCachedNoise(cacheKey, function(): number
			-- Skew the input space to determine which simplex cell we're in
			local s: number = (x + y + z + w) * F4
			local i: number = fastFloor(x + s)
			local j: number = fastFloor(y + s)
			local k: number = fastFloor(z + s)
			local l: number = fastFloor(w + s)

			-- Unskew the cell origin back to (x,y,z,w) space
			local t: number = (i + j + k + l) * G4
			local x0: number = x - (i - t)
			local y0: number = y - (j - t)
			local z0: number = z - (k - t)
			local w0: number = w - (l - t)

			-- Sort the cell coordinates to determine the simplex traversal order
			local c = {
				{v=x0, o=1}, {v=y0, o=2}, {v=z0, o=3}, {v=w0, o=4}
			}
			table.sort(c, function(a, b) return a.v > b.v end)

			-- The simplex corners are offsets from the cell origin
			local i1,j1,k1,l1 = 0,0,0,0
			local i2,j2,k2,l2 = 0,0,0,0
			local i3,j3,k3,l3 = 0,0,0,0

			local co1, co2, co3 = c[1].o, c[2].o, c[3].o

			if co1 == 1 then i1=1 else if co1 == 2 then j1=1 else if co1 == 3 then k1=1 else l1=1 end end end
			if co2 == 1 then i2=1 else if co2 == 2 then j2=1 else if co2 == 3 then k2=1 else l2=1 end end end
			if co3 == 1 then i3=1 else if co3 == 2 then j3=1 else if co3 == 3 then k3=1 else l3=1 end end end

			i2, j2, k2, l2 = i1+i2, j1+j2, k1+k2, l1+l2
			i3, j3, k3, l3 = i2+i3, j2+j3, k2+k3, l2+l3

			-- Calculate the (x,y,z,w) coordinates of the simplex corners
			local x1: number, y1: number, z1: number, w1: number = x0 - i1 + G4,     y0 - j1 + G4,     z0 - k1 + G4,     w0 - l1 + G4
			local x2: number, y2: number, z2: number, w2: number = x0 - i2 + 2*G4,   y0 - j2 + 2*G4,   z0 - k2 + 2*G4,   w0 - l2 + 2*G4
			local x3: number, y3: number, z3: number, w3: number = x0 - i3 + 3*G4,   y0 - j3 + 3*G4,   z0 - k3 + 3*G4,   w0 - l3 + 3*G4
			local x4: number, y4: number, z4: number, w4: number = x0 - 1 + 4*G4,    y0 - 1 + 4*G4,    z0 - 1 + 4*G4,    w0 - 1 + 4*G4

			-- Hash to get gradient vectors for each corner
			local ii, jj, kk, ll = fastFloor(i), fastFloor(j), fastFloor(k), fastFloor(l)
			local gi0 = gradIndex4(self._perm, ii + hash(self._perm, jj + hash(self._perm, kk + hash(self._perm, ll))))
			local gi1 = gradIndex4(self._perm, ii+i1 + hash(self._perm, jj+j1 + hash(self._perm, kk+k1 + hash(self._perm, ll+l1))))
			local gi2 = gradIndex4(self._perm, ii+i2 + hash(self._perm, jj+j2 + hash(self._perm, kk+k2 + hash(self._perm, ll+l2))))
			local gi3 = gradIndex4(self._perm, ii+i3 + hash(self._perm, jj+j3 + hash(self._perm, kk+k3 + hash(self._perm, ll+l3))))
			local gi4 = gradIndex4(self._perm, ii+1 + hash(self._perm, jj+1 + hash(self._perm, kk+1 + hash(self._perm, ll+1))))

			-- Calculate the contribution from each corner
			local n0, n1, n2, n3, n4 = 0,0,0,0,0

			local t0 = 0.6 - x0*x0 - y0*y0 - z0*z0 - w0*w0
			if t0 > 0 then n0 = (t0*t0) * (t0*t0) * dot4_packed(gi0, x0, y0, z0, w0) end

			local t1 = 0.6 - x1*x1 - y1*y1 - z1*z1 - w1*w1
			if t1 > 0 then n1 = (t1*t1) * (t1*t1) * dot4_packed(gi1, x1, y1, z1, w1) end

			local t2 = 0.6 - x2*x2 - y2*y2 - z2*z2 - w2*w2
			if t2 > 0 then n2 = (t2*t2) * (t2*t2) * dot4_packed(gi2, x2, y2, z2, w2) end

			local t3 = 0.6 - x3*x3 - y3*y3 - z3*z3 - w3*w3
			if t3 > 0 then n3 = (t3*t3) * (t3*t3) * dot4_packed(gi3, x3, y3, z3, w3) end

			local t4 = 0.6 - x4*x4 - y4*y4 - z4*z4 - w4*w4
			if t4 > 0 then n4 = (t4*t4) * (t4*t4) * dot4_packed(gi4, x4, y4, z4, w4) end

			local result: number = 27.0 * (n0 + n1 + n2 + n3 + n4)
			return math.max(-1, math.min(1, result))
		end)
	end)
end

function NoiseGenerator:perlin3D(x: number, y: number, z: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")

	return self:profileFunction("perlin3D", function(): number
		local cacheKey: string = generateCacheKey("p3d", self._config.cache.fullPrecision, x, y, z)
		return self:getCachedNoise(cacheKey, function(): number
			local X: number = fastFloor(x)
			local Y: number = fastFloor(y)
			local Z: number = fastFloor(z)

			x = x - fastFloor(x)
			y = y - fastFloor(y)
			z = z - fastFloor(z)

			local u: number = quintic(x)
			local v: number = quintic(y)
			local w: number = quintic(z)

			local h1 = hash(self._perm, X)
			local h2 = hash(self._perm, X + 1)

			local h11 = hash(self._perm, h1 + Y)
			local h12 = hash(self._perm, h1 + Y + 1)
			local h21 = hash(self._perm, h2 + Y)
			local h22 = hash(self._perm, h2 + Y + 1)

			local grad111 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h11 + Z)), x, y, z)
			local grad112 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h11 + Z + 1)), x, y, z-1)
			local grad121 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h12 + Z)), x, y-1, z)
			local grad122 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h12 + Z + 1)), x, y-1, z-1)

			local grad211 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h21 + Z)), x-1, y, z)
			local grad212 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h21 + Z + 1)), x-1, y, z-1)
			local grad221 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h22 + Z)), x-1, y-1, z)
			local grad222 = dot3_packed(gradIndex3(self._perm, hash(self._perm, h22 + Z + 1)), x-1, y-1, z-1)

			local lerp_z1 = lerp(v, lerp(u, grad111, grad211), lerp(u, grad121, grad221))
			local lerp_z2 = lerp(v, lerp(u, grad112, grad212), lerp(u, grad122, grad222))

			local result = lerp(w, lerp_z1, lerp_z2)

			return math.max(-1, math.min(1, result))
		end)
	end)
end

function NoiseGenerator:worley3D(x: number, y: number, z: number, jitter: number?, mode: string?): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	local jitterVal: number = jitter or 1.0
	local modeVal: string = mode or "F1"
	assert(jitterVal >= 0 and jitterVal <= 2, "Jitter must be between 0 and 2")
	assert(modeVal == "F1" or modeVal == "F2" or modeVal == "F2-F1", "Worley mode must be 'F1', 'F2', or 'F2-F1'")

	local modeId: number = if modeVal == "F1" then 1 elseif modeVal == "F2" then 2 else 3

	return self:profileFunction("worley3D", function(): number
		local cacheKey: string = generateCacheKey("w3d", self._config.cache.fullPrecision, x, y, z, jitterVal, modeId)

		return self:getCachedNoise(cacheKey, function(): number
			local xint: number = math.floor(x)
			local yint: number = math.floor(y)
			local zint: number = math.floor(z)

			local minDist1: number = math.huge
			local minDist2: number = math.huge

			for xi: number = -1, 1 do
				for yi: number = -1, 1 do
					for zi: number = -1, 1 do
						local cellX: number = xint + xi
						local cellY: number = yint + yi
						local cellZ: number = zint + zi

						local pointHash: number = hash(self._perm, cellX + hash(self._perm, cellY + hash(self._perm, cellZ)))
						local pointX: number = cellX + (pointHash % 1000) / 1000.0 * jitterVal
						local pointY: number = cellY + ((pointHash * 7) % 1000) / 1000.0 * jitterVal
						local pointZ: number = cellZ + ((pointHash * 13) % 1000) / 1000.0 * jitterVal

						local dist: number = distance3D(x, y, z, pointX, pointY, pointZ)

						if dist < minDist1 then
							minDist2 = minDist1
							minDist1 = dist
						elseif dist < minDist2 then
							minDist2 = dist
						end
					end
				end
			end

			local finalValue: number
			if modeVal == "F1" then
				finalValue = minDist1
			elseif modeVal == "F2" then
				finalValue = minDist2
			else -- "F2-F1"
				finalValue = minDist2 - minDist1
			end

			return normalizeRange(finalValue, -1, 1, 0, math.sqrt(3))
		end)
	end)
end


-- ================================================================================================
--                               ENHANCED FRACTAL & ADVANCED NOISE
-- ================================================================================================

function NoiseGenerator:FBM(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")

	return self:profileFunction("FBM", function(): number
		local validOctaves: number = math.max(1, math.min(20, math.floor(octaves)))
		local validLacunarity: number = math.max(0.1, lacunarity)
		local validPersistence: number = math.max(0, math.min(1, persistence))

		local cacheKey: string = generateCacheKey("fbm", self._config.cache.fullPrecision, x, y, z, validOctaves, validLacunarity, validPersistence)
		return self:getCachedNoise(cacheKey, function(): number
			local value: number = 0.0
			local amplitude: number = 1.0
			local frequency: number = 1.0
			local maxValue: number = 0.0

			for i: number = 1, validOctaves do
				value = value + self:simplex3D(x * frequency, y * frequency, z * frequency) * amplitude
				maxValue = maxValue + amplitude
				amplitude = amplitude * validPersistence
				frequency = frequency * validLacunarity

				-- Yield periodically for large octave counts
				if i % self._config.performance.yieldInterval == 0 then
					task.wait()
				end
			end

			return value / maxValue
		end)
	end)
end

function NoiseGenerator:getFBM(x: number, y: number, z: number, settings: NoiseSettings?): number
	local s: NoiseSettings = validateNoiseSettings(settings)
	local octaves: number = s.octaves or 6
	local lacunarity: number = s.lacunarity or 2.0
	local persistence: number = s.persistence or 0.5
	local scale: number = s.scale or 1.0
	local offset = s.offset or {x = 0, y = 0, z = 0}
	local offsetX: number = offset.x or 0
	local offsetY: number = offset.y or 0
	local offsetZ: number = offset.z or 0

	if s.seed then
		self:setSeed(s.seed)
	end

	return self:FBM(
		(x + offsetX) * scale,
		(y + offsetY) * scale,
		(z + offsetZ) * scale,
		octaves, lacunarity, persistence
	)
end

function NoiseGenerator:advancedDomainWarp(x: number, y: number, z: number, warpSettings: WarpSettings, sourceSettings: WarpSettings): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(warpSettings) == "table", "Warp settings must be a table")
	assert(type(sourceSettings) == "table", "Source settings must be a table")

	return self:profileFunction("advancedDomainWarp", function(): number
		local wOctaves: number = math.max(1, math.min(20, math.floor(warpSettings.octaves)))
		local wLacunarity: number = math.max(0.1, warpSettings.lacunarity)
		local wPersistence: number = math.max(0, math.min(1, warpSettings.persistence))
		local wScale: number = math.max(0.001, warpSettings.scale)
		local strength: number = warpSettings.strength or 0.1

		local sOctaves: number = math.max(1, math.min(20, math.floor(sourceSettings.octaves)))
		local sLacunarity: number = math.max(0.1, sourceSettings.lacunarity)
		local sPersistence: number = math.max(0, math.min(1, sourceSettings.persistence))
		local sScale: number = math.max(0.001, sourceSettings.scale)

		local q_x: number = self:FBM(x * wScale, y * wScale, z * wScale, wOctaves, wLacunarity, wPersistence)
		local q_y: number = self:FBM((x + 5.2) * wScale, (y + 1.3) * wScale, (z + 8.7) * wScale, wOctaves, wLacunarity, wPersistence)
		local q_z: number = self:FBM((x + 3.7) * wScale, (y + 9.1) * wScale, (z + 2.8) * wScale, wOctaves, wLacunarity, wPersistence)

		local r_x: number = self:FBM((x + 4.0 * q_x) * wScale, (y + 4.0 * q_y) * wScale, (z + 4.0 * q_z) * wScale, wOctaves, wLacunarity, wPersistence)
		local r_y: number = self:FBM((x + 4.0 * q_x + 1.7) * wScale, (y + 4.0 * q_y + 9.2) * wScale, (z + 4.0 * q_z + 2.3) * wScale, wOctaves, wLacunarity, wPersistence)
		local r_z: number = self:FBM((x + 4.0 * q_x + 8.3) * wScale, (y + 4.0 * q_y + 2.8) * wScale, (z + 4.0 * q_z + 9.7) * wScale, wOctaves, wLacunarity, wPersistence)

		local warped_x: number = x + strength * r_x
		local warped_y: number = y + strength * r_y
		local warped_z: number = z + strength * r_z

		return self:FBM(warped_x * sScale, warped_y * sScale, warped_z * sScale, sOctaves, sLacunarity, sPersistence)
	end)
end

function NoiseGenerator:curl3D(x: number, y: number, z: number, epsilon: number?): (number, number, number)
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	local eps: number = epsilon or 0.01
	assert(eps > 0, "Epsilon must be positive")

	return self:profileFunction("curl3D", function(): (number, number, number)
		local n1: number = self:simplex3D(x, y + eps, z)
		local n2: number = self:simplex3D(x, y - eps, z)
		local n3: number = self:simplex3D(x, y, z + eps)
		local n4: number = self:simplex3D(x, y, z - eps)
		local n5: number = self:simplex3D(x + eps, y, z)
		local n6: number = self:simplex3D(x - eps, y, z)

		local curl_x: number = (n1 - n2) / (2 * eps) - (n3 - n4) / (2 * eps)
		local curl_y: number = (n3 - n4) / (2 * eps) - (n5 - n6) / (2 * eps)
		local curl_z: number = (n5 - n6) / (2 * eps) - (n1 - n2) / (2 * eps)

		return curl_x, curl_y, curl_z
	end)
end

function NoiseGenerator:ridge3D(x: number, y: number, z: number): number
	return self:profileFunction("ridge3D", function(): number
		return 1.0 - math.abs(self:simplex3D(x, y, z))
	end)
end

function NoiseGenerator:turbulence3D(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	return self:profileFunction("turbulence3D", function(): number
		local validOctaves: number = math.max(1, math.min(20, math.floor(octaves)))
		local validLacunarity: number = math.max(0.1, lacunarity)
		local validPersistence: number = math.max(0, math.min(1, persistence))

		local value: number = 0.0
		local amplitude: number = 1.0
		local frequency: number = 1.0
		local maxValue: number = 0.0

		for i: number = 1, validOctaves do
			value = value + math.abs(self:simplex3D(x * frequency, y * frequency, z * frequency)) * amplitude
			maxValue = maxValue + amplitude
			amplitude = amplitude * validPersistence
			frequency = frequency * validLacunarity
		end

		return value / maxValue
	end)
end

function NoiseGenerator:billow(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	return self:profileFunction("billow", function(): number
		return math.abs(self:FBM(x, y, z, octaves, lacunarity, persistence))
	end)
end

function NoiseGenerator:animatedNoise(x: number, y: number, z: number, time: number, timeScale: number?): number
	local scale: number = timeScale or 1.0
	return self:profileFunction("animatedNoise", function(): number
		return self:simplex4D(x, y, z, time * scale)
	end)
end

-- ================================================================================================
--                                ENHANCED CAVE GENERATION INTEGRATION
-- ================================================================================================

-- Enhanced cave generation methods for integration with modular system
function NoiseGenerator:generateGeologicalNoise(x: number, y: number, z: number, geologicalLayer: any): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(geologicalLayer) == "table", "Geological layer must be a table")
	
	return self:profileFunction("generateGeologicalNoise", function(): number
		-- Layer 1: Base structure influenced by rock hardness
		local baseNoise = self:simplex3D(x * 0.02, y * 0.01, z * 0.02)
		baseNoise = baseNoise * (1 - geologicalLayer.hardness)
		
		-- Layer 2: Joint and fracture patterns
		local jointNoise = self:worley3D(x * 0.05, y * 0.05, z * 0.05, 0.6, "F2-F1")
		jointNoise = jointNoise * geologicalLayer.jointDensity
		
		-- Layer 3: Stratification effects (horizontal layering)
		local stratNoise = self:simplex3D(x * 0.01, y * 0.1, z * 0.01) * 0.3
		
		-- Layer 4: Porosity influence
		local porosityNoise = self:ridge3D(x * 0.08, y * 0.08, z * 0.08)
		porosityNoise = porosityNoise * geologicalLayer.porosity
		
		-- Combine layers with geological weighting
		local combinedNoise = (baseNoise * 0.4) + 
			(jointNoise * 0.3) + 
			(stratNoise * 0.2) + 
			(porosityNoise * 0.1)
		
		return math.max(-1, math.min(1, combinedNoise))
	end)
end

function NoiseGenerator:generateCaveFormationNoise(x: number, y: number, z: number, formationType: string): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(formationType) == "string", "Formation type must be a string")
	
	return self:profileFunction("generateCaveFormationNoise", function(): number
		if formationType == "chamber" then
			-- Large, rounded chambers using Worley noise
			local chamberNoise = self:worley3D(x * 0.03, y * 0.03, z * 0.03, 0.8, "F1")
			return 1.0 - chamberNoise -- Invert for cave spaces
			
		elseif formationType == "tunnel" then
			-- Elongated tunnels using ridge noise
			local tunnelNoise = self:ridge3D(x * 0.04, y * 0.02, z * 0.04)
			local direction = self:simplex3D(x * 0.01, y * 0.005, z * 0.01)
			return tunnelNoise * (0.7 + direction * 0.3)
			
		elseif formationType == "vertical_shaft" then
			-- Vertical shafts using cylindrical noise
			local radialDistance = math.sqrt((x % 50)^2 + (z % 50)^2)
			local shaftNoise = self:simplex3D(x * 0.05, y * 0.02, z * 0.05)
			local cylindrical = math.max(0, 1 - radialDistance / 8) -- 8 stud radius
			return shaftNoise * cylindrical
			
		elseif formationType == "squeeze_passage" then
			-- Narrow squeeze passages
			local squeezeNoise = self:turbulence3D(x * 0.08, y * 0.08, z * 0.08, 4, 2.0, 0.5)
			return squeezeNoise * 0.6 -- Smaller amplitude for tighter spaces
			
		else
			-- Default: general cave noise
			return self:simplex3D(x * 0.03, y * 0.02, z * 0.03)
		end
	end)
end

function NoiseGenerator:generateErosionPattern(x: number, y: number, z: number, waterVelocity: Vector3, rockHardness: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(typeof(waterVelocity) == "Vector3", "Water velocity must be a Vector3")
	assert(type(rockHardness) == "number", "Rock hardness must be a number")
	
	return self:profileFunction("generateErosionPattern", function(): number
		local velocity = waterVelocity.Magnitude
		
		-- Flow-aligned erosion pattern
		local flowDirection = waterVelocity.Unit
		local flowX = x + flowDirection.X * 10
		local flowY = y + flowDirection.Y * 10
		local flowZ = z + flowDirection.Z * 10
		
		-- Primary erosion pattern following flow
		local erosionNoise = self:simplex3D(flowX * 0.05, flowY * 0.05, flowZ * 0.05)
		
		-- Secondary turbulence for realistic erosion
		local turbulenceNoise = self:turbulence3D(x * 0.1, y * 0.1, z * 0.1, 3, 2.0, 0.6)
		
		-- Chemical erosion component (less directional)
		local chemicalNoise = self:worley3D(x * 0.02, y * 0.02, z * 0.02, 0.5, "F1")
		
		-- Combine based on rock properties and flow
		local erosionStrength = velocity * (1 - rockHardness)
		local combinedErosion = (erosionNoise * 0.6) + (turbulenceNoise * 0.3) + (chemicalNoise * 0.1)
		
		return combinedErosion * erosionStrength
	end)
end

function NoiseGenerator:generateSpeleothemPattern(x: number, y: number, z: number, humidity: number, age: number): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(humidity) == "number", "Humidity must be a number")
	assert(type(age) == "number", "Age must be a number")
	
	return self:profileFunction("generateSpeleothemPattern", function(): number
		-- Stalactite/stalagmite formation pattern
		local formationNoise = self:ridge3D(x * 0.1, y * 0.05, z * 0.1)
		
		-- Drip pattern influence
		local dripNoise = self:simplex3D(x * 0.2, y * 0.3, z * 0.2)
		
		-- Flowstone pattern
		local flowstoneNoise = self:billow(x * 0.06, y * 0.06, z * 0.06, 4, 2.0, 0.5)
		
		-- Age and humidity influence
		local environmentalFactor = humidity * (age * 0.5 + 0.5)
		
		local combinedPattern = (formationNoise * 0.5) + (dripNoise * 0.3) + (flowstoneNoise * 0.2)
		return combinedPattern * environmentalFactor
	end)
end

function NoiseGenerator:generateCaveQualityNoise(x: number, y: number, z: number, qualitySettings: any): {[string]: number}
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(qualitySettings) == "table", "Quality settings must be a table")
	
	return self:profileFunction("generateCaveQualityNoise", function(): {[string]: number}
		local results = {}
		
		-- Wall smoothness noise
		if qualitySettings.wallSmoothness > 0 then
			results.wallSmoothing = self:billow(x * 0.15, y * 0.15, z * 0.15, 3, 2.0, 0.4)
			results.wallSmoothing = results.wallSmoothing * qualitySettings.wallSmoothness
		end
		
		-- Ceiling variation
		if qualitySettings.ceilingVariation > 0 then
			results.ceilingHeight = self:simplex3D(x * 0.08, y * 0.05, z * 0.08)
			results.ceilingHeight = results.ceilingHeight * qualitySettings.ceilingVariation
		end
		
		-- Floor roughness
		if qualitySettings.floorRoughness > 0 then
			results.floorTexture = self:turbulence3D(x * 0.2, y * 0.1, z * 0.2, 4, 2.0, 0.6)
			results.floorTexture = results.floorTexture * qualitySettings.floorRoughness
		end
		
		-- Detail enhancement
		if qualitySettings.detailLevel > 0 then
			results.microDetail = self:ridge3D(x * 0.3, y * 0.3, z * 0.3)
			results.microDetail = results.microDetail * qualitySettings.detailLevel * 0.1
		end
		
		-- Ambient occlusion hints
		if qualitySettings.ambientOcclusion then
			results.occlusionHint = self:worley3D(x * 0.06, y * 0.06, z * 0.06, 0.4, "F2")
			results.occlusionHint = math.max(0, 1 - results.occlusionHint) -- Invert for occlusion
		end
		
		return results
	end)
end

-- Enhanced domain warping specifically for cave generation
function NoiseGenerator:generateCaveWarpedNoise(
	x: number, 
	y: number, 
	z: number, 
	primarySettings: NoiseSettings,
	warpSettings: WarpSettings,
	geologicalInfluence: number?
): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	
	return self:profileFunction("generateCaveWarpedNoise", function(): number
		local geoInfluence = geologicalInfluence or 0.5
		
		-- First level warp (geological structure)
		local warp1X = self:simplex3D(x * 0.01, y * 0.01, z * 0.01) * geoInfluence
		local warp1Y = self:simplex3D(x * 0.01 + 100, y * 0.01, z * 0.01) * geoInfluence
		local warp1Z = self:simplex3D(x * 0.01, y * 0.01, z * 0.01 + 100) * geoInfluence
		
		-- Second level warp (formation structure)
		local warp2X = self:simplex3D((x + warp1X) * 0.05, (y + warp1Y) * 0.05, (z + warp1Z) * 0.05) * 0.3
		local warp2Y = self:simplex3D((x + warp1X) * 0.05 + 200, (y + warp1Y) * 0.05, (z + warp1Z) * 0.05) * 0.3
		local warp2Z = self:simplex3D((x + warp1X) * 0.05, (y + warp1Y) * 0.05, (z + warp1Z) * 0.05 + 200) * 0.3
		
		-- Final warped coordinates
		local finalX = x + warp1X + warp2X
		local finalY = y + warp1Y + warp2Y
		local finalZ = z + warp1Z + warp2Z
		
		-- Generate primary cave noise with warped coordinates
		return self:getFBM(finalX, finalY, finalZ, primarySettings)
	end)
end

-- Multi-octave cave generation with quality enhancements
function NoiseGenerator:generateQualityCaveNoise(
	x: number, 
	y: number, 
	z: number, 
	baseSettings: NoiseSettings,
	qualityEnhancement: number?
): number
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	
	return self:profileFunction("generateQualityCaveNoise", function(): number
		local quality = qualityEnhancement or 0.8
		
		-- Base cave structure
		local baseCave = self:getFBM(x, y, z, baseSettings)
		
		-- Quality enhancements
		if quality > 0.5 then
			-- Add geological realism
			local geoPattern = self:ridge3D(x * 0.03, y * 0.01, z * 0.03) * 0.2
			baseCave = baseCave + (geoPattern * quality)
			
			-- Add structural detail
			local structureDetail = self:turbulence3D(x * 0.1, y * 0.05, z * 0.1, 3, 2.0, 0.5) * 0.1
			baseCave = baseCave + (structureDetail * quality)
		end
		
		if quality > 0.7 then
			-- Add micro-variations for realism
			local microVar = self:simplex3D(x * 0.5, y * 0.5, z * 0.5) * 0.05
			baseCave = baseCave + (microVar * (quality - 0.7) * 2)
		end
		
		return math.max(-1, math.min(1, baseCave))
	end)
end

-- ================================================================================================
--                               INTEGRATION HELPER FUNCTIONS
-- ================================================================================================

-- Helper to generate multiple noise layers efficiently
function NoiseGenerator:generateNoiseLayers(x: number, y: number, z: number, layerConfigs: {any}): {[string]: number}
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(layerConfigs) == "table", "Layer configs must be a table")
	
	return self:profileFunction("generateNoiseLayers", function(): {[string]: number}
		local results: {[string]: number} = {}
		
		for layerName, config in pairs(layerConfigs) do
			local noiseType = config.type or "simplex3D"
			local scale = config.scale or 1.0
			local amplitude = config.amplitude or 1.0
			
			local layerValue = 0
			if noiseType == "simplex3D" then
				layerValue = self:simplex3D(x * scale, y * scale, z * scale)
			elseif noiseType == "worley3D" then
				layerValue = self:worley3D(x * scale, y * scale, z * scale, config.jitter or 1.0, config.mode or "F1")
			elseif noiseType == "ridge3D" then
				layerValue = self:ridge3D(x * scale, y * scale, z * scale)
			elseif noiseType == "turbulence3D" then
				layerValue = self:turbulence3D(x * scale, y * scale, z * scale, 
					config.octaves or 4, config.lacunarity or 2.0, config.persistence or 0.5)
			elseif noiseType == "FBM" then
				layerValue = self:FBM(x * scale, y * scale, z * scale,
					config.octaves or 6, config.lacunarity or 2.0, config.persistence or 0.5)
			end
			
			results[layerName] = layerValue * amplitude
		end
		
		return results
	end)
end

-- Quality assessment for generated noise
function NoiseGenerator:assessNoiseQuality(noiseValues: {number}, targetDistribution: string?): number
	assert(type(noiseValues) == "table", "Noise values must be a table")
	
	return self:profileFunction("assessNoiseQuality", function(): number
		if #noiseValues == 0 then return 0 end
		
		local target = targetDistribution or "normal"
		
		-- Calculate statistics
		local sum = 0
		local min, max = math.huge, -math.huge
		
		for _, value in pairs(noiseValues) do
			sum = sum + value
			min = math.min(min, value)
			max = math.max(max, value)
		end
		
		local mean = sum / #noiseValues
		local range = max - min
		
		-- Calculate variance
		local variance = 0
		for _, value in pairs(noiseValues) do
			variance = variance + (value - mean)^2
		end
		variance = variance / #noiseValues
		local stdDev = math.sqrt(variance)
		
		-- Quality score based on target distribution
		local qualityScore = 1.0
		
		if target == "normal" then
			-- Prefer values near 0 with good spread
			local meanPenalty = math.abs(mean) * 0.5
			local rangePenalty = math.max(0, 1.8 - range) * 0.3 -- Want range close to 2
			qualityScore = math.max(0, 1 - meanPenalty - rangePenalty)
		elseif target == "uniform" then
			-- Prefer even distribution across range
			local uniformity = 1 - (stdDev / (range / 2)) -- Normalized std dev
			qualityScore = math.max(0, uniformity)
		end
		
		return qualityScore
	end)
end

function NoiseGenerator:getDepthProbability(y: number, optimalDepth: number, range: number): number
	assert(type(y) == "number", "Y coordinate must be a number")
	assert(type(optimalDepth) == "number", "Optimal depth must be a number")
	assert(type(range) == "number", "Range must be a number")

	local distance: number = math.abs(y - optimalDepth)
	local probability: number = math.exp(-(distance * distance) / (2 * range * range))

	-- Surface caves are rare, deep caves are impossible
	if y > -10 then
		probability = probability * 0.1
	end
	if y < -200 then
		probability = probability * 0.05
	end

	return probability
end

function NoiseGenerator:generateRealisticCaves(x: number, y: number, z: number, settings: ValidatedCaveSettings): CaveData
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Coordinates must be numbers")
	assert(type(settings) == "table", "Settings must be a table")

	return self:profileFunction("generateRealisticCaves", function(): CaveData
		local tunnelScale: number = settings.tunnelScale
		local chamberScale: number = settings.chamberScale

		-- Layer 1: Main tunnel structure using 3D Simplex
		local mainTunnels: number = self:simplex3D(x * tunnelScale, y * settings.scaleVerticality, z * tunnelScale)

		-- Layer 2: Secondary passages using Worley noise
		local chambers: number = self:worley3D(x * chamberScale, y * chamberScale, z * chamberScale, 0.8, "F1")

		-- Layer 3: Vertical shafts and connections
		local verticalShafts: number = self:simplex3D(x * 0.01, y * 0.08, z * 0.01)

		-- Layer 4: Small details and roughness
		local details: number = self:simplex3D(x * settings.scaleDetail, y * settings.scaleDetail, z * settings.scaleDetail)

		-- Combine layers with configurable weighting
		local caveStructure: number = (mainTunnels * settings.weightMainTunnels)
			+ (chambers * settings.weightChambers)
			+ (verticalShafts * settings.weightVerticalShafts)
			+ (details * 0.1) -- Detail weight is kept small and constant

		-- Apply depth-based probability
		local depthFactor: number = self:getDepthProbability(y, settings.optimalDepth, settings.depthRange)
		caveStructure = caveStructure * depthFactor

		-- Determine cave contents based on depth using deterministic RNG
		local waterLevel: number = settings.waterLevel
		local lavaLevel: number = settings.lavaLevel
		local contents: string = "air"

		if y < lavaLevel and self._rng:NextNumber() < 0.3 then
			contents = "lava"
		elseif y < waterLevel and self._rng:NextNumber() < 0.6 then
			contents = "water"
		end

		return {
			isAir = caveStructure > settings.threshold,
			tunnelStrength = math.abs(mainTunnels),
			chamberStrength = 1.0 - chambers,
			roughness = math.abs(details),
			position = Vector3.new(x, y, z),
			contents = contents,
			size = math.abs(caveStructure),
			isMainTunnel = math.abs(mainTunnels) > 0.7
		}
	end)
end

-- ================================================================================================
--                                 ENHANCED ERROR HANDLING & SAFE GENERATION
-- ================================================================================================

function NoiseGenerator:generateCaveSystemSafe(region: Region3, settings: CaveSettings): GenerationResult<CaveSystemData>
	local startTime: number = os.clock()
	local startMemory: number = getMemoryUsage()

	local success: boolean, result: any = pcall(function(): CaveSystemData
		local validatedSettings: ValidatedCaveSettings = validateCaveSettings(settings)
		return self:generateCaveSystem(region, validatedSettings)
	end)

	local endTime: number = os.clock()
	local endMemory: number = getMemoryUsage()

	local performanceStats: PerformanceStats = {
		totalExecutions = 1,
		averageExecutionTime = (endTime - startTime) * 1000,
		peakMemoryUsage = endMemory,
		cacheStats = self:getPerformanceStats().cacheStats
	}

	if success then
		return {
			success = true,
			data = result :: CaveSystemData,
			error = nil,
			performanceStats = performanceStats
		}
	else
		warn("🚨 Cave generation failed:", result)
		return {
			success = false,
			data = nil,
			error = "Cave generation failed: " .. tostring(result),
			performanceStats = performanceStats
		}
	end
end

function NoiseGenerator:generateCaveSystemWithProgress(region: Region3, settings: CaveSettings, progressCallback: ProgressCallback?): CaveSystemData
	assert(typeof(region) == "Region3", "Region must be a Region3")
	assert(type(settings) == "table", "Settings must be a table")

	local callback: ProgressCallback = progressCallback or function(_: number, _: string, _: string?) end
	local validatedSettings: ValidatedCaveSettings = validateCaveSettings(settings)

	return self:profileFunction("generateCaveSystemWithProgress", function(): CaveSystemData
		local caves: {CaveData} = {}
		local step: number = 2  -- Sampling resolution

		local minPoint: Vector3, maxPoint: Vector3 = getRegionBounds(region)
		local totalVoxels: number = ((maxPoint.X - minPoint.X) / step) * ((maxPoint.Y - minPoint.Y) / step) * ((maxPoint.Z - minPoint.Z) / step)
		local processedVoxels: number = 0

		callback(0, "Starting cave generation", "Initializing parameters...")
		print("🕳️ Generating cave system for region size:", region.Size)

		local x: number = minPoint.X
		while x <= maxPoint.X do
			local y: number = minPoint.Y
			while y <= maxPoint.Y do
				local z: number = minPoint.Z
				while z <= maxPoint.Z do
					local cave: CaveData = self:generateRealisticCaves(x, y, z, validatedSettings)

					if cave.isAir then
						caves[#caves + 1] = cave
					end

					processedVoxels += 1
					z = z + step
				end
				y = y + step
			end

			-- Progress reporting and yielding
			local progress: number = processedVoxels / totalVoxels
			callback(progress * 0.7, "Generating caves", string.format("Processed %d/%d voxels", processedVoxels, math.floor(totalVoxels)))

			-- Yield periodically to prevent timeout
			if (x - minPoint.X) % (self._config.performance.yieldInterval * step) == 0 then
				task.wait()
				self:validateMemoryUsage()
			end

			x = x + step
		end

		callback(0.7, "Analyzing cave networks", "Finding connected cave systems...")
		local entrances: {CaveEntrance} = self:findCaveEntrances(caves)

		callback(0.85, "Building cave networks", "Connecting related caves...")
		local networks: {{CaveData}} = self:analyzeCaveNetworks(caves, validatedSettings)

		callback(1.0, "Cave generation complete", string.format("Generated %d caves, %d entrances, %d networks", #caves, #entrances, #networks))
		print("✅ Cave generation complete:", #caves, "caves,", #entrances, "entrances,", #networks, "networks")

		return {
			caves = caves,
			entrances = entrances,
			networks = networks
		}
	end)
end

function NoiseGenerator:generateCaveSystem(region: Region3, settings: ValidatedCaveSettings): CaveSystemData
	return self:generateCaveSystemWithProgress(region, settings, nil)
end

-- ================================================================================================
--                                 ENHANCED CAVE ANALYSIS
-- ================================================================================================

function NoiseGenerator:generateCaveFeatures(cave: CaveData, position: Vector3): {CaveFeature}
	assert(type(cave) == "table", "Cave data must be a table")
	assert(typeof(position) == "Vector3", "Position must be a Vector3")

	return self:profileFunction("generateCaveFeatures", function(): {CaveFeature}
		local features: {CaveFeature} = {}

		-- Stalactites and Stalagmites
		local speleothemNoise: number = self:simplex3D(position.X * 0.1, position.Y * 0.1, position.Z * 0.1)
		if speleothemNoise > 0.6 and cave.chamberStrength > 0.5 then
			features[#features + 1] = {
				type = "stalactite",
				position = position + Vector3.new(0, 5, 0),
				length = self._rng:NextInteger(2, 8),
				thickness = 0.5 + cave.roughness
			}

			-- Matching stalagmite below
			if self._rng:NextNumber() > 0.3 then
				features[#features + 1] = {
					type = "stalagmite",
					position = position - Vector3.new(0, 5, 0),
					length = self._rng:NextInteger(1, 6),
					thickness = 0.7 + cave.roughness
				}
			end
		end

		-- Underground pools
		local poolNoise: number = self:worley3D(position.X * 0.03, position.Y * 0.03, position.Z * 0.03)
		if poolNoise < 0.2 and cave.chamberStrength > 0.7 and position.Y < -30 then
			features[#features + 1] = {
				type = "pool",
				position = position,
				radius = 3 + cave.chamberStrength * 5,
				depth = 1 + cave.chamberStrength * 3
			}
		end

		-- Crystal formations
		local crystalNoise: number = self:ridge3D(position.X * 0.05, position.Y * 0.05, position.Z * 0.05)
		if crystalNoise > 0.8 and self._rng:NextNumber() > 0.7 then
			-- Generate procedural color based on position
			local r: number = (self:simplex3D(position.X * 0.01, position.Y * 0.01, position.Z * 0.01) + 1) * 0.5
			local g: number = (self:simplex3D(position.X * 0.01 + 100, position.Y * 0.01, position.Z * 0.01) + 1) * 0.5
			local b: number = (self:simplex3D(position.X * 0.01, position.Y * 0.01 + 100, position.Z * 0.01) + 1) * 0.5

			features[#features + 1] = {
				type = "crystals",
				position = position,
				count = self._rng:NextInteger(3, 12),
				color = Color3.new(r, g, b)
			}
		end

		return features
	end)
end

function NoiseGenerator:simulateWaterFlow(caves: {CaveData}, iterations: number?): {FlowPath}
	assert(type(caves) == "table", "Caves must be a table")
	local iterCount: number = iterations or 50

	return self:profileFunction("simulateWaterFlow", function(): {FlowPath}
		local flowPaths: {FlowPath} = {}
		local defaultSettings = validateCaveSettings({})

		-- Find water sources (higher elevation caves)
		local sources: {CaveData} = {}
		for _, cave: CaveData in pairs(caves) do
			if cave.position.Y > -20 and cave.contents == "water" then
				sources[#sources + 1] = cave
			end
		end

		print("💧 Simulating water flow from", #sources, "sources")

		local memoCache: {[Vector3]: CaveData} = {}
		local function getMemoizedCaveData(pos: Vector3, settings: ValidatedCaveSettings): CaveData
			local cached = memoCache[pos]
			if cached then
				return cached
			end
			local newData = self:generateRealisticCaves(pos.X, pos.Y, pos.Z, settings)
			memoCache[pos] = newData
			return newData
		end


		-- Simulate flow for each source
		for _, source: CaveData in pairs(sources) do
			local currentPos: Vector3 = source.position
			local path: {Vector3} = {currentPos}

			for i: number = 1, iterCount do
				-- Use gradient of cave density to determine flow direction, passing the memoCache
				local gradient: Vector3 = self:calculateCaveDensityGradient(currentPos, defaultSettings, memoCache)

				-- Flow towards lower density (bigger caves) and downward
				local flowDirection: Vector3 = gradient + Vector3.new(0, -0.5, 0)
				if flowDirection.Magnitude > 0 then
					currentPos = currentPos + flowDirection.Unit * 2
				else
					break  -- No flow direction
				end

				path[#path + 1] = currentPos

				-- Stop if we hit solid rock or reach depth limit, using the memoized helper
				local caveHere: CaveData = getMemoizedCaveData(currentPos, defaultSettings)
				if not caveHere.isAir or currentPos.Y < -100 then
					break
				end
			end

			flowPaths[#flowPaths + 1] = {
				source = source.position,
				path = path,
				flowRate = source.size
			}
		end

		return flowPaths
	end)
end

function NoiseGenerator:calculateCaveDensityGradient(pos: Vector3, settings: ValidatedCaveSettings, memoCache: {[Vector3]: CaveData}?): Vector3
	assert(typeof(pos) == "Vector3", "Position must be a Vector3")
	assert(type(settings) == "table", "Settings must be a table")

	return self:profileFunction("calculateCaveDensityGradient", function(): Vector3
		local epsilon: number = 1.0

		local function getCaveData(atPos: Vector3): CaveData
			if memoCache then
				local cached = memoCache[atPos]
				if cached then
					return cached
				end
				local newData = self:generateRealisticCaves(atPos.X, atPos.Y, atPos.Z, settings)
				memoCache[atPos] = newData
				return newData
			else
				return self:generateRealisticCaves(atPos.X, atPos.Y, atPos.Z, settings)
			end
		end

		local center: CaveData = getCaveData(pos)

		local dx: number = getCaveData(pos + Vector3.new(epsilon, 0, 0)).tunnelStrength - center.tunnelStrength
		local dy: number = getCaveData(pos + Vector3.new(0, epsilon, 0)).tunnelStrength - center.tunnelStrength
		local dz: number = getCaveData(pos + Vector3.new(0, 0, epsilon)).tunnelStrength - center.tunnelStrength

		return Vector3.new(dx, dy, dz)
	end)
end

function NoiseGenerator:generateCaveEntrances(heightmap: {{number}}, caves: {CaveData}): {CaveEntrance}
	assert(type(heightmap) == "table", "Heightmap must be a table")
	assert(type(caves) == "table", "Caves must be a table")

	return self:profileFunction("generateCaveEntrances", function(): {CaveEntrance}
		local entrances: {CaveEntrance} = {}

		for _, cave: CaveData in pairs(caves) do
			-- Only consider caves near surface
			if cave.position.Y > -30 and cave.isMainTunnel then
				local heightmapRow: {number}? = heightmap[1]
				local heightmapWidth: number = if heightmapRow then #heightmapRow else 0
				local heightmapHeight: number = #heightmap

				if heightmapWidth > 0 and heightmapHeight > 0 then
					local surfaceX: number = math.max(1, math.min(heightmapWidth, math.floor(cave.position.X) + math.floor(heightmapWidth / 2)))
					local surfaceZ: number = math.max(1, math.min(heightmapHeight, math.floor(cave.position.Z) + math.floor(heightmapHeight / 2)))

					-- Safe heightmap access with nil checks
					local surfaceRow: {number}? = heightmap[surfaceZ]
					if surfaceRow and surfaceRow[surfaceX] then
						local surfaceHeight: number = surfaceRow[surfaceX] * 50  -- Scale to world units

						-- Entrance possible if cave is close to surface
						if math.abs(cave.position.Y - surfaceHeight) < 15 then
							local entranceNoise: number = self:simplex2D(cave.position.X * 0.01, cave.position.Z * 0.01)

							if entranceNoise > 0.3 then  -- Random entrance placement
								entrances[#entrances + 1] = {
									position = Vector3.new(cave.position.X, surfaceHeight, cave.position.Z),
									cavePosition = cave.position,
									size = cave.chamberStrength * 5 + 2,  -- Entrance size
									type = if cave.chamberStrength > 0.7 then "large" else "tunnel"
								}
							end
						end
					end
				end
			end
		end

		return entrances
	end)
end

function NoiseGenerator:analyzeCaveNetworks(caves: {CaveData}, settings: ValidatedCaveSettings): {{CaveData}}
	assert(type(caves) == "table", "Caves must be a table")
	assert(type(settings) == "table", "Settings must be a table")

	return self:profileFunction("analyzeCaveNetworks", function(): {{CaveData}}
		local networks: {{CaveData}} = {}
		local visited: {[CaveData]: boolean} = {}

		-- IMPLEMENTED: More accurate line-of-sight connectivity check
		local connectionRadius: number = 30 / settings.connectivity -- Higher connectivity = smaller radius and more checks
		local checkStep: number = 4 -- studs, resolution of the line-of-sight check

		-- Checks if the path between two points is clear of solid rock
		local function isPathClear(startPos: Vector3, endPos: Vector3): boolean
			local direction: Vector3 = (endPos - startPos)
			local distance: number = direction.Magnitude
			local unit: Vector3 = direction.Unit

			local steps: number = math.floor(distance / checkStep)
			if steps <= 1 then
				return true -- Points are very close, assume clear
			end

			-- Sample points along the line, skipping the start and end points
			for i = 1, steps - 1 do
				local checkPos: Vector3 = startPos + unit * (i * checkStep)
				-- This is the expensive part that makes connectivity accurate
				local caveDataAtPoint: CaveData = self:generateRealisticCaves(checkPos.X, checkPos.Y, checkPos.Z, settings)
				if not caveDataAtPoint.isAir then
					return false -- Path is blocked
				end
			end
			return true
		end

		local function findConnectedCaves(startCave: CaveData, network: {CaveData}): ()
			if visited[startCave] then return end
			visited[startCave] = true
			network[#network + 1] = startCave

			for _, otherCave: CaveData in pairs(caves) do
				if not visited[otherCave] then
					local distance: number = (startCave.position - otherCave.position).Magnitude
					-- Broad-phase distance check first for performance
					if distance < connectionRadius then
						-- Narrow-phase line-of-sight check for accuracy
						if isPathClear(startCave.position, otherCave.position) then
							findConnectedCaves(otherCave, network)
						end
					end
				end
			end
		end

		for _, cave: CaveData in pairs(caves) do
			if not visited[cave] and cave.isMainTunnel then
				local network: {CaveData} = {}
				findConnectedCaves(cave, network)
				if #network > 1 then  -- Only count networks with multiple caves
					networks[#networks + 1] = network
				end
			end
		end

		return networks
	end)
end

function NoiseGenerator:findCaveEntrances(caves: {CaveData}): {CaveEntrance}
	assert(type(caves) == "table", "Caves must be a table")

	return self:profileFunction("findCaveEntrances", function(): {CaveEntrance}
		local entrances: {CaveEntrance} = {}

		for _, cave: CaveData in pairs(caves) do
			-- Look for caves that could connect to surface
			if cave.position.Y > -50 and cave.isMainTunnel then
				local surfaceProximity: number = (-cave.position.Y) / 50  -- Closer to surface = higher value
				local entranceChance: number = surfaceProximity * cave.tunnelStrength

				if entranceChance > 0.6 then
					entrances[#entrances + 1] = {
						position = Vector3.new(cave.position.X, 0, cave.position.Z),  -- Surface level
						cavePosition = cave.position,
						size = cave.size * 5,
						type = if cave.chamberStrength > 0.7 then "chamber" else "tunnel"
					}
				end
			end
		end

		return entrances
	end)
end

-- ================================================================================================
--                                 COMPLETE UNDERGROUND SYSTEM
-- ================================================================================================

function NoiseGenerator:generateCompleteUnderground(region: Region3, settings: UndergroundSettings, progressCallback: ProgressCallback?): UndergroundSystem
	assert(typeof(region) == "Region3", "Region must be a Region3")
	assert(type(settings) == "table", "Settings must be a table")

	local callback: ProgressCallback = progressCallback or function(_: number, _: string, _: string?) end

	return self:profileFunction("generateCompleteUnderground", function(): UndergroundSystem
		print("🗻 Starting complete underground generation for region:", region.Size)

		-- Step 1: Generate cave networks
		callback(0, "Step 1: Cave Networks", "Generating cave systems...")
		print("🕳️ Step 1: Generating cave networks...")
		local caves: CaveSystemData = self:generateCaveSystemWithProgress(region, settings.caves, function(progress: number, stage: string, details: string?)
			callback(progress * 0.5, "Step 1: " .. stage, details)
		end)

		-- Step 2: Simulate water flow and erosion
		callback(0.5, "Step 2: Water Flow", "Simulating water flow patterns...")
		print("💧 Step 2: Simulating water flow...")
		local waterFlow: {FlowPath} = self:simulateWaterFlow(caves.caves, 100)

		-- Step 3: Create cave features
		callback(0.7, "Step 3: Cave Features", "Generating stalactites, pools, and crystals...")
		print("💎 Step 3: Generating cave features...")
		local features: {CaveFeature} = {}
		for i: number, cave: CaveData in pairs(caves.caves) do
			local caveFeatures: {CaveFeature} = self:generateCaveFeatures(cave, cave.position)
			for _, feature: CaveFeature in pairs(caveFeatures) do
				features[#features + 1] = feature
			end

			-- Progress reporting and yielding
			if i % 50 == 0 then
				local progress: number = 0.7 + (i / #caves.caves) * 0.2
				callback(progress, "Step 3: Cave Features", string.format("Processed %d/%d caves", i, #caves.caves))
				task.wait()
				self:validateMemoryUsage()
			end
		end

		-- Step 4: Find natural entrances
		callback(0.9, "Step 4: Natural Entrances", "Finding surface connections...")
		print("🚪 Step 4: Finding natural entrances...")
		local heightmap: {{number}} = self:generateHeightmap(
				math.floor(region.Size.X / 4),
				math.floor(region.Size.Z / 4),
				validateNoiseSettings(settings.surface)
			)
		local entrances: {CaveEntrance} = self:generateCaveEntrances(heightmap, caves.caves)

		local stats = {
			totalCaves = #caves.caves,
			totalEntrances = #entrances,
			totalFeatures = #features
		}

		callback(1.0, "Underground Generation Complete", string.format("Generated %d caves, %d entrances, %d features", stats.totalCaves, stats.totalEntrances, stats.totalFeatures))
		print("✅ Underground generation complete!")
		print("📊 Stats:", stats.totalCaves, "caves,", stats.totalEntrances, "entrances,", stats.totalFeatures, "features")

		return {
			caves = caves,
			waterFlow = waterFlow,
			features = features,
			entrances = entrances,
			stats = stats
		}
	end)
end

-- ================================================================================================
--                                 CONVENIENCE FUNCTIONS
-- ================================================================================================

function NoiseGenerator:generateHeightmap(width: number, height: number, settings: NoiseSettings): {{number}}
	assert(type(width) == "number" and type(height) == "number", "Dimensions must be numbers")
	assert(width > 0 and height > 0, "Dimensions must be positive")
	assert(width <= 1024 and height <= 1024, "Dimensions too large (max 1024x1024)")

	return self:profileFunction("generateHeightmap", function(): {{number}}
		local validatedSettings: NoiseSettings = validateNoiseSettings(settings)

		if validatedSettings.seed then
			self:setSeed(validatedSettings.seed)
		end

		local scale: number = validatedSettings.scale or 0.01
		local octaves: number = validatedSettings.octaves or 6
		local lacunarity: number = validatedSettings.lacunarity or 2.0
		local persistence: number = validatedSettings.persistence or 0.5

		local heightmap: {{number}} = {}
		for y: number = 1, height do
			heightmap[y] = {}
			for x: number = 1, width do
				local worldX: number = x * scale
				local worldZ: number = y * scale
				heightmap[y][x] = self:FBM(worldX, 0, worldZ, octaves, lacunarity, persistence)
			end

			-- Yield periodically
			if y % self._config.performance.yieldInterval == 0 then
				task.wait()
			end
		end

		return heightmap
	end)
end

function NoiseGenerator:generateCaves(x: number, y: number, z: number, settings: {scale: number, threshold: number, jitter: number?}): number
	assert(type(settings) == "table", "Settings must be a table")
	assert(type(settings.scale) == "number" and settings.scale > 0, "Scale must be a positive number")
	assert(type(settings.threshold) == "number" and settings.threshold >= -1 and settings.threshold <= 1, "Threshold must be between -1 and 1")

	return self:profileFunction("generateCaves", function(): number
		local caveNoise: number = self:worley3D(x * settings.scale, y * settings.scale, z * settings.scale, settings.jitter)
		return if caveNoise < settings.threshold then 1 else 0
	end)
end

function NoiseGenerator.normalize(value: number, newMin: number, newMax: number, oldMin: number?, oldMax: number?): number
	return normalizeRange(value, newMin, newMax, oldMin, oldMax)
end

function NoiseGenerator:benchmark(iterations: number?): {[string]: number}
	local iterCount: number = iterations or 10000
	local results: {[string]: number} = {}

	local function benchmarkFunction(name: string, func: () -> ()): ()
		local startTime: number = os.clock()
		for i: number = 1, iterCount do
			func()
		end
		local endTime: number = os.clock()
		results[name] = (endTime - startTime) * 1000  -- Convert to milliseconds
	end

	-- Benchmark core noise functions
	benchmarkFunction("simplex2D", function(): ()
		self:simplex2D(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100)
	end)

	benchmarkFunction("simplex3D", function(): ()
		self:simplex3D(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100)
	end)

	benchmarkFunction("simplex4D", function(): ()
		self:simplex4D(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100)
	end)

	benchmarkFunction("perlin3D", function(): ()
		self:perlin3D(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100)
	end)

	benchmarkFunction("worley3D_F1", function(): ()
		self:worley3D(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, 1.0, "F1")
	end)

	benchmarkFunction("FBM", function(): ()
		self:FBM(self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, self._rng:NextNumber() * 100, 6, 2.0, 0.5)
	end)

	return results
end

-- ================================================================================================
--                                    DEBUG HELPERS
-- ================================================================================================

NoiseLib.Debug = {
	visualizeNoise2D = function(generator: NoiseGenerator, width: number, height: number, scale: number): Frame
		local frame: Frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, width, 0, height)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)

		for x: number = 1, width do
			for y: number = 1, height do
				local noise: number = generator:simplex2D(x * scale, y * scale)
				local colorValue: number = noise * 0.5 + 0.5
				local color: Color3 = Color3.new(colorValue, colorValue, colorValue)

				local pixel: Frame = Instance.new("Frame")
				pixel.Size = UDim2.new(0, 1, 0, 1)
				pixel.Position = UDim2.new(0, x-1, 0, y-1)
				pixel.BackgroundColor3 = color
				pixel.BorderSizePixel = 0
				pixel.Parent = frame
			end
		end

		return frame
	end,

	generatePerformanceReport = function(generator: NoiseGenerator): string
		local stats: PerformanceStats = generator:getPerformanceStats()
		local hitRate: number = if (stats.cacheStats.hits + stats.cacheStats.misses) > 0
			then (stats.cacheStats.hits / (stats.cacheStats.hits + stats.cacheStats.misses)) * 100
			else 0

		local report: string = string.format([[
=== NoiseLib Performance Report ===
Total Executions: %d
Average Execution Time: %.2fms
Peak Memory Usage: %.2fKB
Cache Hit Rate: %.1f%%
Cache Size: %d/%d
===================================
]],
			stats.totalExecutions,
			stats.averageExecutionTime,
			stats.peakMemoryUsage,
			hitRate,
			stats.cacheStats.size,
			stats.cacheStats.maxSize
		)

		return report
	end
}

-- ================================================================================================
--                                    MODULE INTERFACE
-- ================================================================================================

-- Create a default global instance for backward compatibility
local defaultGenerator: NoiseGenerator = NoiseGenerator.new(12345)

-- Export the NoiseGenerator class and a default instance
function NoiseLib.new(seed: number?, config: GenerationConfig?): NoiseGenerator
	return NoiseGenerator.new(seed, config)
end

-- Provide access to default instance methods for compatibility
NoiseLib.setSeed = function(seed: number): ()
	defaultGenerator:setSeed(seed)
end

NoiseLib.simplex2D = function(x: number, y: number): number
	return defaultGenerator:simplex2D(x, y)
end

NoiseLib.simplex3D = function(x: number, y: number, z: number): number
	return defaultGenerator:simplex3D(x, y, z)
end

NoiseLib.simplex4D = function(x: number, y: number, z: number, w: number): number
	return defaultGenerator:simplex4D(x, y, z, w)
end

NoiseLib.perlin3D = function(x: number, y: number, z: number): number
	return defaultGenerator:perlin3D(x, y, z)
end

NoiseLib.worley3D = function(x: number, y: number, z: number, jitter: number?, mode: string?): number
	return defaultGenerator:worley3D(x, y, z, jitter, mode)
end

NoiseLib.FBM = function(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	return defaultGenerator:FBM(x, y, z, octaves, lacunarity, persistence)
end

NoiseLib.getFBM = function(x: number, y: number, z: number, settings: NoiseSettings?): number
	return defaultGenerator:getFBM(x, y, z, settings)
end

NoiseLib.advancedDomainWarp = function(x: number, y: number, z: number, warpSettings: WarpSettings, sourceSettings: WarpSettings): number
	return defaultGenerator:advancedDomainWarp(x, y, z, warpSettings, sourceSettings)
end

NoiseLib.curl3D = function(x: number, y: number, z: number, epsilon: number?): (number, number, number)
	return defaultGenerator:curl3D(x, y, z, epsilon)
end

NoiseLib.ridge3D = function(x: number, y: number, z: number): number
	return defaultGenerator:ridge3D(x, y, z)
end

NoiseLib.turbulence3D = function(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	return defaultGenerator:turbulence3D(x, y, z, octaves, lacunarity, persistence)
end

NoiseLib.billow = function(x: number, y: number, z: number, octaves: number, lacunarity: number, persistence: number): number
	return defaultGenerator:billow(x, y, z, octaves, lacunarity, persistence)
end

NoiseLib.animatedNoise = function(x: number, y: number, z: number, time: number, timeScale: number?): number
	return defaultGenerator:animatedNoise(x, y, z, time, timeScale)
end

NoiseLib.generateHeightmap = function(width: number, height: number, settings: NoiseSettings): {{number}}
	return defaultGenerator:generateHeightmap(width, height, settings)
end

NoiseLib.generateCaves = function(x: number, y: number, z: number, settings: {scale: number, threshold: number, jitter: number?}): number
	return defaultGenerator:generateCaves(x, y, z, settings)
end

-- Enhanced cave generation methods
NoiseLib.generateGeologicalNoise = function(x: number, y: number, z: number, geologicalLayer: any): number
	return defaultGenerator:generateGeologicalNoise(x, y, z, geologicalLayer)
end

NoiseLib.generateCaveFormationNoise = function(x: number, y: number, z: number, formationType: string): number
	return defaultGenerator:generateCaveFormationNoise(x, y, z, formationType)
end

NoiseLib.generateErosionPattern = function(x: number, y: number, z: number, waterVelocity: Vector3, rockHardness: number): number
	return defaultGenerator:generateErosionPattern(x, y, z, waterVelocity, rockHardness)
end

NoiseLib.generateSpeleothemPattern = function(x: number, y: number, z: number, humidity: number, age: number): number
	return defaultGenerator:generateSpeleothemPattern(x, y, z, humidity, age)
end

NoiseLib.generateCaveQualityNoise = function(x: number, y: number, z: number, qualitySettings: any): {[string]: number}
	return defaultGenerator:generateCaveQualityNoise(x, y, z, qualitySettings)
end

NoiseLib.generateCaveWarpedNoise = function(x: number, y: number, z: number, primarySettings: NoiseSettings, warpSettings: WarpSettings, geologicalInfluence: number?): number
	return defaultGenerator:generateCaveWarpedNoise(x, y, z, primarySettings, warpSettings, geologicalInfluence)
end

NoiseLib.generateQualityCaveNoise = function(x: number, y: number, z: number, baseSettings: NoiseSettings, qualityEnhancement: number?): number
	return defaultGenerator:generateQualityCaveNoise(x, y, z, baseSettings, qualityEnhancement)
end

NoiseLib.generateNoiseLayers = function(x: number, y: number, z: number, layerConfigs: {any}): {[string]: number}
	return defaultGenerator:generateNoiseLayers(x, y, z, layerConfigs)
end

NoiseLib.assessNoiseQuality = function(noiseValues: {number}, targetDistribution: string?): number
	return defaultGenerator:assessNoiseQuality(noiseValues, targetDistribution)
end

NoiseLib.generateCaveSystem = function(region: Region3, settings: CaveSettings): CaveSystemData
	local validatedSettings: ValidatedCaveSettings = validateCaveSettings(settings)
	return defaultGenerator:generateCaveSystem(region, validatedSettings)
end

NoiseLib.generateCaveSystemSafe = function(region: Region3, settings: CaveSettings): GenerationResult<CaveSystemData>
	return defaultGenerator:generateCaveSystemSafe(region, settings)
end

NoiseLib.generateCompleteUnderground = function(region: Region3, settings: UndergroundSettings, progressCallback: ProgressCallback?): UndergroundSystem
	return defaultGenerator:generateCompleteUnderground(region, settings, progressCallback)
end

NoiseLib.normalize = NoiseGenerator.normalize

NoiseLib.benchmark = function(iterations: number?): {[string]: number}
	return defaultGenerator:benchmark(iterations)
end

-- Enhanced utility methods
NoiseLib.cleanup = function(): ()
	defaultGenerator:cleanup()
end

NoiseLib.getPerformanceStats = function(): PerformanceStats
	return defaultGenerator:getPerformanceStats()
end

NoiseLib.clearCache = function(): ()
	defaultGenerator:clearCache()
end

NoiseLib.setConfig = function(config: GenerationConfig): ()
	defaultGenerator:setConfig(config)
end

-- Legacy compatibility (basic domain warp)
NoiseLib.domainWarp = function(x: number, y: number, z: number, warpSettings: {octaves: number, lacunarity: number, persistence: number, scale: number}, sourceSettings: {octaves: number, lacunarity: number, persistence: number, scale: number}): number
	return defaultGenerator:advancedDomainWarp(x, y, z,
		{octaves = warpSettings.octaves, lacunarity = warpSettings.lacunarity, persistence = warpSettings.persistence, scale = warpSettings.scale, strength = 0.1},
		{octaves = sourceSettings.octaves, lacunarity = sourceSettings.lacunarity, persistence = sourceSettings.persistence, scale = sourceSettings.scale}
	)
end

-- Configuration presets for easy use
NoiseLib.Presets = {
	TERRAIN_REALISTIC = {
		octaves = 6, lacunarity = 2.0, persistence = 0.5, scale = 0.01
	},
	TERRAIN_MOUNTAINOUS = {
		octaves = 8, lacunarity = 2.2, persistence = 0.6, scale = 0.005
	},
	CAVES_SPARSE = {
		threshold = 0.3, optimalDepth = -60, depthRange = 40, tunnelScale = 0.02, chamberScale = 0.05
	},
	CAVES_DENSE = {
		threshold = 0.5, optimalDepth = -40, depthRange = 30, tunnelScale = 0.03, chamberScale = 0.07
	},
	CLOUDS_WISPY = {
		octaves = 4, lacunarity = 2.0, persistence = 0.4, scale = 0.02
	},

	-- Performance presets
	CONFIG_HIGH_PERFORMANCE = {
		cache = { enabled = true, maxSize = 50000, cleanupThreshold = 0.8, fullPrecision = false },
		performance = { yieldInterval = 50, memoryThreshold = 100000, profilingEnabled = false },
		async = true
	},

	CONFIG_MEMORY_EFFICIENT = {
		cache = { enabled = true, maxSize = 5000, cleanupThreshold = 0.6, fullPrecision = false },
		performance = { yieldInterval = 25, memoryThreshold = 25000, profilingEnabled = false },
		async = true
	},

	CONFIG_HIGH_PRECISION = {
		cache = { enabled = true, maxSize = 20000, cleanupThreshold = 0.8, fullPrecision = true },
		performance = { yieldInterval = 100, memoryThreshold = 50000, profilingEnabled = false },
		async = true
	},

	CONFIG_DEBUG = {
		cache = { enabled = true, maxSize = 10000, cleanupThreshold = 0.7, fullPrecision = false },
		performance = { yieldInterval = 100, memoryThreshold = 50000, profilingEnabled = true },
		async = false
	}
}

return NoiseLib