# nlib - Cave Generation Library

A comprehensive procedural cave generation system for Roblox, featuring three-tier generation architecture for creating realistic, interconnected cave networks.

## Features

### 🏗️ Three-Tier Generation System
- **Tier 1 (Foundation)**: Main chambers, connecting passages, vertical shafts
- **Tier 2 (Complexity)**: Branches, sub-chambers, collapse rooms, hidden pockets, tectonic features
- **Tier 3 (Micro-features)**: Fracture veins, pinch points, seam layers, surface details

### 🎮 Easy-to-Use API
- `generateQuickCave()` - Simple cave generation with default settings
- `generateAdvancedCave()` - Full-featured cave with all tiers enabled
- `generateTestCave()` - Debug cave with fixed seed for testing
- `generateCave()` - Full control over generation parameters

### 🔧 Advanced Features
- **Performance Monitoring**: Track generation time, memory usage, feature counts
- **Progress Reporting**: Real-time progress callbacks with detailed status
- **Error Handling**: Graceful failure recovery with detailed error messages
- **Configuration System**: Extensive customization options for all generation aspects
- **Connectivity Analysis**: Ensures all cave features are properly connected
- **Memory Management**: Automatic cleanup and garbage collection

## Quick Start

```lua
-- Basic cave generation
local InitializeCaveGeneration = require(game.ServerScriptService.InitializeCaveGeneration)

-- Generate a simple cave
local result = InitializeCaveGeneration.generateQuickCave(
    Vector3.new(0, -25, 0),  -- Position
    Vector3.new(100, 50, 100) -- Size
)

if result.success then
    print("Cave generated with", result.features.chambers, "chambers!")
else
    warn("Generation failed:", result.errorMessage)
end
```

## Repository Structure

```
src/
├── ServerScriptService/
│   ├── InitializeCaveGeneration.lua    # Main orchestration script 🚀
│   ├── ExampleCaveGeneration.lua       # Usage examples
│   └── NoiseLib.lua                    # Noise generation library
└── ReplicatedStorage/
    └── CaveGen/
        ├── Core.lua                    # Data management and utilities
        ├── Config.lua                  # Configuration settings
        ├── Tier1.lua                  # Foundation features
        ├── Tier2.lua                  # Complexity features
        └── Tier3.lua                  # Micro-features
```

## Installation

1. Copy the `src` folder structure to your Roblox place
2. Require the `InitializeCaveGeneration` module from ServerScriptService
3. Start generating caves!

## Documentation

- **[API Documentation](CAVE_GENERATION_API.md)** - Complete API reference and usage guide
- **Examples** - See `ExampleCaveGeneration.lua` for comprehensive usage examples

## Configuration

The system is highly configurable. You can customize:

- **Noise Parameters**: Control cave shape and structure
- **Feature Density**: Adjust how many chambers, passages, etc. are generated
- **Performance Settings**: Tune generation speed vs quality
- **Debug Options**: Enable visualization and detailed logging
- **Terrain Settings**: Material types, resolution, chunk sizes

```lua
local customConfig = {
    Core = {
        seed = 12345,  -- Reproducible generation
        logLevel = "INFO"
    },
    Tier1 = {
        mainChambers = {
            densityThreshold = 0.15,  -- More chambers
            minSize = 8,
            maxSize = 24
        }
    }
}

local result = InitializeCaveGeneration.generateCave(region, customConfig)
```

## Performance

The system is optimized for Roblox's constraints:

- **Chunked Processing**: Large caves are processed in chunks to prevent timeout
- **Yielding**: Automatic yielding during long operations
- **Memory Management**: Efficient voxel buffer handling
- **Timeout Protection**: Configurable timeouts with graceful failure
- **Progress Reporting**: Monitor generation progress in real-time

Typical performance:
- **Quick Cave** (50x30x50): ~5-15 seconds
- **Advanced Cave** (100x60x100): ~30-90 seconds
- **Large Cave** (200x100x200): ~2-5 minutes

## Error Handling

The system includes robust error handling:

```lua
local result = InitializeCaveGeneration.generateCave(region, config, {
    timeout = 60,
    progressCallback = function(progress, stage, details)
        print(string.format("%.1f%% - %s", progress * 100, stage))
    end
})

-- Check results
if result.success then
    print("Generated", result.features.chambers, "chambers")
else
    warn("Failed:", result.errorMessage)
    -- Partial results may still be available
    print("Partial features:", result.features.chambers)
end
```

## Examples

See `ExampleCaveGeneration.lua` for complete examples including:

1. **Simple Quick Cave** - Basic generation with defaults
2. **Custom Configuration** - Tailored cave parameters  
3. **Advanced Cave** - All features enabled with progress reporting
4. **Test Cave** - Fixed seed for debugging
5. **Error Handling** - Demonstrating failure recovery

## Contributing

When contributing to this library:

1. Follow the existing code style and structure
2. Add appropriate logging and error handling
3. Update documentation for any API changes
4. Test with various configurations and region sizes
5. Consider performance impact of changes

## Version History

- **v1.0.0** - Initial release with full three-tier generation system
- Comprehensive API with error handling and performance monitoring
- Complete documentation and examples

## License

This library is provided as-is for educational and development purposes.

---

**Need Help?** Check the [API Documentation](CAVE_GENERATION_API.md) or examine the examples in `ExampleCaveGeneration.lua`.