# TetrisFight – project notes for Claude

Godot 4.7 (GDScript, GL Compatibility) single-player Tetris. Web build is deployed to
GitHub Pages by `.github/workflows/deploy-web.yml` (image `barichello/godot-ci:4.7.2`,
single-threaded web export so no COOP/COEP headers are needed). Main test target: iOS Safari.

## Workflow: always merge
The owner has pre-authorized merging. When a piece of work is finished and verified, push the
dev branch, open a PR into `main` and squash-merge it right away (no need to ask first).
Never force-push. After merging, check that the "Deploy Web to GitHub Pages" run succeeded
(`mcp__github__actions_list` / `get_job_logs`) and report the live URL
`https://jfcc-github.github.io/tetrisFight/`. If CI fails, fix and merge again.

## Art: generate it with Python, don't hand-draw or download
All visual assets are produced by `tools/gen_assets.py` (Pillow + numpy) into `assets/`.
When the UI needs new art (icons, blocks, backgrounds, logos, badges), **add a function to
that script and re-run it** (`python3 tools/gen_assets.py`) instead of shipping ad-hoc images.
Then run `godot --headless --import` so the `.import` files exist, and commit both.

Techniques that make the output look good:
- **Supersample**: draw at 4x (`ss=4`) then `resize(..., Image.LANCZOS)` for clean anti-aliased edges.
- **Retina sizes**: viewport is 540x960 but iPhones render ~3x, so make textures ≥2x the size
  they are drawn at (blocks 96px for 30px cells, icons 128px, background 1080x1920).
- **Gradients with numpy** (`vgradient` with colour stops), pasted through a
  `rounded_rectangle` mask (`rounded_mask`).
- **Blocks**: dark rim → gradient body → inner bevel face → blurred white gloss band on top.
  Don't `ImageDraw` semi-transparent shapes straight onto RGBA (it replaces pixels and
  leaves grey holes); composite a separate layer with `Image.alpha_composite` instead.
- **Logo text**: font mask → `MaxFilter` for a thick outline → stacked offset copies for 3D
  depth → gradient fill through the mask → blurred coloured glow underneath → top-half shine.
- **Icons**: white-on-transparent line icons on an `Icon` helper (`stroke` with round caps,
  `arc`, `poly`, `arrow_head`), stroke width ~10% of size, so Godot can tint them via modulate.
- **Background**: gradient + big blurred colour blobs (`GaussianBlur(220)`) + faint lines +
  stars, then ±3 random noise to avoid banding; save as JPEG (q90) to keep it small.
- Always build a contact sheet and look at it (Read the PNG) before wiring assets in.

Fonts are Google Fonts (OFL) fetched from `raw.githubusercontent.com/google/fonts/main/ofl/...`
with their OFL.txt kept beside them in `assets/fonts/`.

## Code layout
- `scripts/style.gd` – palette, fonts, preloaded textures, StyleBoxFlat factories, draw helpers.
  Shapes (panels, buttons) are vector StyleBoxFlat (crisp at any scale); only art is bitmap.
- `scripts/ui.gd` – node builders (label, button, icon_button, card, pop_in, audio_toggles).
- `scripts/game.gd` – gameplay + all in-game drawing; `pieces.gd` SRS data;
  `scores.gd` / `sfx.gd` autoloads (local leaderboard, synthesized audio).
- Piece colours live in three places that must match: `tools/gen_assets.py` PIECES,
  `style.gd` PIECE_COLORS, `pieces.gd` COLORS.

## Verifying changes
- Headless logic test: a temporary scene with a test script, run
  `godot --headless --path . res://tmp_test.tscn` (autoloads are not available with `--script`).
- Visual check: `--export-release "Web" build/web/index.html`, serve with
  `python3 -m http.server`, screenshot with Playwright (Chromium needs
  `--use-gl=swiftshader --enable-unsafe-swiftshader --ignore-gpu-blocklist`), and look at it.
