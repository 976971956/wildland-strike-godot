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

## 2026-08-22 — Stage 1 enemy eight-state animation sheets

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by deterministic chroma-key-to-alpha conversion and connected-component frame isolation.

Reference role: only existing original-IP Wildland Strike enemy art and the project's established arcade rendering direction were used to define costume families, scale, palette, and silhouette. No external franchise screenshot, ROM asset, character, logo, or traced animation frame was supplied. A first multi-row humanoid attempt was rejected during Web QA because figures crossed nominal cell boundaries; only its valid raider row was retained, while brute and boss were regenerated as isolated strips.

### Final files

- `assets/sprites/raider_sheet_v2.png`: 2560×320 RGBA, 8×1; SHA-256 `85f5b844142e71acc5ee667c2b45b78d19ea307936f15013329b39581bd9ddfd`; intermediate source SHA-256 `8283a342956f637992f5b7eee418987dc54c7c7bccd50804210a30e2a3539d14`.
- `assets/sprites/brute_sheet_v2.png`: 2560×320 RGBA, 8×1; SHA-256 `3e78029f915dcd9b7b593400290665b2503b4a035acc2960aa5bce4f5f255f50`; intermediate source SHA-256 `ab51718ef99bf3113f2872f85785ff52e63e2d02fbbb54993c4169b08aaf3f8d`.
- `assets/sprites/raptor_sheet_v2.png`: 2560×320 RGBA, 8×1; SHA-256 `d36cb5c7b8ff79bf0402d4bd890d2271011717659cbd94ab47715a0ff51198af`; intermediate source SHA-256 `9ad9eb44b8f5f7d5caa81d90ffcf28004f51190c7f47f089809b429c1bf6e0b5`.
- `assets/sprites/boss_sheet_v2.png`: 2560×320 RGBA, 8×1; SHA-256 `d0923c77bd51c848c2607aa454437d3ccf8ecac44b4d53c8cd7f826927c1af77`; intermediate source SHA-256 `727c02e3947ebd64b2befa73a55ca2f443e160c52baf43536390d99e877f115c`.

Generation direction for every strip required one consistent original character, late-1980s/early-1990s hand-pixeled arcade rendering, crisp dark outlines, a flat pure-magenta isolation background, no scenery/text/logos, and eight readable side-view actions in order: two idle/breathing poses, two locomotion poses, attack telegraph, attack contact or burst, hurt recoil, and defeated/knockdown. The raider is an athletic green-vest fighter; the brute is a bald heavyweight in a mustard vest and armored gauntlets; the raptor is an original green/orange neutral creature with crouch, run, pounce, hurt, and down silhouettes; Warden Rourke is a white-haired armored commander with a long red coat and heavy strike poses.

Post-processing isolated the eight largest connected actors from each generated strip, discarded pixels belonging to neighboring actors, preserved each pose's relative vertical placement, applied one uniform nearest-neighbor scale per character, and centered every result in an exact 320×320 transparent cell. This deterministic normalization was added after the first equal-width crop still exposed neighboring limbs in the actual Web renderer.

Verification: all four imported textures retain alpha and divide exactly into eight cells; grunt, hunter, brute, raptor, and boss use state-driven idle, locomotion, telegraph/windup, contact/burst, hurt, and defeat indices. A no-damage `roster_preview=1` Web fixture displays all five archetypes simultaneously without cross-faction combat contaminating the visual test. The final 1280×720 roster and both boss phases were inspected for cell bleed, crop loss, scale, silhouettes, tint, and depth ordering. The roster sample averaged 119.96 FPS over 300 frames with zero frames above 20 ms or 33 ms.

## 2026-08-22 — Mara, Kestrel, and Atlas 24-frame animation sheets

Tool: OpenAI built-in `image_gen` generation and precise-background-edit workflows, followed by deterministic FFmpeg chroma-to-alpha conversion and the project-local `tools/normalize_sprite_sheet.gd` per-cell connected-component cleanup.

Reference role: only the existing original-IP `assets/sprites/ranger_sheet_v2.png` was supplied as a production-format reference for the 6×4 grid, scale, action order, and arcade rendering density. Each output explicitly requested a new face, body, costume, silhouette, palette, and identity. No franchise screenshot, ROM asset, external character, logo, or traced animation frame was used. The initially generated checkerboard-background files were rejected and are not retained in the repository.

### Final files

- `assets/sprites/mara_sheet_v2.png`: 1536×1024 RGBA, 6×4; SHA-256 `46ef9dec67079f56a55c20466358ed4518ba9438d3446263151818c5971d96e8`; intermediate chroma source SHA-256 `5222917e752d037e5742a2aa64651fcd857a3af85c32304e49d7fea707e41f44`.
- `assets/sprites/kestrel_sheet_v2.png`: 1536×1024 RGBA, 6×4; SHA-256 `9536037ba1048349e6962db60a1b5f96ea877676e9a191014da1af848847d759`; intermediate chroma source SHA-256 `9b7a69d414e4a81bd7d06129cc498f43ea42927261dbcc42bfd97dfd542d566b`.
- `assets/sprites/atlas_sheet_v2.png`: 1536×1024 RGBA, 6×4; SHA-256 `ea90a6815e546f893dc6a1e744c4617d955a1f1ca3ab0d71e10977e907fa6eb4`; intermediate chroma source SHA-256 `b0de4ccf43a7726ebeea43360f62fad4fde02d245df87c440003072c08b74a13`.

Shared final generation direction:

```text
Use case: stylized-concept
Asset type: production 2D arcade beat-'em-up character animation sprite sheet for Wildland Strike
Input images: Image 1 is an original-IP Ranger sheet used only as the exact production-format, grid, scale, pixel-rendering, and action-order reference; create a completely new character and do not preserve or copy Ranger's face, hair, costume, body, or colors
Style/medium: polished hand-authored late-1980s/early-1990s arcade pixel art, crisp deliberate pixel clusters, a limited character-specific palette, strong dark outlines, readable belt-scrolling brawler silhouettes, and the same rendering density and full-body scale as Image 1
Composition/framing: exact 6-column by 4-row grid on a 1536x1024 canvas, one centered full-body side-view sprite in each equal 256x256 cell, every action facing screen-right, consistent foot baseline and uniform scale, no overlap or cell bleed
Action order: row 1 = two breathing idle frames and four movement frames; row 2 = attack startup/contact chain, launcher, rush, and defensive special; row 3 = jump rise, air kick, dive, grab, hurt, and knockdown; row 4 = defeated, get-up, machete, pistol, and two victory poses
Constraints: original character and original IP only; exactly 24 sprites; consistent identity/costume/proportions; cleanly sliceable equal cells; no scenery, text, logos, watermark, copyrighted characters, cropped limbs, duplicate poses, or objects crossing cell boundaries
```

Character-specific direction:

- Mara: athletic female field technician with short tied copper hair, slate-blue cropped mechanic jacket, dark work shirt, reinforced blue-gray utility trousers, teal gloves, compact tool harness, and rugged boots; blue/teal/copper palette, wrench-hand launcher, tool-raise victory.
- Kestrel: lean female aerial scout with short swept silver hair, plum flight jacket, orange scarf, fitted charcoal tactical trousers, orange wraps, and lightweight high boots; plum/charcoal/orange palette, rising-knee launcher, long aerial kick, acrobatic get-up.
- Atlas: massive male power grappler with shaved head, short auburn beard, rust-red sleeveless utility vest, charcoal undershirt, oversized amber gauntlets, heavy dark cargo trousers, and steel-toe boots; rust/charcoal/amber palette, hammerfist chain, body kick, crushing grab, double-fist victory.

