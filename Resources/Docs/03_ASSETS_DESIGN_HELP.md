## Suggested Prompts



### Sprite



```
Use $generate2dsprite to create a 3x3 idle for an ultimate earth titan.
```



```
Use $generate2dsprite to create a side-view lightning knight attack animation.
```



```
Use $generate2dsprite to create a late-Sengoku player_sheet for a wandering fire swordsman.
```



```
Use $generate2dsprite to create a wizard spell bundle with cast, projectile, and impact sprites.
```



### Map



```
Use $generate2dmap to create a small fixed-screen pixel-art battle arena with simple collision.
```



```
Use $generate2dmap to create a top-down RPG forest shrine map. Use a layered raster pipeline, a 3x3 prop pack for small environmental props, precise collision, encounter grass zones, a rest point, and actors that can walk in front of and behind tall props.
```



```
Use $generate2dmap to create a Godot-editable RPG map with separated props, encounter grass Area2D zones, collision StaticBody2D blockers, exit zones, and a debug player scene.
```



## What You Get



For a typical sprite sheet output:

- `raw-sheet.png`
- `raw-sheet-clean.png`
- `sheet-transparent.png`
- Frame PNGs
- `animation.gif`
- `prompt-used.txt`
- `pipeline-meta.json`

For player walk sheets, you also get direction strips and per-direction GIFs.

For a map output, the result depends on the chosen pipeline:

- Single baked map: complete map image, optional prompt file, and optional collision metadata.
- Layered raster map: base map, dressed reference, prop folders or prop-pack extraction manifest, prop placement metadata, collision/zones metadata, and flattened layered preview.
- Godot editable map: tileset/prop assets, scene files, layer metadata, collision/zones, exits, and debug player setup.

## Notes



- Best results come from prompts that clearly specify view, action, and desired motion style.
- Large creatures often work better as `3x3 idle`.
- Small spells and projectiles often work better as `1x4`, `2x2`, or `2x3`.
- Layout guides are useful for fixed-frame action sheets and prop packs, but they are not always better for compact attack sheets.
- For commercial projects, prefer original characters or IP that you control.