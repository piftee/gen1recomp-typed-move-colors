# Changelog

## 0.3.4 - 2026-08-10

- Added Gen 3 Inspired UI Overhaul v1.3.2 compatibility for type-coloured battle move rows and its TYPE/PP details strip.
- Preserved the overhaul's final-resolution panel, smooth fonts, spacing, PP readouts and selection controls instead of drawing a second move selector beside it.
- Added the Gen 3 overhaul as an optional dependency so the compatibility post-pass always runs after its renderer is registered.

## 0.3.3 - 2026-08-10

- Kept Useful Move Info's Start/Q battle text box above the detached move selector.
- Added type-coloured current-move and NEW MOVE rows to Useful Move Info's move-learning screen without replacing its inspection controls.
- Added Useful Move Info as an optional dependency so its screen factory is available before the compatibility adapter is installed.

## 0.3.2 - 2026-08-09

- Made the detached move selector choose its integer scale from both display width and height.
- Capped the selector to roughly the bottom third of short landscape screens instead of allowing width to make it excessively tall.
- Expanded the native card widths after a height cap so wide displays still use their available horizontal space without stretching the pixel art.
- Kept the complete selector inside Android and iOS safe areas where the platform reports them.
- Restored the narrow player HUD strip shared with the erased native TYPE/PP panel, fixing clipped HP and companion EXP labels in standard battles.
- Anchored tall mobile selectors to the native move-menu row beneath the player HUD instead of dropping them into the touch-control area.

## 0.3.1 - 2026-08-08

- Replaced the approximate named-palette type colours with exact fills sampled from the supplied type reference.
- Added matching Dark, Fairy and Steel colours for content mods that register later-generation types.
- Derived a brighter selected shade from each reference colour while keeping the default bold face exact.
- Preserved OG Red, OG Blue, OG Yellow, monochrome, inverted and Classic display-mode behaviour.

## 0.3.0 - 2026-08-08

- Added optional geometric effectiveness indicators to responsive battle move buttons.
- Uses double-up, up, down and circle symbols for super-effective, effective, resisted and non-HP moves respectively.
- Keeps the symbols secondary with stemless arrowheads anchored to each card's bottom-right corner.
- Added the Move Effect toggle to the normal game Options menu and the mod settings page.
- Treats fixed-damage and Super Fang moves as HP-effective without claiming a chart multiplier Generation 1 does not apply.
- Restored the complete player Pokemon sprite after removing the classic TYPE/PP box in standard battles, while leaving staged voxel renderers untouched.

## 0.2.5 - 2026-08-08

- Scaled the complete detached selector uniformly to nearly the full screen width.
- Positioned it in the bottom band beneath the battling Pokémon rather than squeezing it into a corner.
- Made one- and two-move selectors use full-height buttons; three and four moves retain the two-by-two grid.

## 0.2.4 - 2026-08-08

- Reduced the detached move panel to at most roughly two-thirds of the window width.
- Docked the two-by-two grid to the lower-right, preserving the player's lower-left battle space.
- Retained the separate PP/type card, strong selected frame and responsive integer scaling.
- Removed redundant type abbreviations from the move cards; the selected type remains in the PP card.

## 0.2.3 - 2026-08-08

- Replaced the global wide-battle override with a move-panel-only responsive overlay.
- Added a two-by-two move grid and separate PP/type card over classic and staged voxel battles.
- Added matching two-by-two directional navigation while preserving native move execution.
- Removed only the native move-menu pixels, leaving HUDs, sprites and custom backgrounds untouched.

## 0.2.2 - 2026-08-08

- Added a solid ink-black frame to the selected move button.
- Raised and enlarged selected buttons where the surrounding layout has room.
- Made the default-wide layout yield to active custom world renderers.
- Preserved staged voxel battle backgrounds by retaining their required classic transparent surface.

## 0.2.1 - 2026-08-08

- Made the complete widescreen battle renderer and two-by-two move grid the mod default.
- Added a Move Layout setting: Wide uses the responsive presentation, while Game respects Gen1Recomp's saved preference.
- Kept the PP and type details panel attached to the right side of the wide move grid.

## 0.2.0 - 2026-08-08

- Rebuilt move tints as chamfered button cards matching Modern Party UI.
- Added offset shadows, palette rims, type faces and bright selected states.
- Expanded classic battle moves into four full-width buttons with type labels.
- Added responsive two-column widescreen buttons and cleared the native menu beneath them.
- Updated summary, move-forgetting, Mimic and PP-item menus to use the same button hierarchy.
- Made Bold the default tint strength for visual parity with Modern Party UI.

## 0.1.0 - 2026-08-08

- Added type-coloured move chips to classic and widescreen battles.
- Added colours to Mimic, summary, move-forgetting and PP-item menus.
- Added battle, menu and tint-strength settings to the main Options screen.
- Used only Gen1Recomp's existing named Gen 1 palettes.