Isolation edit changed only the empty generated checker background to a uniform chroma-magenta field while preserving the sprites and exact grid. FFmpeg converted that field to alpha. Browser inspection of a query-gated 24-cell fixture then identified both texture-filter sampling and disconnected neighboring-pose fragments. Nearest-neighbor sampling removed atlas-edge interpolation; the retained normalizer removed weak alpha, components below 128 pixels, and independent components farther than an eight-pixel expansion of the main character while preserving nearby weapon flashes and motion arcs.

Verification: all four hero resources validate their own texture/grid metadata. Each final sheet retains alpha, is exactly divisible into 24 equal cells, and every cell passes deterministic opaque-silhouette and transparent-gutter checks. Mara, Kestrel, and Atlas were each inspected across all 24 exported-Web cells after cleanup; the final real-sprite character-select screen was also inspected. The animation and selection fixtures average about 120 FPS across 300 frames with zero frames above 20 ms and no console errors.

## 2026-08-22 — Dinosaur ecosystem animation sheets

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/split_dinosaur_atlas.gd` black-key, connected-component isolation, nearest-neighbor normalization, and transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, or traced animation frame was supplied. The prompt referenced only the original Wildland Strike name and the project's general CPS-era arcade rendering direction.

### Final files

- `assets/sprites/compy_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `d6bdb8d8c511aa34291f77743e4326e988e6831f7255171d6c0e112de470b73d`.
- `assets/sprites/ankylosaur_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `26f4db559f9735b132d14407ab24df8d0fbc1bb98f0b4ec67a8f465f08af296e`.
- `assets/sprites/triceratops_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `65c789f8d01887a67d240db729ea256a64f8154db172dc8dc28d1a555b290b6d`.
- Archived three-row source: `assets/sprites/dinosaur_ecosystem_source.png`; SHA-256 `7b2d226b91ef6808318013f73a98e4e56a7a81902b42aa845ddb938cc1b97443`. It is excluded from runtime exports.

Generation prompt:

```text
Create one production-ready transparent PNG sprite atlas for an original 1990s arcade beat-em-up named Wildland Strike. EXACT layout: 8 columns by 3 rows, every cell isolated with generous transparent gutters, no grid lines, no labels, no text, no background, no shadows, no cropped limbs, no object crossing a cell boundary. Each row is one consistent dinosaur species facing LEFT in all eight poses, with consistent proportions/colors within its row. Row 1: small agile compsognathus-like pack hunter, teal and sand palette; poses idle alert, sleep curled, run, bite attack, hurt recoil, enraged roar, knockdown, defeated. Row 2: heavy ankylosaur-like armored dinosaur, slate blue and ochre palette; poses idle, sleep, walk, tail-club attack, hurt recoil, enraged roar, knockdown, defeated. Row 3: large triceratops-like charging dinosaur, rust red and cream palette; poses idle, sleep, walk, horn charge attack, hurt recoil, enraged roar, knockdown, defeated. High quality clean pixel art matching CPS-era arcade sprites, detailed lighting, crisp silhouettes, consistent pixel density, no anti-aliased blurry edges. Keep every complete creature centered independently in its cell. Transparent background is mandatory.
```

The generated source encoded the empty field as opaque black despite the requested transparency and did not respect equal column widths. It was rejected as a runtime atlas. The retained splitter keys only exact/near-exact black background pixels, discovers connected opaque components independently within each species row, selects and x-sorts the eight largest complete actors, scales each with nearest-neighbor interpolation, and centers it on a transparent 320×320 cell. This produces deterministic, cleanly sliceable output while preserving dark non-black outlines.

Verification: all three new textures and the existing raptor texture are unique, retain alpha, and divide into eight exact cells. Every typed definition validates neutral faction, grab immunity, behavior, wake radius, enrage threshold, multipliers, and atlas metadata. The exported 1280×720 four-species fixture was inspected for silhouettes, sleeping/enraged readability, scale, gutters, and crop loss; its final sample averaged 119.99 FPS over 300 frames with zero frames above 20 ms or 33 ms.

## 2026-08-22 — Human specialist and elite roster sheets

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/split_enemy_roster_atlas.gd` black-key, connected-component isolation, nearest-neighbor normalization, and transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, or traced animation frame was supplied. The prompt used only the original Wildland Strike name and a general 1990s arcade pixel-art direction.

### Final files

- `assets/sprites/hunter_sheet.png`: SHA-256 `44aca98bd2cb32201bd2d725b7a943ebd93eca703a95912e81cc9d511f7b4c48`.
- `assets/sprites/knife_raider_sheet.png`: SHA-256 `902236f19926bb8a68f610abcae86b30df35827862428928967c59c5c2503aad`.
- `assets/sprites/demolitionist_sheet.png`: SHA-256 `3228eabb571fb4bc745bbe1792f19a74282cdf7a325a8c1c18f2448d6f0f2c87`.
- `assets/sprites/shield_guard_sheet.png`: SHA-256 `7682abfe8756ad04f7a1b5919fc9a378b0204b70ff96e26d7f4248304b45bbee`.
- `assets/sprites/elite_enforcer_sheet.png`: SHA-256 `71070d314f6571228556864e57f13d21b167f4140021d041c131cff7fd4c65bb`.
- `assets/sprites/elite_blade_sheet.png`: SHA-256 `9e060b4ab8567b4508a8fb9692c60c12a4e3b2065384349f8603a88d593d653f`.
- `assets/sprites/elite_bombardier_sheet.png`: SHA-256 `e78b6b0f18840e598d49cb21be781535cc577e1d6a6bfa7a1dd38986e297abfa`.
- `assets/sprites/elite_bulwark_sheet.png`: SHA-256 `b3cae34696686786b1182975d2dab2f0ebd8aa74fabb7973b9971ce282cb4d31`.
- Archived 8×8 source: `assets/sprites/enemy_roster_source.png`; SHA-256 `e88439582edf6ff3d5438a955645b5449a46e4bf4b9a5a6d9a2b9ec4a685cecf`. It is excluded from runtime exports.

Every final runtime file is a 2560×320 RGBA eight-state strip with transparent gutters.

Generation prompt:

```text
Original clean-room pixel-art enemy sprite atlas for the original game Wildland Strike. 2560x2560 square canvas, pure opaque black background. EXACTLY 8 columns and 8 rows, generous black gutters, no cell overlap, no text, no logos, no UI, no scenery, no copyrighted characters. One consistent full-body human enemy per row, facing left, feet on a consistent baseline. The 8 columns per row are: idle, guard, run A, run B, signature attack, hurt, knockdown/get-up, defeated. Crisp hard-edged 32-bit arcade pixel art; each full character and weapon entirely inside its cell.
Rows: (1) lean slate-blue long-coat pistol hunter; (2) agile rust-orange jacket bandana hooked-knife raider; (3) yellow-black hazard-vest gas-mask grenade demolition specialist; (4) teal industrial armor rectangular riot-shield and stun-baton controller; (5) massive crimson plated elite enforcer; (6) white-haired deep-magenta elite dual-blade duelist; (7) orange armored sealed-mask elite bombardier with canisters; (8) dark navy and gold elite bulwark with tower shield and shock mace. Every row must have a visibly distinct silhouette and weapon language. At least 20 pixels of pure black separation at all cell edges.
```

The generated service output was 1254×1254 RGB with a slightly lifted opaque black field rather than the requested exact dimensions. It was retained only as reproducible source, never used directly at runtime. The splitter first converts to RGBA, removes near-black background pixels, finds the eight largest connected actors independently in each row, sorts by x position, and reconstructs normalized transparent 320×320 cells. Separate muzzle flashes and distant particles are intentionally discarded so no detached effect can replace a character component.

Verification: all eight outputs retain alpha, are unique, divide into eight exact cells, and were inspected individually before integration. The exported 1280×720 ten-character fixture was rejected once because its banner covered the upper row, then rebuilt with an unobstructed two-row layout. The accepted fixture exposes standard/elite identity, weapons, shield guard bars, and elite rank cues at 119.997 FPS over 300 frames with zero frames above 20 ms or 33 ms and no browser warnings/errors.

## 2026-08-22 — Flooded wilderness environments and Mirewarden Sable

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/build_flooded_wilderness_assets.gd` panel extraction, connected-component pose isolation, nearest-neighbor normalization, and transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, or traced animation frame was supplied. The prompts referenced only the original Wildland Strike name and a general late-1990s arcade rendering direction.

