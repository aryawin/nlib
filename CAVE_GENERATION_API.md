# Cave Generation API Documentation

The `InitializeCaveGeneration` module provides a comprehensive API for generating procedural caves in Roblox. It orchestrates three tiers of generation to create realistic, connected cave systems.

## Quick Start

```lua
-- Simple cave generation
local InitializeCaveGeneration = require(game.ServerScriptService.InitializeCaveGeneration)

-- Generate a basic cave at spawn
local position = Vector3.new(0, -25, 0)
local size = Vector3.new(100, 50, 100)
local result = InitializeCaveGeneration.generateQuickCave(position, size)

if result.success then
    print("Cave generated successfully!")
    print("Features:", result.features.chambers, "chambers,", result.features.passages, "passages")
else
    warn("Cave generation failed:", result.errorMessage)
end
```

## API Functions

### Main Generation Functions

#### `generateCave(region, customConfig?, options?)`
The primary cave generation function with full control over all parameters.

**Parameters:**
- `region: Region3` - The 3D region where the cave will be generated
- `customConfig: table?` - Optional configuration overrides (merges with default Config)
- `options: GenerationOptions?` - Optional generation options

**Returns:** `GenerationResult`

**Example:**
```lua
local region = Region3.new(Vector3.new(-50, -50, -50), Vector3.new(50, 0, 50))

local customConfig = {
    Core = {
        seed = 12345, -- Fixed seed for reproducible caves
        logLevel = "INFO"
    },
    Tier1 = {
        mainChambers = {
            densityThreshold = 0.1 -- More chambers
        }
    }
}

local options = {
    enableTier1 = true,
    enableTier2 = true,
    enableTier3 = false, -- Skip micro-features for speed
    progressCallback = function(progress, stage, details)
        print(string.format("%.1f%% - %s", progress * 100, stage))
    end,
    timeout = 60
}

local result = InitializeCaveGeneration.generateCave(region, customConfig, options)
```

#### `generateQuickCave(position, size?)`
Generate a simple cave with optimized settings for quick generation.

**Parameters:**
- `position: Vector3` - Center position of the cave
- `size: Vector3?` - Size of the cave (default: 100x50x100 studs)

**Returns:** `GenerationResult`

**Example:**
```lua
-- Generate a small cave for testing
local result = InitializeCaveGeneration.generateQuickCave(
    Vector3.new(0, -20, 0),
    Vector3.new(50, 30, 50)
)
```

#### `generateAdvancedCave(region, customConfig, progressCallback?)`
Generate a cave with all features enabled and extended timeout.

**Parameters:**
- `region: Region3` - The generation region
- `customConfig: table` - Custom configuration (required)
- `progressCallback: function?` - Optional progress reporting function

**Returns:** `GenerationResult`

#### `generateTestCave()`
Generate a test cave with fixed seed and debug features enabled.

**Returns:** `GenerationResult`

### Utility Functions

#### `isGenerating()`
Check if a cave generation is currently in progress.

**Returns:** `boolean`

#### `getGenerationStats()`
Get statistics about cave generation performance.

**Returns:** Statistics table with total/successful generations, success rate, and timing info

#### `cleanup()`
Clean up memory and clear cave data. Call this between generations if needed.

#### `getVersion()`
Get the current version of the cave generation system.

**Returns:** `string`

#### `validateModules()`
Validate that all required modules are available.

**Returns:** `boolean`

## Generation Options

```lua
type GenerationOptions = {
    enableTier1: boolean?, -- Foundation features (default: true)
    enableTier2: boolean?, -- Complexity features (default: true)  
    enableTier3: boolean?, -- Micro-features (default: true)
    progressCallback: function?, -- Progress reporting function
    timeout: number?, -- Generation timeout in seconds
    enableDebugVisualization: boolean?, -- Enable debug visuals
    enablePerformanceLogging: boolean?, -- Enable performance logs
    yieldInterval: number?, -- Override default yield interval
}
```

## Generation Result

```lua
type GenerationResult = {
    success: boolean, -- Whether generation succeeded
    generationTime: number, -- Total time in seconds
    totalVoxels: number, -- Number of voxels processed
    memoryUsed: number, -- Memory usage in KB
    features: { -- Count of generated features
        chambers: number,
        passages: number,
        verticalShafts: number,
        branches: number,
        subChambers: number,
        collapseRooms: number,
        hiddenPockets: number,
        microFeatures: number,
    },
    errorMessage: string?, -- Error message if failed
    metadata: table -- Additional generation metadata
}
```

