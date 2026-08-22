# Known issues — v1.0.0 release candidate

Audit date: 2026-08-22

## Defect gate

| Severity | Open defects | Release disposition |
|---|---:|---|
| Critical | 0 | Pass |
| High | 0 | Pass |
| Medium | 0 | Pass |
| Low | 0 | Pass |

No gameplay, content, save, Web, or unsigned iOS build defect is currently accepted for v1.0.0.

## External release dependency

- A signed physical-iPhone installation still requires a valid Apple Development identity and provisioning profile for team `BYSMY792J7`, plus the paired phone connected and trusted. This is tracked as a release-environment dependency, not a product defect. The unsigned generic-device arm64 build passes.

## Supported-scope notes

- Local 2–3 player play is a desktop/Web keyboard-and-gamepad feature. Mobile touch guarantees a polished single-player layout by design.
- Web first load includes the full high-resolution campaign package; subsequent loads may benefit from browser caching.
