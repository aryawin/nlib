# Simple Cave Generation for Roblox

A streamlined cave generation system that creates beautiful, natural-looking cave systems without floating rocks or disconnected segments. Designed for immediate good results with minimal configuration.

## 🌟 Key Features

- **Clean Cave Structures**: No floating rocks or disconnected segments
- **Simple API**: Easy to use with good defaults that just work
- **3D Density Field**: Creates naturally connected tunnels and chambers
- **Multi-Scale Noise**: Combines different scales for realistic cave structures
- **Connectivity Filtering**: Automatically removes isolated floating elements
- **Optimized Performance**: Efficient chunk-based processing with `Terrain:WriteVoxels`

## 📁 File Structure

```
nlib/
├── NoiseLib.lua                    # Core noise generation library
├── ProceduralCaveGenerator.lua     # Simplified cave generation system
├── CaveGenerationExample.lua       # Easy-to-use examples
└── README.md                       # This documentation
```

## 🚀 Quick Start

### Basic Usage (Just Works!)

```lua
local CaveGenerator = require(script.ProceduralCaveGenerator)

-- Create a test region
local region = CaveGenerator.createTestRegion(Vector3.new(0, -64, 0), Vector3.new(128, 80, 128))

-- Generate caves with good defaults
local result = CaveGenerator.generateCaves(workspace.Terrain, region)

if result.success then
    print("✅ Generated", result.cavesGenerated, "cave voxels!")
else
    warn("❌ Failed:", result.error)
end
```

### Using Examples

```lua
local CaveExamples = require(script.CaveGenerationExample)

-- Generate basic caves (recommended starting point)
CaveExamples.generateBasicCaves(workspace.Terrain)

-- Try different styles
CaveExamples.generateDenseCaves(workspace.Terrain)
CaveExamples.generateBigCaverns(workspace.Terrain)

-- Quick demo of all types
CaveExamples.runDemo(workspace.Terrain)
```

## 🎛️ Configuration Options

### Simple Settings

```lua
local settings = {
    -- Cave density and structure
    caveThreshold = 0.4,      -- How dense caves should be (0.3-0.6)
    caveScale = 0.03,         -- Size of cave features (0.02-0.08)
    tunnelScale = 0.025,      -- Scale for main tunnels (0.01-0.05)
    chamberScale = 0.08,      -- Scale for large chambers (0.05-0.15)
    
    -- Depth control
    minDepth = -20,           -- Minimum depth for caves
    maxDepth = -150,          -- Maximum depth for caves
    
    -- Features
    generateStalactites = true, -- Add cave decorations
    waterLevel = -80,         -- Y level for water
    
    -- Performance
    resolution = 4,           -- Voxel resolution in studs
    chunkSize = 64           -- Chunk size for processing
}

local result = CaveGenerator.generateCaves(terrain, region, settings)
```

### Preset Configurations

```lua
-- Use built-in presets for immediate good results
CaveGenerator.Presets = {
    SMALL_TEST,        -- Good for development and testing
    DENSE_CAVES,       -- Dense cave network
    BIG_CAVERNS,       -- Large open spaces
    FAST_GENERATION    -- Performance optimized
}

-- Example usage
local result = CaveGenerator.generateCaves(terrain, region, CaveGenerator.Presets.DENSE_CAVES)
```

## 🎮 Examples

### Basic Cave Generation

```lua
local CaveExamples = require(script.CaveGenerationExample)

-- Generate caves at origin
CaveExamples.generateBasicCaves(workspace.Terrain)

-- Generate at specific position
CaveExamples.generateBasicCaves(workspace.Terrain, Vector3.new(100, -64, 100))
```

### Custom Cave System

```lua
local customSettings = {
    caveThreshold = 0.35,     -- Slightly easier to form caves
    caveScale = 0.025,        -- Smaller cave features
    tunnelScale = 0.02,       -- Smaller tunnels
    chamberScale = 0.06,      -- Medium chambers
    minDepth = -30,           -- Caves closer to surface
    generateStalactites = true,
    waterLevel = -70
}

CaveExamples.generateCustomCaves(workspace.Terrain)
```

### Performance Testing

```lua
-- Quick test for development
CaveExamples.generateQuickTest(workspace.Terrain)

-- Clear test area
CaveExamples.clearTestArea(workspace.Terrain)
```

## 🔧 Algorithm Details

### Core Cave Generation Approach

1. **3D Density Field**: Creates a continuous 3D field that determines cave vs rock
2. **Multi-Scale Noise**: Combines large chambers, medium tunnels, and small details
3. **Connectivity Check**: Ensures each cave voxel connects to at least 2 neighbors
4. **Depth-Based Probability**: More caves at medium depths, fewer near surface/bottom
5. **Chunk Processing**: Efficiently processes terrain in chunks using `WriteVoxels`

### Noise Combination Strategy

```lua
-- Large-scale chambers (big open spaces)
local chambers = noiseGen:simplex3D(x * chamberScale, y * chamberScale, z * chamberScale)

-- Medium-scale tunnels (connecting passages)
local tunnels = noiseGen:simplex3D(x * tunnelScale, y * tunnelScale * 0.5, z * tunnelScale)

-- Small-scale detail (roughness and variation)
local detail = noiseGen:simplex3D(x * detailScale, y * detailScale, z * detailScale)

-- Key: Use MAX to create connections, not addition
local caveValue = math.max(chambers * 0.7, tunnels * 0.8) + detail * 0.2
```

### Connectivity Filtering

The system checks each potential cave voxel to ensure it connects to at least 2 neighboring cave voxels, preventing isolated floating rocks while allowing natural cave endpoints.

## 🎯 Quality vs Performance

### High Quality
```lua
{
    resolution = 4,           -- Higher resolution
    chunkSize = 64,           -- Moderate chunks
    generateStalactites = true,
    caveScale = 0.025         -- Detailed features
}
```

### High Performance
```lua
{
    resolution = 8,           -- Lower resolution
    chunkSize = 128,          -- Larger chunks
    generateStalactites = false,
    caveScale = 0.035         -- Simpler features
}
```

## 🛠️ Utility Functions

```lua
-- Create test regions easily
local region = CaveGenerator.createTestRegion(centerPos, size)

-- Clear terrain for testing
CaveGenerator.clearTerrain(terrain, region)

-- Simple generation with good defaults
local result = CaveGenerator.generateCaves(terrain, region)
```

## ⚠️ Best Practices

### For Good Results
1. **Start with defaults** - They're tuned to work well immediately
2. **Use presets** - Try different presets before custom settings
3. **Test small first** - Use small regions for experimentation
4. **Check connectivity** - Lower thresholds create more connected caves
5. **Mind the depth** - Set appropriate minDepth/maxDepth for your world

### Performance Guidelines
1. **Start small** - Test with 64x64x64 regions first
2. **Adjust resolution** - Use 8-stud resolution for large areas
3. **Use larger chunks** - 128-stud chunks for better performance
4. **Disable features** - Turn off stalactites for performance-critical scenarios

## 🎉 What's New

This is a complete rewrite focused on:
- **Simplicity over complexity** - Removed unnecessary abstractions
- **Visual quality** - Caves that actually look like caves
- **Immediate results** - Good defaults that work out of the box
- **Clean connectivity** - No more floating rocks or disconnected segments
- **Easy configuration** - Simple settings that make sense

The old complex 5-stage system has been replaced with a focused approach that produces beautiful caves with minimal configuration.