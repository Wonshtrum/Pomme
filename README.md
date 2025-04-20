# 🍏 Pomme

Pomme is an experimental, early-stage, vanilla-style Minecraft shader that reimagines depth effects. Inspired by Parallax Occlusion Mapping (POM) but designed to overcome its limitations, Pomme extrudes and carves faces to simulate actual 3D geometry.

Unlike classic POM, which flattens at sharp angles and sharply stops at face edges, Pomme maintains its depth effect consistently, offering a more immersive visual style.

## ✨ Features

Pomme can extrude the pixels of any surface, independent of the view angle. It handles intersecting geometry surprisingly well: shared edges between blocks, block-entity collision, and entity-entity intersections should render correctly in most cases.

Currently supports:
- Blocks
- Tile entities
- Entities (including players and items)
- Held items

## ⚠️ Known Limitations

Pomme is still in proof-of-concept territory.
It makes heavy use of geometry shaders, which may cause significant performance issues depending on your GPU.

Current issues:
- “Layered effects” aren’t rendered (enchantment glint, fog, blindness...)
- Sloped liquids aren’t extruded correctly
- Torches can break extrusion when viewed head-on
- Transparent block culling (glass, water) is view-direction dependent
- Some single-plane models render oddly (sunflowers, stonecutter blade, rails...)
- Various rendering glitches (potted plants, tall seagrass, calibrated sculk sensors...)
- Extrusion is based on texture luminance, not actual height maps (yet)
