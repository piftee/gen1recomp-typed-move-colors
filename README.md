# Typed Move Colors

Typed Move Colors turns each move into a chamfered type-coloured button while
retaining Pokémon Red, Blue and Yellow's original font and four-shade rendering. Its
layered rim, offset shadow and bright selected state mirror Modern Party UI's
party cards, but the mod also works independently.

## Install

1. Download the `.zip` from the
   [latest release](https://github.com/piftee/gen1recomp-typed-move-colors/releases/latest).
2. Open Gen1Recomp and select **MODS → Import mod .zip**. You can also drag the
   downloaded ZIP onto the launcher window on desktop.
3. Enable **Typed Move Colors**, then open your game.

The ZIP contains only the mod. You still need your own legally obtained Pokémon
Red, Blue, or Yellow ROM imported into
[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).

## Where colours appear

- classic and widescreen battle move selection
- Mimic's move picker
- the Pokémon summary's moves and PP page
- the move-forgetting screen
- Ether, Max Ether and PP Up move selection

The mod reads every move from Gen1Recomp's live merged move registry. Changes
from balance mods, renamed moves and newly registered moves are respected.

## Settings

The following rows appear in the game's normal **OPTIONS** menu and in the
mod's own options page:

| Setting | Choices |
| --- | --- |
| Move Battle | On or off |
| Move Layout | Wide or game |
| Move Effect | On or off |
| Move Menus | On or off |
| Move Tint | Bold or soft |

Move Layout defaults to **Wide**. If Gen1Recomp is already using its wide
battle renderer, the mod decorates that grid. Otherwise the mod adds a
responsive move-only two-by-two panel after the battlefield has been drawn.
The complete selector scales uniformly to nearly the full screen width and
occupies the bottom band beneath the battling Pokémon. Pokémon with one or two
moves use full-height buttons; three or four moves use the two-by-two grid. The
background, sprites and battle HUD remain owned by the game or another renderer
such as a staged voxel battle. **Game** restores the engine's original compact
move list whenever its own Battle Layout setting is `OG`.

Bold mirrors Modern Party UI: unselected buttons use the strong type shade,
while the selected button becomes bright with dark text. Soft keeps every face
on the lighter shade and relies on its selection rail and rim for focus.

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

Each colour receives a lighter selected shade plus the game's paper and ink
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

The Wide setting never enables or replaces Gen1Recomp's battlefield renderer.
Over an `OG` or custom-rendered battle, it removes only the old move-menu pixels
from the transparent UI layer and draws its grid after the final battlefield
composition. Directional input is mapped to the same two-by-two arrangement;
native PP validation and move execution remain unchanged.

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