### Final files

- Archived three-panel environment source: `assets/backgrounds/flooded_wilderness_atlas_source.png`; 2048×768 RGB; SHA-256 `35e54dfc2cd724eb9cec94be932ce9442e41eccee379dfca37d32ac1c7bbf9e3`.
- `assets/backgrounds/flooded_cypress_approach.png`: 1672×941 RGB; SHA-256 `874cfd9c53472b2afa58334c8527e31a32550c7b5acdf11f8726d2428018900f`.
- `assets/backgrounds/flooded_research_camp.png`: 1672×941 RGB; SHA-256 `12e19987accc33a00f9fcb06ea62e80f5116d7aeaa27d1dcfa0e969a83dd9487`.
- `assets/backgrounds/ancient_spillway_arena.png`: 1672×941 RGB; SHA-256 `59a7d974777579b703eb611a30e08c34a4bf91261a4e70dce02d269760d1c549`.
- Archived Mirewarden source: `assets/sprites/mirewarden_source.png`; 2172×724 RGBA; SHA-256 `d7bd5e2243920bc6ddb8631bb33baa7f4d0b8a5a6ecc7979de0284d90963a2eb`.
- `assets/sprites/mirewarden_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `978013992a5e442e2e797c5c088c3828c24a310441f55f4cad94ca7a6895ee7f`.

Both archived source images are excluded from Web and iOS runtime exports.

Environment generation prompt:

```text
Use case: stylized-concept
Asset type: clean-room 2.5D side-scrolling arcade game background atlas
Primary request: create one ultra-wide image divided into exactly three equal vertical panels that form a continuous flooded wilderness journey: panel 1 a storm-flooded cypress approach with broken ranger boardwalk and distant lightning; panel 2 a half-submerged research camp with tilted watchtower, sandbags, supply pontoons and rushing water channels; panel 3 a dramatic ancient spillway arena under a waterfall with stone terraces and a wide open boss battleground.
Style/medium: polished late-1990s arcade beat-em-up environment art, crisp hand-painted pseudo-pixel rendering, original clean-room visual identity, strong silhouettes and readable depth layers.
Composition/framing: fixed side view, each panel 16:9, horizon and gameplay floor continuous across panel seams; keep the bottom 35 percent as a broad unobstructed walkable lane with shallow reflective water, no foreground objects that hide fighters.
Lighting/mood: blue-green monsoon dusk, warm amber camp lights in panel 2, pale waterfall mist in panel 3.
Color palette: deep teal, slate blue, moss green, wet stone, small amber accents.
Constraints: environment only; exactly three equal panels; no people, no dinosaurs, no characters, no UI, no text, no logos, no watermark, no copyrighted characters or franchise imagery; consistent camera and scale across all three panels.
```

Mirewarden generation prompt:

```text
Use case: stylized-concept
Asset type: original boss sprite action atlas for a 2.5D side-scrolling arcade beat-em-up
Primary request: one single horizontal strip containing exactly 8 equal square cells of the same original swamp warlord named MIREWARDEN SABLE: a massive weathered flood-rescue commander in dark teal waders and layered reed armor, orange rescue straps, scarred broad face, short gray-black hair, carrying an original heavy hydraulic harpoon-gauntlet on his right arm. Exact poses left to right: battle idle, heavy walk, gauntlet punch, harpoon windup telegraph, tidal ground smash, forward harpoon rush, hurt recoil, defeated fall.
Style/medium: crisp hand-painted pseudo-pixel arcade sprite art with hard readable silhouettes, detailed but clean, consistent proportions and costume in every frame, fully original clean-room character.
Composition/framing: exactly one centered full-body fighter per cell, side-facing to the left in every standing pose, feet aligned to a common baseline, generous transparent gutter around every silhouette, no overlap between cells, no cropped limbs or weapon.
Lighting/mood: cool rim light with small amber equipment accents.
Constraints: genuinely transparent background, exactly 8 cells in one row, same character identity and scale in all frames, no scenery, no floor, no shadows crossing cell boundaries, no text, no labels, no logos, no watermark, no copyrighted characters, no guns or franchise imagery.
```

The environment service output was 2048×768 rather than three independently sized runtime files. The deterministic builder rounds exact third boundaries, resizes each panel to the established 1672×941 scene contract, and leaves the broad combat lane intact. The Mirewarden output retained real alpha but did not center poses at equal mathematical intervals. The first equal-width crop was rejected because neighboring limbs crossed cell boundaries. The final builder discovers the eight largest eight-neighbor opaque components, sorts them by x position, scales each complete silhouette uniformly with nearest-neighbor interpolation, and reconstructs exact transparent 320×320 cells.

Verification: typed Stage 2 scene resources validate and reference all three runtime backgrounds. The Mirewarden definition validates an exact eight-column atlas and three typed phases. The exported Cypress and Spillway fixtures were inspected at 1280×720 gameplay scale; the first boss composition was rejected for a cropped, over-dark entrance, after which spawn position and phase tint were corrected. Accepted fixtures sustain approximately 120 FPS over 300 frames with zero frames above 20 ms or 33 ms.

## 2026-08-22 — Highway environments, Desert Interceptor, and Iron Vulture

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/build_highway_assets.gd` and `tools/build_interceptor_asset.gd` deterministic crop, isolation, nearest-neighbor normalization, and transparent-cell reconstruction pipelines.

Reference role: no external image, franchise screenshot, ROM art, logo, character, vehicle, or traced animation frame was supplied. Every prompt used only the original Wildland Strike setting and a general 1990s arcade rendering direction.

### Final files

