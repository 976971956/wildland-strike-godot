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
