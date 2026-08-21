# Changelog

## 0.4.1 - 2026-08-21

- Replaced the seven Typed Move Colors rows in the main Options screen with one `TYPED MOVE COLORS → OPEN` entry and a compact native submenu; the regular per-mod settings page remains available.
- Added an optional Vibrant type palette with stronger Fire, Water, Grass, Electric and other type associations while retaining the existing reference-derived Bold palette as the default.
- Applied Vibrant consistently to card fills, Gen 3 UI compatibility and Text Only move/type ink without changing any layout or renderer-ownership rules.
- Kept the established black normal text and white-on-dark selected treatment as the accessibility-safe default rather than exposing combinations that can make bright or dark cards unreadable.
- Adapted and credited Haseo's contributed submenu and Vibrant-palette work for the current Text Only and voxel-compatible codebase.

## 0.4.0 - 2026-08-20

- Added a Text Only option for maximum compatibility with the native battle UI and move-management menus.
- When Text Only is enabled, leaves every native box, cursor, PP value, TYPE/ prompt, selection style, layout and input path unchanged while recolouring the move names and selected type value from each move's live type.
- Uses brighter but paper-readable type-derived ink for Fire, Water, Grass and other type names; Normal and unknown custom types retain the native darkest ink shade.
- Disables detached/compact card ownership, voxel panel suppression, Gen 3 panel tinting, command/dialogue replacement and two-by-two input remapping while Text Only is active.
- Added regression coverage for native classic battle, summary, move-learning and PP-item text-only presentation.

## 0.3.9 - 2026-08-20

- Added Modern UI `gen1_modern_ui` compatibility for GAME layout, suppressing the empty native white move/details slab while retaining compact type-coloured move and PP cards over its edited battle composition.
- Extended paper-free GAME move selection to Potato Voxel and active Dramatic Shape 1.8.x 3D battles through their exported `OverworldBattle` panel seams; their worlds, Pokémon HUDs, commands and dialogue remain renderer-owned.
- Made selection unambiguous with black text on normal cards and white text on a darker selected type face, plus a thicker black focus frame and white selection rail.
- Kept the Card Opacity setting effective on compact custom-renderer cards as well as the Wide detached presentation.
- Added focused regression coverage for Modern UI 0.9.19, Dramatic Shape 1.8.4, Potato Voxel GAME panels and selected-card foreground contrast; the released Dramatic Shape 1.8.4 and 1.8.5 packages were also loaded directly against the adapter.

## 0.3.8 - 2026-08-14

- Preserved complete translated move names on summary rows by using the space freed when redundant type abbreviations were removed and scaling long labels instead of clipping their final characters.
- Routed the replacement FIGHT, PKMN, ITEM, RUN, POWER, PP and COPY labels through the engine string catalog, including fit-safe translated command labels.
- Stabilized Type, Power and PP typography against a nine-character reference so ordinary selection changes no longer make the details-card text jump in size; only longer custom type names shrink further.
- Added Potato Voxel compatibility through its exported OverworldBattle seam, suppressing its obsolete white/glass command, dialogue and move panels while retaining the world scene and Pokémon HUDs.

## 0.3.7 - 2026-08-13

- Constrained the finished-frame controls to the presented 160x144 battle rectangle in flat/OG battles, including WORLD backgrounds, portrait Auto Fill and horizontal letterboxing.
- Lifted flat-battle controls from row 13 to row 12 so their top edge meets the Pokémon composition without an empty strip.
- Scaled short card labels to the native Pokémon-name size and wrapped long translated move names over two lines when that materially improves readability.
- Added a 100%/85%/70%/55% Card Opacity setting for detached battle cards, allowing voxel and WORLD scenes to remain visible beneath the type treatment while text stays fully opaque.
- Retained the existing full-window Wide treatment for Battle Art and other staged/custom battle surfaces.

## 0.3.6 - 2026-08-12

- Stopped native command, dialogue, move-list and TYPE/PP boxes before they draw whenever the mod's Wide presentation owns the phase; this removes retained white slabs, WORLD-shaped holes and old GUI beneath the finished-frame cards.
- Added matching finished-frame FIGHT/PKMN/ITEM/RUN cards and a neutral prompt card in Wide mode while retaining the game or custom renderer's names, levels and HP HUD.
- Added a matching Wide battle-dialogue card so normal battles no longer jump between classic Game Boy boxes and the modern selector.
- Kept native Wide suppression active underneath closing overlays and fades, preventing a final one-frame flash of the old interface as a battle disappears.
- Placed the WHAT WILL prompt card on the left and the four command cards on the right, matching the established wide-battle reading order.
- Expanded the selected-move details card with the full type name, Power and PP; status moves show `---` for Power and three-letter type abbreviations are never used.
- Kept GAME mode, Safari battles, the scripted catching demo and genuinely sub-minimum fallback surfaces on their original native presentation.

## 0.3.5 - 2026-08-12

- Kept the normal detached two-by-two selector at Faithful 1x by fitting its full geometry at half scale, with per-axis DPI correction where the window exposes a high-resolution framebuffer.
- Removed explicit move-type names and three-letter abbreviations from battle buttons, summary rows and companion details; card colour remains the sole type treatment.
- Preserved PP information while removing the repeated TYPE text from both native compact fallback and Gen 3 Inspired UI Overhaul presentations.
- Added Battle Art v1.8.3 presentation-contract support, allowing its native move text and obsolete TYPE/PP backing panel to be suppressed without erasing its transparent arena canvas or redrawing Crystal Animated sprites.
- Anchored portrait selectors above the live customized D-pad/A/B layout when Battle Art or another composition cannot provide the normal battle-row anchor.

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