- `assets/backgrounds/highway_canyon.png`: 1672×941 RGB; SHA-256 `6a07e32457641d17901f06b1f84ae6c91aba747662d725eb9422387ad4961700`.
- `assets/backgrounds/highway_checkpoint.png`: 1672×941 RGB; SHA-256 `3e9f59ca05201496f08213645121daf9a8f23dde7387194eb4ef10b91c7abce2`.
- `assets/backgrounds/highway_overpass.png`: 1672×941 RGB; SHA-256 `a47c5f5f6e0261d653402aff4ba05fd70414781c1669932cbae49ed9e211cf21`.
- `assets/sprites/desert_interceptor_sheet.png`: 1440×240 RGBA, 4×1; SHA-256 `31b0142798384509c3216a91d8e762bf3d8387f052abca6032e3ac3689496065`.
- `assets/sprites/iron_vulture_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `8633cc7d7172ac6c8b78ea3a8499941c3a279b7153c459aaa11b435bed235986`.
- Rejected environment concept retained for audit: `assets/backgrounds/highway_atlas_source.png`; SHA-256 `d43368d871e171b9b10db9691c68d5da4b819bb027969ca3c2dae2175a5dcfdc`.
- Archived vehicle sources: `assets/sprites/desert_interceptor_source.png`, SHA-256 `b4805aff62a9c65471c7fd632e2d947eb9486ae3bae70f9d3ad5fd12b87ffbbb`; and `assets/sprites/iron_vulture_source.png`, SHA-256 `512d59d7996eb919053013d885c02107c7e9b73dabb95318e76fa577c0bc4e46`.

All three source images are excluded from Web and iOS runtime exports.

Initial rejected environment-atlas prompt:

```text
Create an original clean-room 1990s arcade beat-em-up highway environment atlas for a Godot game named Wildland Strike. One wide cinematic pixel-art concept sheet arranged as THREE clearly separated equal vertical PANELS from left to right, with no gutters and no text: PANEL 1 sun-baked red-rock canyon highway, broken guardrails, distant mesas, abandoned research convoy; PANEL 2 raider checkpoint on a broad cracked asphalt freeway, improvised steel barricades, wrecked trucks, warning lights; PANEL 3 elevated storm overpass at dusk, lightning clouds, industrial skyline, wet asphalt and dramatic perspective. Camera is classic 2.5D side-view beat-em-up, horizon high, broad playable roadway covering lower 38%, foreground never blocks fighters, consistent scale and vanishing point across panels. Rich hand-authored 16-bit/32-bit arcade pixel art, crisp clusters, restrained dithering, dramatic teal/orange palette, serious grounded dinosaur-action atmosphere. Exactly three environment panels only, no characters, no vehicles in the active road area, no UI, no labels, no logos, no copyrighted imagery. High clarity and production-ready detail, landscape canvas.
```

The three-panel concept was rejected because the delivered panels were too narrow for a readable 16:9 combat arena. It remains only as an excluded provenance artifact. The following three independent prompts produced the accepted runtime backgrounds:

```text
Original clean-room production background for Wildland Strike, a serious 1990s arcade beat-em-up. Wide 16:9 landscape composition, classic 2.5D side-view. Sun-baked red-rock canyon highway at noon, distant mesas and abandoned scientific convoy far behind the playfield, broken guardrail and research antenna silhouettes, broad cracked asphalt roadway occupying the lower 40% with three readable depth lanes, horizontal side-scrolling composition, no perspective road receding into center. Crisp hand-authored 16-bit/32-bit pixel art, warm copper rock and cyan sky, rich but uncluttered, fighters will stand between y=455 and 665. No characters, no active vehicles, no text, no UI, no logo, no copyrighted imagery.
```

```text
Original clean-room production background for Wildland Strike, a serious 1990s arcade beat-em-up. Wide 16:9 landscape composition, classic 2.5D side-view. Raider checkpoint spanning a broad desert freeway at late afternoon, rusted watchtowers, wrecked convoy trucks and steel fortifications only behind the playfield, warning beacons and hanging cables, broad cracked asphalt roadway occupying the lower 40% with three readable depth lanes, horizontal side-scrolling composition and clear fighter silhouettes. Crisp hand-authored 16-bit/32-bit pixel art, burnt orange, gunmetal and dusty teal, rich grounded detail without foreground obstruction. No characters, no active vehicles on roadway, no text, no UI, no logos, no copyrighted imagery.
```

```text
Original clean-room production background for Wildland Strike, a serious 1990s arcade beat-em-up. Wide 16:9 landscape composition, classic 2.5D side-view. Elevated industrial overpass during a violent dusk thunderstorm, refinery skyline and lightning behind concrete barriers, wet asphalt reflections and damaged lamps, broad roadway occupying the lower 40% with three readable depth lanes, horizontal side-scrolling composition, dramatic navy, violet, cyan and amber palette. Crisp hand-authored 16-bit/32-bit pixel art, rich atmosphere but open active playfield, fighters will stand between y=455 and 665. No characters, no active vehicles, no text, no UI, no logo, no copyrighted imagery.
```

Iron Vulture generation prompt:

```text
Create an original clean-room arcade pixel-art sprite concept sheet for the Wildland Strike Stage 3 vehicle boss, named IRON VULTURE. Transparent background. A brutal improvised armored highway battle truck viewed in strict side profile, facing LEFT, dark charcoal steel with hazard-yellow markings, reinforced ram prow, exposed engine, oversized tires, roof gunner cage, exhaust stacks, and a distinct red vulture insignia that is not a logo from any existing franchise. Arrange EXACTLY EIGHT isolated equal-width cells in one horizontal row with generous transparent separation and the whole vehicle fully contained in every cell: 1 idle engine rumble, 2 suspension bounce, 3 rolling frame A, 4 rolling frame B, 5 ram telegraph with sparks, 6 active high-speed ram, 7 mine-drop recoil, 8 wrecked/defeated. Same scale, ground baseline, orientation, lighting, and silhouette in every cell. Crisp serious 16-bit/32-bit beat-em-up pixel art, readable at gameplay size, no text, no UI, no humanoid character outside the vehicle, no copyrighted designs, no shadows crossing cell boundaries. Very wide landscape atlas.
```

Desert Interceptor generation prompt:

```text
Create an original clean-room arcade pixel-art vehicle sprite sheet for Wildland Strike, transparent background. A rugged player-controlled desert interceptor in strict side profile facing RIGHT: low wide armored off-road muscle car, burnt-orange and cream body panels, reinforced steel bumper, exposed suspension, large realistic tires, roll cage, roof-mounted belt-fed gun, visible dark windshield driver silhouette, practical 1990s retro-future design. Arrange EXACTLY FOUR isolated equal-width cells in one horizontal row with generous transparent separation: 1 engine idle, 2 driving suspension frame A, 3 driving suspension frame B with subtle dust, 4 collision-damaged flash/sparks. Same vehicle scale, ground baseline, orientation and lighting in every cell; entire vehicle contained in each cell. Serious crisp 16-bit/32-bit beat-em-up pixel art matching a high-detail canyon highway, not cute, not toy-like, no text, no UI, no logo, no copyrighted designs, no external standing characters, no shadows crossing cell boundaries. Very wide landscape atlas.
```

The first integrated player vehicle was a procedural placeholder. Exported-browser inspection rejected it as toy-like and also caught standing player sprites clipping through the roof. The final Desert Interceptor atlas replaced that placeholder, and vehicle mounting now hides on-foot silhouettes while preserving each player's independent mounted-fire ownership. Both generated vehicle sources arrived with nonuniform pose spacing, so the retained builders detect the largest complete opaque components, sort them by x position, apply one uniform nearest-neighbor scale, and center each vehicle on a fixed transparent baseline.

Verification: every Stage 3 scene resource validates its original background and the typed vehicle sequence validates speed, lane, hull, collision, ram, and mounted-weapon parameters. Both accepted vehicle sheets retain alpha and divide into exact state cells. The exported 1280×720 canyon, checkpoint, overpass, and three-phase boss fixtures were inspected for lane readability, silhouette scale, crop loss, mounting, depth order, collision cues, and telegraph clarity. The initial oversized circular boss cue was rejected and replaced with road-aligned chevrons. Accepted canyon and boss samples average 119.60 and 120.00 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings or errors.

## 2026-08-22 — Industrial foundry environments and Forge Regent Volkr

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/build_industrial_assets.gd` connected-component isolation, nearest-neighbor normalization, and transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, vehicle, or traced animation frame was supplied. Every prompt used only the original Wildland Strike setting and a general late-1990s arcade rendering direction.