## Configuration Customization

You can customize any aspect of cave generation by providing a `customConfig` table:

```lua
local customConfig = {
    -- Core system settings
    Core = {
        seed = 42, -- Fixed seed for reproducible caves
        chunkSize = 64, -- Smaller chunks for better performance
        maxGenerationTime = 45, -- Timeout per tier
        yieldInterval = 50, -- Yield more frequently
        logLevel = "INFO", -- Logging level
        enablePerformanceLogging = true
    },
    
    -- Noise settings
    Noise = {
        primary = {
            scale = 0.03, -- Larger scale = bigger features
            threshold = 0.2 -- Lower = more open space
        }
    },
    
    -- Tier 1: Foundation features
    Tier1 = {
        mainChambers = {
            enabled = true,
            densityThreshold = 0.15, -- Lower = more chambers
            minSize = 10,
            maxSize = 30
        },
        passages = {
            enabled = true,
            minWidth = 4,
            maxWidth = 10,
            curvature = 0.3 -- 0 = straight, 1 = very curved
        },
        verticalShafts = {
            enabled = true,
            density = 0.08, -- Probability per chamber
            minHeight = 15,
            maxHeight = 50
        }
    },
    
    -- Tier 2: Complexity features  
    Tier2 = {
        enabled = true,
        branches = {
            enabled = true,
            probability = 0.3, -- Per passage segment
            deadEndChance = 0.4
        },
        subChambers = {
            enabled = true,
            probability = 0.5, -- Per main chamber
            sizeRatio = 0.7 -- Relative to parent
        }
    },
    
    -- Tier 3: Micro-features
    Tier3 = {
        enabled = true,
        fractureVeins = {
            enabled = true,
            density = 0.25,
            zigzagIntensity = 0.5
        }
    }
}
```

## Error Handling

The cave generation system includes robust error handling:

```lua
local result = InitializeCaveGeneration.generateCave(region, config, options)

if not result.success then
    if result.errorMessage then
        warn("Generation failed:", result.errorMessage)
    end
    
    -- You can still check what was generated before the error
    print("Partial generation:", result.features.chambers, "chambers")
end
```

## Performance Tips

1. **Use `generateQuickCave()`** for testing or when you need fast generation
2. **Disable higher tiers** for better performance: set `enableTier2 = false, enableTier3 = false`
3. **Reduce chunk size** in config for better memory usage: `Core.chunkSize = 32`
4. **Increase yield interval** for faster generation: `Core.yieldInterval = 200`
5. **Set reasonable timeouts** to prevent hanging: `timeout = 30`

## Example: Progressive Cave Generation

```lua
-- Generate caves of increasing complexity
local function generateProgressiveCave(position)
    print("Generating basic cave...")
    local basic = InitializeCaveGeneration.generateQuickCave(position, Vector3.new(40, 25, 40))
    
    if basic.success then
        print("Generating complex cave...")
        local region = Region3.new(position - Vector3.new(50, 30, 50), position + Vector3.new(50, 20, 50))
        local complex = InitializeCaveGeneration.generateAdvancedCave(region, {
            Tier2 = { enabled = true },
            Tier3 = { enabled = false } -- Skip micro-features
        })
        
        if complex.success then
            print("Cave system generated successfully!")
            print("Total features:", complex.features.chambers + complex.features.passages)
        end
    end
end

generateProgressiveCave(Vector3.new(0, -30, 0))
```

## Troubleshooting

**Cave generation is too slow:**
- Use `generateQuickCave()` instead
- Disable Tier 2 and 3: `enableTier2 = false, enableTier3 = false`
- Reduce region size
- Increase yield interval: `yieldInterval = 200`

**Caves are too sparse:**
- Lower `densityThreshold` in chamber config: `densityThreshold = 0.1`
- Lower noise threshold: `Noise.primary.threshold = 0.2`

**Caves are too dense:**
- Raise `densityThreshold` in chamber config: `densityThreshold = 0.3` 
- Raise noise threshold: `Noise.primary.threshold = 0.4`

**Generation fails with timeout:**
- Increase timeout: `timeout = 120`
- Reduce region size
- Use `generateQuickCave()` for testing

**Memory issues:**
- Reduce chunk size: `Core.chunkSize = 32`
- Call `InitializeCaveGeneration.cleanup()` between generations
- Enable garbage collection: add `wait()` calls in progress callback