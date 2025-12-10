# Material Generator

A Godot addon that auto-generates StandardMaterial3D resources from folders containing texture maps.

## Installation

1. Copy the `addons/material_generator` folder to your project's `addons/` directory
2. Enable the plugin in Project Settings → Plugins

## Usage

The Material Generator panel appears in the bottom dock. Point it to a folder containing texture files, and it will create a `.tres` material with the textures automatically assigned.

### Supported Texture Types

The addon recognizes common texture naming patterns:

- **Albedo/Diffuse**: `basecolor`, `albedo`, `diffuse`
- **Metallic**: `metallic`
- **Roughness**: `roughness`
- **Normal**: `normal`, `normalogl`, `normalgl`
- **Height**: `height`, `heightmap`
- **Ambient Occlusion**: `ambientocclusion`, `ao`
- **Emission**: `emission`

File names are case-insensitive and work with underscores or hyphens (e.g., `base_color.png`, `Base-Color.png`).

### Modes

- **Create**: Generate new materials (skips if file exists)
- **Overwrite**: Replace existing materials completely
- **Merge**: Update existing materials while preserving other settings

## Example

For a folder structure like:
```
textures/wood/
  ├─ wood_albedo.png
  ├─ wood_normal.png
  └─ wood_roughness.png
```

The addon generates `textures/wood.tres` with all textures assigned to the appropriate StandardMaterial3D properties.

## License

MIT