### Final files

- `assets/backgrounds/industrial_motor_pool.png`: 1672×941 RGB; SHA-256 `7c05a40f1bd259a4720011dae90b52656a8411e49929d925c24f9edc7cb5244a`.
- `assets/backgrounds/industrial_assembly_floor.png`: 1672×941 RGB; SHA-256 `dd679fd18d3f7d60b48ff285a0064be0ff637e9ea2d8e275ad921c918c24cb88`.
- `assets/backgrounds/industrial_crucible_lift.png`: 1672×941 RGB; SHA-256 `0ac3590935e3892e1c4112e7a5bee5b227ef58f610fc042c376a83d63b28d8da`.
- Archived Forge Regent source: `assets/sprites/forge_regent_source.png`; 2079×756 RGBA; SHA-256 `3ab3137802c9e734ea51b143d5e594474fbd0bba59badc8a6c15048620a5c06c`.
- `assets/sprites/forge_regent_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `a31203b18734779e48c2d4d7ba56bec81ae975fa5dbf0e69bdee6d0d3a0a663f`.

The archived boss source is excluded from Web and iOS runtime exports.

Motor-pool generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 4, a serious 1990s 2.5D arcade beat-em-up
Primary request: a vast fortified desert motor-pool garage breached at night, with armored repair bays, suspended engines, tool gantries, welding sparks, partly opened blast doors and distant storm-lit canyon visible only behind the combat floor
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded industrial detail, consistent with a premium late-1990s belt-scrolling brawler
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed concrete gameplay lane occupying the lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; machinery and vehicles remain behind safety rails and never block the active floor
Lighting/mood: cold cyan moonlight, warm amber work lamps, restrained red emergency lights, serious tense atmosphere
Constraints: environment only; no people, no dinosaurs, no active vehicles in the combat lane, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing-point road, no foreground obstruction
```

Assembly-floor generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 4, a serious 1990s 2.5D arcade beat-em-up
Primary request: the interior of a colossal armored assembly foundry, with overhead chain hoists, robotic welding arms, piston presses, moving conveyor machinery and half-built original industrial vehicles kept behind guardrails; molten sparks but no open lava on the combat floor
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail industrial environment, premium late-1990s belt-scrolling brawler quality
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed steel-plate gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; all large machinery remains in back and upper layers
Lighting/mood: hot amber welding light against deep teal steel shadows, rhythmic red warning lamps, escalating mechanical danger
Constraints: environment only; no people, no dinosaurs, no active vehicle in gameplay lane, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing point, no foreground machinery covering fighters
```

Crucible-lift generation prompt:

```text
Use case: stylized-concept
Asset type: original production boss-arena background for Wildland Strike Stage 4, a serious 1990s 2.5D arcade beat-em-up
Primary request: an immense circular crucible lift deep inside an armored foundry, stopped beside a glowing smelter chamber; towering pistons, furnace mouths, cooling pipes, suspended magnetic crane and molten-metal channels are safely behind thick rails, creating a dramatic industrial boss arena
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, premium late-1990s belt-scrolling brawler environment, grounded materials and readable silhouettes
Composition/framing: wide 16:9 strict side view, horizontal arena composition, broad unobstructed circular steel gameplay platform occupying lower 40%, three readable depth lanes and symmetrical boss framing; fighters stand between y=455 and 665; no foreground objects obscure combat
Lighting/mood: fierce orange furnace glow, deep cobalt steel shadows, white-hot sparks and red alarm accents, climactic but visually readable
Constraints: environment only; no people, no dinosaurs, no boss, no text, no UI, no logos, no watermark, no copyrighted imagery, no open molten metal crossing the active floor, no central perspective corridor, no foreground obstruction
```

Forge Regent generation prompt:

```text
Use case: stylized-concept
Asset type: original transparent boss sprite action atlas for Wildland Strike Stage 4
Primary request: one horizontal strip of EXACTLY EIGHT isolated equal-width cells showing the same original industrial boss, FORGE REGENT VOLKR: a towering broad human foundry commander inside a compact charcoal-and-copper powered exoskeleton, asymmetrical magnetic grappler gauntlet on the left arm, heavy piston hammer on the right arm, heat-shield apron plates, glowing cyan power coils and small amber furnace vents; strict side profile facing LEFT
Pose order: 1 armored idle with vent pulse, 2 heavy walk, 3 piston-hammer strike, 4 magnetic-hook telegraph with coil glow, 5 magnetic pull recoil, 6 furnace ground-slam with sparks, 7 hurt stagger with cracked armor, 8 defeated kneeling collapse
Style/medium: serious crisp hand-authored 16-bit/32-bit arcade beat-em-up pixel art, strong readable silhouette, detailed late-1990s sprite rendering, original clean-room design
Composition/framing: very wide landscape atlas; exactly one complete full-body boss centered per cell; same scale, foot baseline, orientation, lighting, proportions and costume in every frame; generous genuinely transparent separation; all limbs, hammer, grappler and effects remain within their own cell
Constraints: transparent background mandatory; exactly 8 cells in one row; no scenery, floor, labels, text, UI, logos, watermark, copyrighted designs, vehicles, detached distant effects, shadows crossing cell boundaries, cropped anatomy, extra characters
```

The environment outputs already matched the established 1672×941 runtime contract and were retained directly. The Forge Regent service output retained real alpha but delivered irregular pose spacing and a non-runtime canvas. The deterministic builder discovers the eight largest complete opaque components, sorts them by x position, scales each silhouette uniformly with nearest-neighbor interpolation, and centers every pose on an exact transparent 320×320 cell without carrying detached effects across boundaries.

Verification: all three Stage 4 scene resources validate and reference unique original backgrounds. The accepted boss sheet retains alpha and divides into eight exact cells. Exported 1280×720 environment and boss fixtures were inspected for gameplay-lane readability, press/vent silhouette identity, actor occlusion, boss scale, crop loss, phase cues, and telegraph clarity. Abstract floating press outlines and an oversized circular boss cue were rejected and replaced before acceptance. Final fixtures sustain approximately 120 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings or errors.

## 2026-08-22 — Burning settlement environments and Cinder Matriarch Veyra

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/build_burning_settlement_assets.gd` checker-background removal, connected-component isolation, nearest-neighbor normalization, and exact transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, creature, or traced animation frame was supplied. Every prompt used only the original Wildland Strike setting and a general late-1990s arcade rendering direction.

### Final files

- `assets/backgrounds/burning_refuge.png`: 1672×941 RGB; SHA-256 `cd928c4634623cf50678af059db7c8d82bf818276c9e2a02859821ca81c94831`.
- `assets/backgrounds/burning_market.png`: 1672×941 RGB; SHA-256 `31cc9dfef57f37fbe7ca4f5b6b493af553dc1691f9ac471db76f585e6107f945`.
- `assets/backgrounds/ashen_cistern.png`: 1672×941 RGB; SHA-256 `3728b5054a52898133afccdc4703aea6d4ac5f93f4fb42b6464b01497df15b25`.
- Archived Cinder Matriarch source: `assets/sprites/cinder_matriarch_source.png`; 1774×887 RGBA; SHA-256 `7902c640a439874bc8143dda33ffc619ab27d227ecfdd3905496aff1562a58f9`.
- `assets/sprites/cinder_matriarch_sheet.png`: 2560×640 RGBA, 8×2; SHA-256 `7c37f8d60ce85258d0eb8879879a20621fb993d5eba8fe43fc5ed4906a90cb12`.

