# Typed Move Colors

Typed Move Colors can turn each move into a chamfered type-coloured button or
leave the native interface intact and colour only its move-name text. Both
presentations retain Pokémon Red, Blue and Yellow's original font. The default
card mode uses a layered rim, offset shadow and high-contrast selected state
inspired by Modern Party UI, but the mod also works independently.

Gold, Silver, and Crystal use a dedicated 2×2 type-coloured move grid and
summary swatches while the native Gen 2 move, PP, disable, and selection logic
remains authoritative. Their selected-move panel contains only Power and PP;
the buttons use the same optional effectiveness markers as Red, Blue and
Yellow.

## Install

1. Download the `.zip` from the
   [latest release](https://github.com/piftee/gen1recomp-typed-move-colors/releases/latest).
2. Open Gen1Recomp and select **MODS → Import mod .zip**. You can also drag the
   downloaded ZIP onto the launcher window on desktop.
3. Enable **Typed Move Colors**, then open your game.

The ZIP contains only the mod. You still need your own legally obtained Pokémon
Red, Blue, Yellow, Gold, Silver, or Crystal ROM imported into
[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).

## Where colours appear

- classic and widescreen battle move selection
- Gen 3 Inspired UI Overhaul's battle move panel
- Mimic's move picker
- the Pokémon summary's moves and PP page
- the move-forgetting screen
- Ether, Max Ether and PP Up move selection

The mod reads every move from Gen1Recomp's live merged move registry. Changes
from balance mods, renamed moves and newly registered moves are respected.

## Settings

The game's normal **OPTIONS** menu contains one **TYPED MOVE COLORS → OPEN**
entry. It opens a compact native submenu containing the following settings.
The same settings also remain available on the mod's own options page:

| Setting | Choices |
| --- | --- |
| Move Battle | On or off |
| Move Layout | Wide or game |
| Move Effect | On or off |
| Move Menus | On or off |
| Move Tint | Soft, bold or vibrant |
| Card Opacity | 100%, 85%, 70% or 55% |
| Text Only | On or off |

Text Only defaults to **Off**. Turning it **On** restores the game or active
renderer's original battle layout, boxes, cursors, PP/type panel, selection
style and input behavior. The mod then redraws each move name in a brighter,
paper-readable colour derived from that move's live type. The selected type
value inside the native TYPE/PP panel uses the same colour, while `TYPE/`, PP
values and disabled-state text remain native. Summary, move-learning and
PP-item lists receive the name-only treatment. Normal and unknown custom types
retain the native darkest ink shade. Move Battle and Move Menus continue to
control whether their respective move names are coloured. Other card-specific
settings have no visible effect while Text Only is on.

Move Layout defaults to **Wide**. If Gen1Recomp is already using its wide
battle renderer, the mod decorates that grid. Otherwise the mod adds a
responsive finished-frame battle presentation after the battlefield has been
drawn. FIGHT/PKMN/ITEM/RUN, battle dialogue and the two-by-two move selector
share the same chamfered card language, so choosing FIGHT no longer swaps from
an old Game Boy box into the modern move grid. Pokémon names, levels and HP
bars remain owned by the game or active battle renderer. The WHAT WILL prompt
sits on the left of the four-command grid, following the engine's wide layout.

The complete selector chooses a crisp integer scale from both the available
width and height. On wide, short displays such as Android landscape screens,
it stays within roughly the bottom third and makes the cards wider at the
smaller scale, so it still uses the available width without becoming too tall.
Device safe areas are respected. In flat/OG battles—including WORLD
backgrounds—the cards stay inside the exact presented 160x144 battle rectangle
and start at the native control row beneath the Pokémon composition, retaining
the original eight-pixel separation at native scale. Staged renderers such as
Battle Art retain the wider window-space presentation that follows their own
canvas. Pokémon with one or two moves use full-height buttons; three or four
moves use the two-by-two grid. The background, sprites and battle HUD remain
owned by the game or active renderer. **Game** restores the engine's original
compact move list whenever its own Battle Layout setting is `OG`. On Modern
UI, Potato Voxel and active Dramatic Shape 3D battles, **Game** instead draws
that same compact coloured layout without obsolete native paper/glass panels,
allowing the edited world composition to remain visible.

At very small faithful resolutions—including a Retina 1x window whose 320
physical pixels are only 160 LOVE layout units—the normal two-by-two selector
keeps its full geometry at half scale. Per-axis DPI correction is applied when
the window exposes a high-resolution framebuffer, so the same layout remains
inside the faithful window without clipping or changing grid navigation.

Move cards, summary rows and compatibility rows stay uncluttered and never use
three-letter type abbreviations such as `FGT` or `WTR`. The focused battle
details card shows the selected move's full type name, base Power and PP;
status moves show `---` for Power.

Detached card lettering targets the same final pixel size as the native
Pokémon names. Short labels reach that size directly; long translated move
names wrap across two lines or scale down only as far as the available card
width requires.

Card Opacity controls detached Wide cards and compact custom-renderer GAME
cards without fading their text. The default 100% retains the solid type
treatment; 85%, 70% and 55% let WORLD, voxel and other staged battle scenery
show through the faces and frames. It does not alter summary screens,
move-learning menus or Gen 3 UI-owned panels.

On tall mobile displays, the responsive selector follows the native control
row immediately below the Pokémon composition. It also reads
the live customized touch-control layout and stays above the upper edge of the
D-pad/A/B cluster. That control edge becomes the fallback when a custom battle
renderer cannot provide the normal menu-row anchor.

Bold mirrors Modern Party UI: unselected buttons use the strong reference
type shade. Vibrant keeps the same structure but uses more saturated colours
for stronger type recognition on small and mobile displays; it also feeds the
brighter move and selected-type ink used by Text Only. Soft keeps unselected
faces on the lighter shade.

The selected button uses a darker type face, white text, a thicker black frame
and a white selection rail. All three palettes retain that unmistakable
selected treatment.

## Type palette mapping

The mod ships no image or ROM assets. Its default bold card faces use this
reference-derived palette exactly:

| Type | Colour | Type | Colour | Type | Colour |
| --- | --- | --- | --- | --- | --- |
| Normal | `#9098A2` | Fighting | `#CE3F6B` | Flying | `#8FA8DE` |
| Poison | `#AB6AC8` | Ground | `#D97746` | Rock | `#C9B68B` |
| Bug | `#90C02C` | Ghost | `#5269AD` | Fire | `#FE9C55` |
| Water | `#4D90D6` | Grass | `#65BC5E` | Electric | `#F4D23B` |
| Psychic | `#F97177` | Ice | `#73CEBF` | Dragon | `#096DC3` |
| Dark | `#5B5265` | Fairy | `#EC90E7` | Steel | `#5B8EA1` |

Each colour receives a lighter companion shade plus the game's paper and ink
endpoints. OG Red/Blue/Yellow, monochrome, inverted and Classic display modes
still apply. Dark, Fairy and Steel are ready for content mods; unknown custom
types fall back to Normal.

## Development

Clone this repository into the `mods` directory of a Gen1Recomp checkout:

```sh
git clone https://github.com/piftee/gen1recomp-typed-move-colors.git \
  mods/typed_move_colors
```

Then run:

```sh
python3 tools/modkit.py validate typed_move_colors --base auto
luajit mods/typed_move_colors/tests/typed_move_colors_test.lua
love . --developer
```

Import a legally obtained canonical US Red, Blue or Yellow ROM on first launch.

## Compatibility

Typed Move Colors changes presentation only. It does not replace move records,
effects, PP, damage, targeting or battle input. Mods that add or alter moves are
resolved at draw time. Unknown custom types fall back to a neutral palette.

Text Only is the maximum-compatibility mode for the vanilla interface. It
does not claim or suppress custom battle panels, replace command/dialogue
surfaces, remap movement, draw cards, or alter PP values. Its only addition to
the native details panel is colouring the already-present selected type value.
Custom final-resolution interfaces such as Gen 3 Inspired UI retain their
complete presentation unchanged while this mode is enabled.

The Wide setting never enables or replaces Gen1Recomp's battlefield renderer.
Over an `OG` or custom-rendered battle, it stops the native command, dialogue,
move-list and TYPE/PP boxes before they touch the transparent UI layer, then
draws the matching cards after the final battlefield composition. This avoids
transparent WORLD holes and retained white rectangles instead of erasing a
box after it was rendered. Directional input is mapped to the same two-by-two
arrangement; native commands, PP validation and move execution remain
unchanged. GAME mode retains the engine's complete native presentation unless
an active custom renderer needs the compact paper-free move treatment.

[Useful Move Info](https://github.com/ShaneMcGovernIE/useful-move-info) is an
optional companion. Its Start/Q information box remains above the responsive
selector, and its expanded move-learning list receives coloured current-move
and NEW MOVE rows while retaining the mod's inspection shortcut and behavior.

[Gen 3 Inspired UI Overhaul](https://github.com/HighDrexler/Gen-3-inspired-UI-overhaul-for-Gen1Recomp-V1.1-w-updater)
v1.3.2 is also supported. When its revamped battle UI is enabled, Typed Move
Colors leaves that mod's full-resolution move panel in place and applies the
selected type palette to its four rounded move rows and PP details strip.
The duplicate responsive selector is suppressed, while the overhaul retains
its fonts, spacing, PP readouts and battle controls.

[Modern UI](https://github.com/espinas201-oss/Modern-UI-edit-/releases/tag/Gen1recomp)
is supported through its stable `gen1_modern_ui` package ID. In GAME layout,
Typed Move Colors suppresses the classic white move/details slab and draws
compact type-coloured move and PP cards directly over Modern UI's edited
battle composition. When Modern UI's own full battle presenter is enabled, it
retains ownership of the finished-window presentation.

[Battle Art](https://github.com/absol89/DramaticShapeVoxelMod) v1.8.3 is
supported through its public battle-presentation contract. While the coloured
Wide presentation is active, Battle Art omits the corresponding native text
and backing panels; Typed Move Colors does not erase the transparent arena
canvas or redraw the Pokémon layer. This keeps Battle Art's staged scene and
Crystal Animated sprites intact while its names, levels and HP bars remain
Battle Art-owned.

[Potato Voxel](https://github.com/ShaneMcGovernIE/potato_voxel) is supported
through its exported OverworldBattle module. In Wide mode, Typed Move Colors
suppresses Potato Voxel's obsolete command, dialogue and move-menu glass
rectangles before they are composed, while leaving its world scene, Pokémon
sprites, names, levels and HP bars under Potato Voxel's ownership. GAME also
suppresses only the obsolete move-selection glass and supplies a compact PP
card; Potato's command and dialogue panels remain unchanged.

[Dramatic Shape Voxel Mod](https://github.com/scottcandy34/DramaticShapeVoxelMod-latest)
1.8.x is supported through its exported `OverworldBattle` module. During an
active 3D-BTL shot, GAME omits Dramatic Shape's old move glass while retaining
its world, sprites, Pokémon HUDs, commands and dialogue. With 3D-BTL disabled,
the ordinary GAME selector is left untouched.

Replacement command and move-detail labels use Gen1Recomp's active string
catalog. Power and PP retain one stable font size, stock type names use the
same nine-character reference size, and only longer translated or custom type
names shrink further. Long translated summary move names are scaled to keep
their complete text instead of losing the final characters.

When **Move Effect** is on, each responsive battle button gets a small geometric
indicator in its bottom-right corner: `↑↑` for super-effective, `↑` for
effective, `↓` for not very effective, and `○` for status moves or attacks that
will not affect HP. The arrows are compact head-only pixel shapes rather than
extra font text. The indicator
reads the opponent's current battle types and the live merged type chart, so
Conversion and type-altering mods are respected. Fixed-damage moves and Super
Fang use `↑` because Generation 1 applies their HP damage without scaling it
through the type chart.

## Distribution

From the Gen1Recomp repository root:

```sh
python3 tools/modkit.py lint typed_move_colors
python3 tools/modkit.py pack typed_move_colors -o Typed-Move-Colors.zip
```

The package contains no ROM-derived assets. Source code is available under the
[MIT License](LICENSE). Pokémon and related names and imagery are trademarks of
their respective owners; this is an unofficial fan-made mod.

The compact settings submenu and Vibrant palette were contributed by Haseo,
then adapted to preserve the current Text Only and renderer compatibility paths.
