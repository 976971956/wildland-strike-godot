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