The archived boss source is excluded from Web and iOS runtime exports.

Ember Refuge generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 5, a serious 1990s 2.5D arcade beat-em-up
Primary request: a fortified desert refugee settlement at the first moments of a night firestorm, improvised adobe-and-steel homes, elevated water tanks, evacuation gantries, torn canvas awnings, controlled flames and smoke only in background structures, distant red mesas under a black sky
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail late-1990s belt-scrolling brawler environment, original clean-room visual identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed dusty-stone gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; civilians and structures remain absent from active floor
Lighting/mood: cold moonlit navy shadows against urgent amber firelight and restrained red alarm lamps, serious evacuation atmosphere
Constraints: environment only; no people, no dinosaurs, no characters, no active vehicles, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing-point road, no flames or debris blocking the active combat lane, no foreground obstruction
```

Burning Market generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 5, a serious 1990s 2.5D arcade beat-em-up
Primary request: the central market of an original fortified desert settlement during a spreading night firestorm, collapsed canvas stalls and adobe arcades kept behind railings, overhead emergency water pipes, a burning communications mast, falling embers and dense smoke high above, visible evacuation alleys behind the combat floor
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail premium late-1990s belt-scrolling brawler environment, original clean-room identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed stone-and-metal gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; all stalls, flames and collapsing structures remain behind barriers and never obscure active combat
Lighting/mood: intense amber and crimson firelight against deep indigo smoke shadows, white emergency lamps, escalating disaster but strong fighter readability
Constraints: environment only; no people, no dinosaurs, no characters, no active vehicles, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing point, no flame wall crossing the active lane, no foreground debris or obstruction
```

Ashen Cistern generation prompt:

```text
Use case: stylized-concept
Asset type: original production boss-arena background for Wildland Strike Stage 5, a serious 1990s 2.5D arcade beat-em-up
Primary request: the high ceremonial water-cistern plaza of a fortified desert settlement at the peak of a night firestorm, a tall original ash-bell tower and ruptured waterworks behind thick safety rails, burning rooftops and smoke columns in the distance, emergency floodgates and wet reflective stone framing a dramatic transformation-boss arena
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, premium grounded late-1990s belt-scrolling brawler environment, original clean-room identity and readable materials
Composition/framing: wide 16:9 strict side view, horizontal symmetrical arena composition, broad unobstructed wet-stone gameplay platform occupying lower 40%, three readable depth lanes; fighters stand between y=455 and 665; tower, flames, pipes and cistern machinery remain in back and upper layers
Lighting/mood: fierce orange fire rim light, deep cobalt night shadows, pale cyan emergency water jets and white-hot embers, climactic yet highly readable
Constraints: environment only; no people, no dinosaurs, no boss, no characters, no text, no UI, no logos, no watermark, no copyrighted imagery, no open flame crossing the active floor, no central perspective corridor, no foreground obstruction
```

Cinder Matriarch generation prompt:

```text
Use case: stylized-concept
Asset type: original transparent transformation-boss sprite action atlas for Wildland Strike Stage 5
Primary request: one two-row action atlas showing the same original boss, CINDER MATRIARCH VEYRA. ROW 1 is a tall human fire marshal in scorched black-and-brass emergency armor, ember-red mantle, long furnace lance, sealed respirator and cyan cistern canisters. ROW 2 is her transformed obsidian ash-beast form, a massive low horned quadruped with cracked volcanic plates, glowing orange seams, the same cyan cistern hardware fused into its shoulders, and a clearly different silhouette. Both forms face LEFT.
Pose order in each row: 1 idle, 2 locomotion, 3 primary strike, 4 special telegraph, 5 special attack, 6 rush or heavy attack, 7 hurt, 8 defeated
Style/medium: serious crisp hand-authored 16-bit/32-bit arcade beat-em-up pixel art, strong readable silhouettes, detailed late-1990s sprite rendering, original clean-room design
Composition/framing: exactly eight isolated cells per row and exactly two rows; one complete figure centered in every cell; consistent scale, foot baseline, orientation, lighting and identity within each form; generous transparent separation; all anatomy, weapons and effects contained in their own cells
Constraints: transparent background mandatory; no scenery, floor, labels, text, UI, logos, watermark, copyrighted designs, extra characters, cropped anatomy, or shadows and effects crossing cell boundaries
```

The initial boss delivery was rejected for pose silhouettes joined across cell boundaries. A follow-up image edit requested stronger separation, unchanged character design, and a truly transparent background. That edit separated the poses but baked a pale checkerboard into the pixels instead of supplying usable alpha. The retained deterministic builder classifies and removes the near-neutral checker colors, bridges only small holes inside each isolated figure, finds the sixteen largest complete pose components, sorts them into two rows, and uniformly normalizes each pose onto exact transparent 320×320 cells. This makes the accepted 8×2 atlas reproducible without retaining any visual bridge or checkerboard contamination.

Verification: all three Stage 5 scene resources validate and reference unique original backgrounds. The accepted boss sheet retains alpha, divides into sixteen exact cells, and presents distinct human and ash-beast phase rows. Exported 1280×720 environment and transformed-boss fixtures were inspected for active-lane readability, scene-boundary crop, silhouette scale, reinforcement occlusion, form change, hazard cues, and attack telegraphs. A boundary-framed environment fixture, occluding reinforcements, and an oversized inherited circular boss cue were rejected and corrected. Accepted fixtures average 120.00 and 120.08 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings or errors.

## 2026-08-22 — Jungle mine environments, ore cart, and Titan Warden Korva

Tool: OpenAI built-in `image_gen` clean-room generation/edit workflow, followed by the retained project-local `tools/build_jungle_mine_assets.gd` neutral-checker removal, connected-component isolation, nearest-neighbor normalization, and exact transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, vehicle, creature, or traced animation frame was supplied. Every prompt used only the original Wildland Strike setting and a general late-1990s arcade rendering direction.

### Final files

- `assets/backgrounds/jungle_research_trail.png`: 1672×941 RGB; SHA-256 `b75b8b0a2bf0f1481f686e23f196cb742869550d345a63a45ded2eb9ad2bb1c9`.
- `assets/backgrounds/jungle_mine_entrance.png`: 1672×941 RGB; SHA-256 `bdd09499d330a2b2220cb45a5e02fa20a4ea307d591814bfec7f1f2d552c9752`.
- `assets/backgrounds/titan_shaft.png`: 1672×941 RGB; SHA-256 `64a03fe12d5bf2f48679d9e7bb9456c68cd62e0aaffe6bbf3887be26ba04b215`.
- Archived Titan Warden original source: `assets/sprites/titan_warden_source.png`; SHA-256 `05975bc8f9bdb1038dc7d47d613df2d21ff9a404e3709afd729fd912825c73f9`.
- Archived Titan Warden isolation-edit source: `assets/sprites/titan_warden_edit_source.png`; SHA-256 `40e45ba87437cadab892d0ad607eb6a11d77d53a75884f2d4a9771a9a5a22284`.
- `assets/sprites/titan_warden_sheet.png`: 2560×320 RGBA, 8×1; SHA-256 `6c9ded982cae77133354897e09cb81e43eb4b83df98f3e39d7f4de8abfcb03ad`.
- Archived ore-cart original source: `assets/sprites/jungle_mine_cart_source.png`; SHA-256 `a82fbf663ca377f4316c2f5802e7c2b16c4be553c1207806e32101a6cc853f27`.
- Archived ore-cart isolation-edit source: `assets/sprites/jungle_mine_cart_edit_source.png`; SHA-256 `3ff3d247742346d5681020577a251eb9b290e25e7b09f4251f7d844bb67fdbb4`.
- `assets/sprites/jungle_mine_cart.png`: 256×160 RGBA; SHA-256 `2759e74624f9de38aa135df2c8e7702316b4b561943e1d748d1ec0b25e6e1e80`.

