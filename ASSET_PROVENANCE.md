# Asset provenance

This log records production assets added to the public clean-room project. Reference images define internal visual consistency only; they are not copied into new compositions. Generated assets must still pass in-game visual, performance, and export QA before release.

## 2026-08-22 — Stage 1 independent environment backgrounds

Tool: OpenAI built-in `image_gen` (`stylized-concept` workflow).

Reference role: `assets/backgrounds/ruined_city_stage.png` was supplied only as an internal style and production-quality reference. Both outputs requested completely new scene geometry and composition, original IP, no protected characters or locations, no logos, no text, and no watermark.

### `assets/backgrounds/flooded_courtyard.png`

- Dimensions: 1672×941 PNG.
- SHA-256: `fc804d8fea7cfbc4085c922ce7f2233af827c421f8bab1b077c97d92d4c72137`.
- Final prompt:

```text
Use case: stylized-concept
Asset type: 16:9 side-scrolling arcade beat-'em-up game environment background for Wildland Strike, Flooded Courtyard scene
Input images: Image 1 is a style and production-quality reference only; create a completely new scene and composition, do not copy its buildings or layout
Primary request: an original overgrown flooded civic courtyard after ecological collapse, with shallow reflective water channels, cracked stone terraces, a broken monumental fountain, vine-covered concrete arcades, storm drains, scattered sandbags, and distant jungle-swallowed towers
Style/medium: polished hand-authored 1990s arcade pixel art, crisp deliberate pixel clusters, limited but rich color ramps, detailed environmental storytelling, cohesive with Image 1 while remaining original IP
Composition/framing: wide orthographic side-view gameplay backdrop, camera level and horizon compatible with a belt-scrolling brawler; the lower 38 percent must remain a broad mostly empty traversable combat lane with readable ground perspective and no obstacles blocking fighters; foreground framing only at extreme bottom corners; strong depth layers and parallax-friendly silhouettes
Lighting/mood: humid late-sunset light after rain, cooler teal shadows and warm amber highlights, atmospheric depth, tense but adventurous
Color palette: deep teal, wet slate, moss green, muted ochre, selective amber reflections
Constraints: environment only; no people, creatures, vehicles, readable text, logos, UI, watermarks, copyrighted characters, or recognizable franchise locations; no blur, no painterly brushwork, no fake screenshot HUD; maintain crisp pixel-art edges and a clean gameplay lane
```

### `assets/backgrounds/processing_plant.png`

- Dimensions: 1672×941 PNG.
- SHA-256: `ddfb2863cd9f1fa71e86ad52d49b055ea2af0a3758f532cc7bc3e6a0691472ca`.
- Final prompt:

```text
Use case: stylized-concept
Asset type: 16:9 side-scrolling arcade beat-'em-up game environment background for Wildland Strike, Processing Plant scene and Stage 1 boss arena
Input images: Image 1 is a style and production-quality reference only; create a completely new industrial scene and composition, do not copy its buildings or layout
Primary request: an original abandoned biomass processing plant reclaimed by jungle, with massive rusted pipes, concrete loading bays, smashed roller doors, hazard-striped platforms, dormant pressure tanks, dangling cables, broken work lights, steam vents, and distant refinery silhouettes
Style/medium: polished hand-authored 1990s arcade pixel art, crisp deliberate pixel clusters, limited but rich color ramps, dense industrial material detail, cohesive with Image 1 while remaining original IP
Composition/framing: wide orthographic side-view boss-arena backdrop compatible with a belt-scrolling brawler; the lower 40 percent must be a broad mostly empty flat combat lane with readable ground perspective and no central machinery blocking fighters; strong symmetrical framing around an intimidating central loading-bay opening, layered depth, parallax-friendly silhouettes, foreground details restricted to extreme lower corners
Lighting/mood: hot dusk shifting toward night, deep burgundy and steel shadows with sodium-orange industrial lamps, thin steam haze, ominous final-arena tension
Color palette: charcoal steel, oxidized copper, dark crimson, dirty concrete, sparse amber lights, restrained jungle green
Constraints: environment only; no people, creatures, vehicles, readable text, logos, UI, watermarks, copyrighted characters, or recognizable franchise locations; no blur, no painterly brushwork, no fake screenshot HUD; maintain crisp pixel-art edges and a clean gameplay lane
```

Verification: both images were imported through Godot, referenced by typed Stage 1 scene data, inspected at 1280×720 gameplay scale in the Web export, and included in the four-enemy performance baseline before commit.

## 2026-08-22 — Ranger 24-frame animation sheet

Tool: OpenAI built-in `image_gen` image-edit workflow, followed by deterministic chroma-key-to-alpha conversion with local FFmpeg.

Reference role: the existing original-IP `assets/sprites/ranger_sheet.png` supplied Ranger's costume, proportions, palette, and arcade rendering direction. No external franchise image or ROM-derived frame was used.

### `assets/sprites/ranger_sheet_v2.png`

- Dimensions: 1536×1024 RGBA PNG, exact 6×4 equal-cell layout.
- SHA-256: `e955b7d30b420f77ec8e0443436b405b44e5e694d18a7e452b8c0ae6594fcd61`.
- Intermediate chroma source SHA-256: `b75620aa2d0a220e811525101bd402e3cb35f103c80c57a5d53db12e66a4cb1d`.
- Character/action prompt:

```text
Edit and expand the supplied original Wildland Strike Ranger sprite artwork into a production-ready 2D arcade beat-em-up animation sheet. Keep the exact same original character identity: athletic dark-haired male ranger, white rolled-sleeve shirt, red neckerchief, blue torn cargo jeans, brown boots and gloves. Preserve the same late-1980s/early-1990s hand-pixeled arcade style, limited warm palette, crisp dark outlines, strong readable silhouette, consistent anatomy and identical costume in every frame. Create an exact 6-column by 4-row grid, one centered full-body side-view sprite per equal cell, all facing screen-right, consistent foot baseline and scale, no overlap. Row 1: two breathing idle frames, four distinct walk/run-cycle frames. Row 2: jab startup, jab contact, cross contact, heavy uppercut, shoulder rush, spinning defensive special. Row 3: jump rise, airborne kick, descending dive kick, grab hold stance, standing hurt recoil, hard knockdown falling. Row 4: defeated on ground, get-up transition, machete attack, pistol firing, victory fist raise frame 1, victory fist raise frame 2. Transparent background only in every cell; no gradient, no scenery, no labels, no grid lines, no shadows outside the sprites, no text, no extra characters, no cropped limbs. Sprite sheet must be cleanly sliceable into 24 equal cells.
```

- Final isolation prompt:

```text
Preserve all 24 Ranger sprites pixel-for-pixel in their existing exact 6-column by 4-row positions, poses, scale, costume colors, motion arcs, weapon details, and 1536x1024 canvas. Change only the empty checkerboard background: replace every background pixel between and around the sprites with one perfectly uniform, flat chroma-key color RGB #FF00FF (pure magenta), with no checker pattern, noise, gradient, shadow, labels, grid, or texture. Do not recolor any part of the character sprites. Keep crisp arcade pixel-art edges and no extra objects.
```

Verification: the imported texture retains alpha, all 24 frame coordinates are covered by deterministic tests, no chroma spill or cell bleed is visible at 1280×720 Web gameplay scale, and the four-enemy benchmark includes the animated ambience layer.
