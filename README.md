# Batman-Style Grappling Hook

A FiveM resource that adds a Batman-inspired grappling hook mechanic to your server.

## Required Resources
Before installing this resource, make sure you have:
1. [Grapple Gun Model](https://github.com/steelzzeu/Grappling-Hook-Model/releases/tag/fivem) - For the weapon model
2. [interact-sound](https://github.com/plunkettscott/interact-sound) - For sound effects

## Installation

1. Download and install the required resources first
2. Copy the `SteelzzGrapplingHook` folder to your server's `resources` directory
3. Add the following to your `server.cfg`:

```cfg
ensure grapplegun
ensure interact-sound
ensure SteelzzGrapplingHook
```

## Usage Instructions

### Controls
- **LMB (Left Mouse Button)** - Fire grappling hook (max range: 250 units)
- **F** - Release/Cancel grapple
- **R** - Reload grapple charges
- You have 5 grapple charges before needing to reload

### Features
- Batman-style UI showing grapple charges and status
- Visual targeting reticle with distance indicator
- Extended range of 250 units for long-distance grappling
- Smoke effects and particles when grappling
- Momentum-based movement system
- 10-second cooldown between uses

### Tips
- Look at a valid surface within 250 units to grapple
- The targeting reticle will show if a surface is in range
- You can't grapple while in vehicles
- Release early with F to maintain momentum
- Reload when out of charges using R

## Support
If you encounter any issues or need help, please create an issue on the repository. 