The four archived generation/edit sources are excluded from Web and iOS runtime exports.

Jungle Research Trail generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 6, a serious 1990s 2.5D arcade beat-em-up
Primary request: a rain-soaked primordial jungle research trail at predawn, colossal original cycads and tree ferns, abandoned steel survey pylons, suspended rope bridges and broken expedition equipment only behind the combat floor, distant gentle sauropod silhouettes high above the canopy
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail premium late-1990s belt-scrolling brawler environment, original clean-room identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed mud-and-stone gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; plants and structures remain behind the lane
Lighting/mood: blue-green predawn rain, pale cyan research lamps, restrained amber emergency markers, tense expedition atmosphere
Constraints: environment only; no people, no fighters, no foreground dinosaurs, no characters, no active vehicles, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing-point road, no vegetation or debris blocking the active combat lane, no foreground obstruction
```

Jungle Mine Entrance generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 6, a serious 1990s 2.5D arcade beat-em-up
Primary request: an illegal open-pit jungle mine entrance carved through ancient basalt, rusted ore rails and empty mine carts behind safety barriers, vine-covered crusher machinery, floodlights, warning cages and a huge reinforced tunnel mouth, with the rainforest closing around the industrial scar
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail premium late-1990s belt-scrolling brawler environment, original clean-room identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed wet stone-and-mud gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; rails, carts and machinery stay behind barriers
Lighting/mood: stormy emerald jungle shadows, hard amber mine floodlights, cold white work lamps and restrained red warning beacons, escalating industrial danger
Constraints: environment only; no people, no dinosaurs, no characters, no active vehicle in the combat lane, no text, no UI, no logos, no watermark, no copyrighted imagery, no central perspective corridor, no foreground machinery or vines covering fighters
```

Titan Shaft generation prompt:

```text
Use case: stylized-concept
Asset type: original production boss-arena background for Wildland Strike Stage 6, a serious 1990s 2.5D arcade beat-em-up
Primary request: an immense subterranean fossil quarry called the Titan Shaft, ancient basalt columns and giant unidentified rib fossils behind reinforced rails, hanging ore elevators, broken drill gantries, glowing mineral seams and a massive sealed excavation gate framing a climactic arena deep under the jungle
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, premium grounded late-1990s belt-scrolling brawler environment, original clean-room identity and readable stone/metal materials
Composition/framing: wide 16:9 strict side view, horizontal symmetrical arena composition, broad unobstructed dark stone gameplay platform occupying lower 40%, three readable depth lanes; fighters stand between y=455 and 665; fossils, shafts, drills and machinery remain in back and upper layers
Lighting/mood: deep teal and violet cavern shadows, cold cyan mineral light, amber lift lamps and restrained red alerts, ancient and dangerous but highly readable
Constraints: environment only; no people, no living dinosaurs, no boss, no characters, no text, no UI, no logos, no watermark, no copyrighted imagery, no central perspective corridor, no active machinery or rockfall crossing the combat floor, no foreground obstruction
```

Titan Warden generation prompt:

```text
Use case: stylized-concept
Asset type: original transparent boss sprite action atlas for Wildland Strike Stage 6
Primary request: one horizontal strip of EXACTLY EIGHT isolated equal-width cells showing the same original boss, TITAN WARDEN KORVA: a very tall broad human illegal-quarry commander in battered moss-green and black powered mining armor, reinforced amber drill-spear on the right arm, compact cyan seismic beacon backpack, fossil-white shoulder plates, braided dark hair, stern face, strict side profile facing LEFT
Pose order: 1 armored idle with beacon pulse, 2 heavy walk, 3 drill-spear strike, 4 seismic telegraph bracing the beacon, 5 ground-fracture slam, 6 full-body drill charge, 7 hurt stagger with cracked shoulder plate, 8 defeated kneeling collapse
Style/medium: serious crisp hand-authored 16-bit/32-bit arcade beat-em-up pixel art, strong readable silhouette, detailed late-1990s sprite rendering, original clean-room design
Composition/framing: very wide landscape atlas; exactly one complete full-body boss centered per cell; same scale, foot baseline, orientation, lighting, proportions and costume in every frame; generous genuinely transparent separation; all limbs, drill, beacon and effects remain within their own cell
Constraints: transparent background mandatory; exactly 8 cells in one row; no scenery, floor, labels, text, UI, logos, watermark, copyrighted designs, vehicles, creatures, detached distant effects, shadows crossing cell boundaries, cropped anatomy, extra characters
```

Ore-cart generation prompt:

```text
Use case: stylized-concept
Asset type: one original transparent gameplay hazard sprite for Wildland Strike Stage 6
Primary request: a single rugged illegal-jungle-mine ore cart viewed in strict side profile, facing RIGHT, low heavy rusted steel hopper loaded with dark basalt rocks and a few cyan mineral shards, reinforced frame, four small realistic flanged rail wheels, rivets, hazard-yellow worn stripe, compact red warning lamp, grounded 1990s industrial design
Style/medium: serious crisp hand-authored 16-bit/32-bit arcade pixel art matching a premium late-1990s belt-scrolling brawler, readable at approximately 150 pixels wide, original clean-room design
Composition/framing: exactly ONE complete cart centered on canvas with generous transparent margin, entire wheels, frame, ore and lamp visible, no motion blur and no shadow outside the silhouette
Constraints: genuine transparent background mandatory; exactly one cart only; no track, no floor, no scenery, no people, no creatures, no text, no UI, no logo, no watermark, no copyrighted design, no cropped edges, no checkerboard
```

Both initial sprite deliveries retained unusable dark backgrounds. Isolation edits preserved the authored figures but baked checkerboard pixels instead of real alpha. The deterministic builder removes only bright neutral checker regions, isolates the largest complete component in each fixed boss cell, uniformly normalizes eight poses onto exact transparent 320×320 cells, and normalizes the cart onto a transparent 256×160 canvas. Two procedural cart drafts were rejected during Web review; the accepted generated cart is the runtime asset.

Verification: all three Stage 6 scene resources validate and reference unique original backgrounds. Titan Warden's accepted atlas retains alpha and divides into eight exact cells; the cart retains alpha and remains fully inside its runtime canvas. Exported 1280×720 environment and phase-two boss fixtures were inspected for gameplay-lane readability, cart scale/materials, silhouette scale, crop loss, footprint warnings, seismic-fracture sequencing, reinforcement visibility, and phase telegraphs. Accepted fixtures average 120.00 and 120.006 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings or errors.

## 2026-08-22 — Underground vault environments and Vault Sentinels

Tool: OpenAI built-in `image_gen` clean-room generation workflow, followed by the retained project-local `tools/build_vault_sentinel_assets.gd` fixed-cell connected-component isolation, nearest-neighbor normalization, and exact transparent-cell reconstruction pipeline.

Reference role: no external image, franchise screenshot, ROM art, logo, character, or traced animation frame was supplied. Every prompt used only the original Wildland Strike setting and a general late-1990s arcade rendering direction.

### Final files

- `assets/backgrounds/vault_elevator_descent.png`: 1672×941 RGB; SHA-256 `ee913514d5a86bea6c1731ae9bebaaba4404163918e99d66cc52ce21b38a6195`.
- `assets/backgrounds/cryogenic_vault_hall.png`: 1672×941 RGB; SHA-256 `bcc72128430e770090db50d2aeb7acab95fa5e6863dad5fa487efbc6098b786a`.
- `assets/backgrounds/twin_core_vault.png`: 1672×941 RGB; SHA-256 `1ee304444abc6597839ac69123df67b2ce49a68be4ec22943f3329b7cf4f12a6`.
- Archived paired-boss source: `assets/sprites/vault_sentinels_source.png`; 1774×887 RGBA; SHA-256 `3ff05f5dd6bc8098e7f2225370ad47d5604a4ac30bc98cd16c12037f790df762`.
- `assets/sprites/vault_sentinels_sheet.png`: 2560×640 RGBA, 8×2; SHA-256 `d53b24ea2410414817937780e8ed9aad51b2bb794622323a74390565d32552e6`.

The archived source is excluded from Web and iOS runtime exports.

Vault Elevator Descent generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 7, a serious 1990s 2.5D arcade beat-em-up
Primary request: the interior of a colossal armored freight elevator descending through a subterranean basalt shaft, thick side rails, huge counterweights, segmented blast doors, maintenance gantries and moving work lights only behind the combat platform; distant cyan mineral seams reveal great depth
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail premium late-1990s belt-scrolling brawler environment, original clean-room identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed steel elevator gameplay deck occupying lower 40%, three readable depth layers, horizon high; fighters stand between y=455 and 665; cables, machinery and gantries remain behind guardrails
Lighting/mood: cold teal shaft shadows, amber maintenance lamps, restrained red descent warnings, strong readable silhouettes and a sense of vertical motion
Constraints: environment only; no people, no fighters, no creatures, no active vehicle, no text, no UI, no logos, no watermark, no copyrighted imagery, no central vanishing-point corridor, no cables or machinery crossing the active combat lane, no foreground obstruction
```

Cryogenic Vault Hall generation prompt:

```text
Use case: stylized-concept
Asset type: original production background for Wildland Strike Stage 7, a serious 1990s 2.5D arcade beat-em-up
Primary request: a sealed subterranean cryogenic vault transit hall built into ancient basalt, enormous original circular security doors, frost-covered specimen cylinders containing only abstract mineral samples, armored cargo rails, decontamination arches and dormant security emitters behind thick barriers
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, grounded high-detail premium late-1990s belt-scrolling brawler environment, original clean-room identity
Composition/framing: wide 16:9 strict side view, horizontal side-scrolling layout, broad unobstructed frost-dusted metal gameplay lane occupying lower 40%, three readable depth lanes, horizon high; fighters stand between y=455 and 665; vault machinery and cylinders remain in back and upper layers
Lighting/mood: icy cyan and desaturated violet shadows, warm amber floor safety lights, restrained red security pulses, sterile and tense but highly readable
Constraints: environment only; no people, no living creatures, no recognizable fossils, no characters, no text, no UI, no logos, no watermark, no copyrighted imagery, no central perspective corridor, no foreground glass or machinery obscuring fighters
```

Twin Core Vault generation prompt:

```text
Use case: stylized-concept
Asset type: original production paired-boss arena background for Wildland Strike Stage 7, a serious 1990s 2.5D arcade beat-em-up
Primary request: the Twin Core Vault, an immense symmetrical underground security chamber around two original suspended reactor prisms, paired armored control thrones, interlocking circular blast-door mechanisms, segmented energy conduits and heavy elevator locks behind reinforced rails
Style/medium: crisp hand-authored 16-bit/32-bit arcade pixel art, premium grounded late-1990s belt-scrolling brawler environment, original clean-room identity and readable metal/crystal materials
Composition/framing: wide 16:9 strict side view, horizontal symmetrical arena composition, broad unobstructed dark steel gameplay platform occupying lower 40%, three readable depth lanes; two bosses and fighters stand between y=455 and 665; all cores, doors and machinery remain behind or above the platform
Lighting/mood: opposing cyan and amber reactor light, deep indigo shadows, restrained red lock alerts, climactic paired-duel atmosphere with clear floor readability
Constraints: environment only; no people, no bosses, no characters, no creatures, no text, no UI, no logos, no watermark, no copyrighted imagery, no beam crossing the active floor, no central perspective corridor, no foreground obstruction
```

Vault Sentinels generation prompt:

```text
Use case: stylized-concept
Asset type: original transparent paired-boss sprite action atlas for Wildland Strike Stage 7
Primary request: exactly TWO ROWS of EIGHT isolated equal-width cells. ROW 1 shows the same original boss VAULT SENTINEL ORIN, a towering broad male security commander in graphite-and-brass powered armor with a large angular cyan barrier gauntlet, compact shoulder projector and shaved head, strict side profile facing LEFT. ROW 2 shows the same original boss VAULT SENTINEL NYX, a tall athletic female security commander in dark violet-and-silver segmented armor with twin short amber phase blades, braided high ponytail and compact hip emitters, strict side profile facing LEFT.
Pose order in each row: 1 combat idle, 2 locomotion, 3 primary strike, 4 synchronized-attack telegraph, 5 energy attack, 6 charging heavy attack, 7 hurt stagger, 8 defeated collapse
Style/medium: serious crisp hand-authored 16-bit/32-bit arcade beat-em-up pixel art, strong distinct silhouettes, detailed premium late-1990s sprite rendering, original clean-room designs
Composition/framing: very wide two-row landscape atlas; exactly one complete full-body boss centered per cell; consistent individual scale, foot baseline, orientation, lighting, identity and costume within each row; generous genuinely transparent gutters; all limbs, weapons, shields and close effects remain within their own cell
Constraints: genuine transparent background mandatory; exactly 8 cells per row and exactly 2 rows; no scenery, floor, labels, text, UI, logos, watermark, copyrighted designs, vehicles, creatures, detached distant effects, shadows crossing cells, cropped anatomy, extra characters
```

The first deterministic pass trimmed each row globally and then sliced it evenly; Web inspection rejected the result because pose widths were not mathematically uniform and neighboring fragments crossed cell boundaries. The accepted builder instead divides the source into sixteen fixed cells, retains only the largest connected opaque figure inside each cell, and uniformly centers it on a transparent 320×320 runtime cell. This intentionally removes detached distant effect fragments while preserving every complete character silhouette.

Verification: all three Stage 7 scene resources validate and reference unique original backgrounds. The accepted paired-boss atlas retains alpha and divides into sixteen exact cells. Exported 1280×720 environment and paired-boss fixtures were inspected for active-lane readability, silhouette scale, crop loss, hazard occlusion, combined-HUD correctness, synchronized telegraphs, and dual-boss composition. A clipped Nyx placement and an overlapping cryogenic cue were rejected and corrected. Accepted fixtures average 120.1547 and 120.0881 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings or errors.
