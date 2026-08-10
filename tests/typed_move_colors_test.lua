-- Standalone: luajit mods/typed_move_colors/tests/typed_move_colors_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local BattleState = require("src.battle.BattleState")
local Font = require("src.render.Font")
local ListMenu = require("src.ui.ListMenu")
local MoveLearnMenu = require("src.ui.MoveLearnMenu")
local PaletteFX = require("src.render.PaletteFX")
local Runtime = require("src.mods.Runtime")
local SummaryMenu = require("src.ui.SummaryMenu")
local TypeChart = require("src.battle.TypeChart")

local data = T.fixtures.fresh()
data.moves = {
  FIX_FIRE = { name = "EMBER", type = "FIRE", power = 40, pp = 25 },
  FIX_WATER = { name = "WATER GUN", type = "WATER", power = 40, pp = 25 },
  FIX_GRASS = { name = "VINE WHIP", type = "GRASS", power = 40, pp = 10 },
  FIX_ELECTRIC = {
    name = "THUNDERBOLT", type = "ELECTRIC", power = 95, pp = 15,
  },
}
data.type_chart.matchups[#data.type_chart.matchups + 1] = {
  attacker = "ELECTRIC", defender = "GROUND", multiplier = 0,
}
data.type_chart.matchups[#data.type_chart.matchups + 1] = {
  attacker = "ELECTRIC", defender = "FLYING", multiplier = 20,
}
data.type_chart.matchups[#data.type_chart.matchups + 1] = {
  attacker = "GRASS", defender = "FLYING", multiplier = 5,
}
local function pal(light, dark)
  return {
    { 255, 255, 255 }, light, dark, { 0, 0, 0 },
  }
end
data.palettes = {
  palettes = {
    REDMON = pal({ 255, 160, 90 }, { 205, 65, 35 }),
    BLUEMON = pal({ 145, 190, 245 }, { 55, 105, 195 }),
    GREENMON = pal({ 155, 220, 135 }, { 55, 145, 65 }),
    YELLOWMON = pal({ 250, 225, 100 }, { 205, 165, 30 }),
    MEWMON = pal({ 220, 185, 225 }, { 125, 85, 155 }),
  },
  pokemon = {},
}
TypeChart.load(data)
Font.load(data)
local previousMode = PaletteFX.mode
PaletteFX.setMode("gbc")

-- Replace the native bodies before load so the test isolates the mod's
-- additive overlays instead of depending on ROM-backed screen assets.
SummaryMenu.draw = function(self) self.baseDrawn = true end
MoveLearnMenu.draw = function(self) self.baseDrawn = true end
ListMenu.draw = function(self) self.baseDrawn = true end

local run = T.sdk.loadMod("mods/typed_move_colors", { data = data, dev = true })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local schema = run.loader.optionSchemas.typed_move_colors or {}
T.eq(#schema, 5, "all five presentation settings are registered")
T.eq(schema[3].key, "effect_hints",
  "the mod settings page exposes the effectiveness toggle")
T.eq(schema[3].label, "MOVE EFFECT",
  "the mod settings page uses the same Move Effect label")

local current
local stack = {}
function stack:top() return current end
local game = {
  data = run.data,
  save = { options = {} },
  mods = run.loader,
  stack = stack,
}

local rows = Runtime.call("ui.options.rows",
  function(_, base) return base end, game, { { id = "text_speed" } })
T.eq(#rows, 6, "the five settings appear in the main Options menu")
T.eq(rows[2].id, "typed_move_colors_battle_colors",
  "battle colours are the first companion setting")
T.eq(rows[3].id, "typed_move_colors_layout",
  "the responsive move layout is exposed in the main Options menu")
T.eq(rows[3].value(game), "WIDE",
  "the two-by-two widescreen battle layout is the mod default")
T.eq(rows[4].id, "typed_move_colors_effect_hints",
  "effectiveness hints are exposed in the main Options menu")
T.eq(rows[4].value(game), "ON",
  "effectiveness hints are enabled by default")
T.eq(rows[6].value(game), "BOLD",
  "the default tint matches Modern Party UI's card contrast")

local layoutProbe = setmetatable({ game = { save = { options = {
  battleLayout = "og",
} } } }, BattleState)
T.eq(BattleState.wideLayout(layoutProbe), false,
  "the mod does not alter the engine's battlefield renderer")
local inputPatch = rawget(BattleState, "_typedMoveColorsInputPatch")
T.eq(inputPatch.navigate(1, 4, "right"), 2,
  "the detached panel maps RIGHT across its first row")
T.eq(inputPatch.navigate(2, 4, "down"), 4,
  "the detached panel maps DOWN into its second row")

local androidLayout = inputPatch.detachedLayout(1600, 845)
T.eq(androidLayout.scale, 3,
  "a wide, short Android display is height-capped at a crisp 3x scale")
T.eq(androidLayout.panelH * androidLayout.scale, 240,
  "the Android panel no longer grows to the old 400-pixel height")
T.eq(androidLayout.panelW * androidLayout.scale, 1584,
  "height-capped cards expand to retain nearly the complete screen width")
T.eq(androidLayout.originY, 597,
  "the compact Android selector remains docked to the bottom band")
T.eq(androidLayout.leftW + 3 + androidLayout.rightW, 392,
  "the responsive move grid divides all available native width")

local insetLayout = inputPatch.detachedLayout(
  1600, 845, 24, 10, 1552, 805)
T.check(insetLayout.originX >= 24
    and insetLayout.originX + insetLayout.panelW * insetLayout.scale <= 1576,
  "the responsive selector stays inside horizontal device safe areas")
T.check(insetLayout.originY >= 10
    and insetLayout.originY + insetLayout.panelH * insetLayout.scale <= 815,
  "the responsive selector stays above the Android navigation safe area")

local portraitLayout = inputPatch.detachedLayout(360, 800)
T.eq(portraitLayout.scale, 1,
  "a narrow portrait display lets width remain the limiting dimension")
T.check(portraitLayout.panelW <= 344,
  "the narrow layout fits its card geometry inside the available width")

local anchoredPortrait = inputPatch.detachedLayout(
  920, 2048, 0, 0, 920, 2048, 1184)
T.eq(anchoredPortrait.originY, 1184,
  "a tall mobile selector follows the native move row below the player HUD")
T.check(anchoredPortrait.originY + anchoredPortrait.panelH
    * anchoredPortrait.scale < 1500,
  "the portrait selector no longer drops into the touch-control area")
local anchoredLandscape = inputPatch.detachedLayout(
  1600, 845, 0, 0, 1600, 845, 582)
T.eq(anchoredLandscape.originY, 582,
  "landscape keeps the selector close to the native battle controls")
local lowerNativeRow = inputPatch.detachedLayout(
  1600, 845, 0, 0, 1600, 845, 700)
T.eq(lowerNativeRow.originY, androidLayout.originY,
  "the safe-area bottom remains the fallback when it is already closer")

local referenceColors = {
  NORMAL = { 144, 152, 162 }, FIGHTING = { 206, 63, 107 },
  FLYING = { 143, 168, 222 }, POISON = { 171, 106, 200 },
  GROUND = { 217, 119, 70 }, ROCK = { 201, 182, 139 },
  BUG = { 144, 192, 44 }, GHOST = { 82, 105, 173 },
  FIRE = { 254, 156, 85 }, WATER = { 77, 144, 214 },
  GRASS = { 101, 188, 94 }, ELECTRIC = { 244, 210, 59 },
  PSYCHIC_TYPE = { 249, 113, 119 }, ICE = { 115, 206, 191 },
  DRAGON = { 9, 109, 195 }, DARK = { 91, 82, 101 },
  FAIRY = { 236, 144, 231 }, STEEL = { 91, 142, 161 },
}
for typeId, expected in pairs(referenceColors) do
  local actual = inputPatch.colorsFor(game, typeId)[3]
  T.check(actual[1] == expected[1] and actual[2] == expected[2]
      and actual[3] == expected[3],
    typeId .. " uses the exact supplied reference colour")
end
local selectedFire = inputPatch.colorsFor(game, "FIRE")[2]
T.check(selectedFire[1] == 254 and selectedFire[2] == 186
    and selectedFire[3] == 136,
  "selected cards derive a consistent lighter shade from the reference")
local unknownColor = inputPatch.colorsFor(game, "CUSTOM_TYPE")[3]
T.check(unknownColor[1] == 144 and unknownColor[2] == 152
    and unknownColor[3] == 162,
  "unknown content-mod types fall back to the reference Normal colour")
PaletteFX.setMode("og")
T.eq(inputPatch.colorsFor(game, "FIRE"), PaletteFX.GRAYS,
  "monochrome display mode still replaces the custom palette")
PaletteFX.setMode("classic")
T.eq(inputPatch.colorsFor(game, "FIRE"), PaletteFX.CLASSIC,
  "Classic display mode still replaces the custom palette")
PaletteFX.setMode("gbc")
rows[3].step(game, 1)
T.eq(BattleState.wideLayout(layoutProbe), false,
  "GAME mode restores the engine's saved battle-layout preference")
rows[3].step(game, 1) -- restore WIDE for the remaining checks
rows[2].step(game, 1)
T.eq(run.loader.modOptions.typed_move_colors.battle_colors, false,
  "main Options updates the live battle-colour setting")
rows[2].step(game, 1) -- restore ON for drawing checks

local graphics = love.graphics
local realCircle = graphics.circle
local realRectangle = graphics.rectangle
local realPolygon = graphics.polygon
local realSetColor = graphics.setColor
local realTranslate = graphics.translate
local realFontDraw = Font.draw
local realMark = PaletteFX.markTrueColor
local panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
local translations = {}
local activeColor
graphics.setColor = function(r, g, b, a)
  activeColor = { r, g, b, a }
  return realSetColor(r, g, b, a)
end
graphics.rectangle = function(mode, x, y, w, h)
  if mode == "fill" then
    panels[#panels + 1] = { x = x, y = y, w = w, h = h }
  end
  return realRectangle(mode, x, y, w, h)
end
graphics.polygon = function(mode, points)
  buttonLayers[#buttonLayers + 1] = {
    mode = mode, points = points, color = activeColor,
  }
  if realPolygon then return realPolygon(mode, points) end
end
graphics.circle = function(mode, x, y, radius)
  circles[#circles + 1] = {
    mode = mode, x = x, y = y, radius = radius,
  }
  return realCircle(mode, x, y, radius)
end
graphics.translate = function(x, y)
  translations[#translations + 1] = { x = x, y = y }
  return realTranslate(x, y)
end
PaletteFX.markTrueColor = function(x, y, w, h)
  marks[#marks + 1] = { x = x, y = y, w = w, h = h }
end
Font.draw = function(value, x, y)
  text[#text + 1] = { value = value, x = x, y = y }
end

local moves = {
  { id = "FIX_FIRE", pp = 20 },
  { id = "FIX_WATER", pp = 18 },
  { id = "FIX_GRASS", pp = 7 },
  { id = "FIX_ELECTRIC", pp = 12 },
}
local battle = {
  game = game,
  phase = "moveSelect",
  moveIndex = 2,
  player = { curMoves = moves },
  enemy = { curTypes = { "GRASS" } },
  wideLayout = function() return false end,
  drawPicsLayer = function(self, slide, sx, sy, onlySide, skipMenuClip)
    self.restoredPlayerPic = {
      slide = slide, sx = sx, sy = sy,
      onlySide = onlySide, skipMenuClip = skipMenuClip,
    }
  end,
  drawHUDs = function(self, slide)
    self.restoredPlayerHud = { slide = slide }
  end,
}
current = battle
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_FIRE), "double_up",
  "a super-effective attack receives two up arrows")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_WATER), "down",
  "a resisted attack receives one down arrow")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_GRASS), "up",
  "a neutral HP attack receives one up arrow")
T.eq(inputPatch.effectIndicator(battle,
    { type = "NORMAL", power = 0, effect = "SLEEP_EFFECT" }), "circle",
  "a status move receives a circle")
T.eq(inputPatch.effectIndicator(battle,
    { type = "GHOST", power = 0, effect = "SPECIAL_DAMAGE_EFFECT" }), "up",
  "a fixed-damage move receives an HP-effective up arrow")

battle.enemy.curTypes = { "NORMAL", "FLYING" }
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_ELECTRIC), "double_up",
  "Thunderbolt is super effective against a Normal/Flying Pidgey")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_FIRE), "up",
  "Flamethrower is neutral against a Normal/Flying Pidgey")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_WATER), "up",
  "Surf is neutral against a Normal/Flying Pidgey")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_GRASS), "down",
  "Razor Leaf is resisted by a Normal/Flying Pidgey")
battle.enemy.curTypes = { "GRASS" }

local detachedOK, detachedErr = pcall(function()
  Runtime.call("battle.overlay", function() end, battle)
end)
T.check(detachedOK,
  "detached grid erases the native menu safely: " .. tostring(detachedErr))
T.eq(#marks, 0,
  "detached mode leaves the battlefield renderer and palette zones alone")
T.eq(#panels, 2,
  "only the native TYPE/PP and move-menu regions are cleared")
T.eq(battle.restoredPlayerPic.onlySide, "player",
  "standard detached battles restore only the player's sprite")
T.eq(battle.restoredPlayerPic.skipMenuClip, true,
  "the restored standard sprite is no longer clipped by the removed menu")
T.eq(battle.restoredPlayerHud.slide, 0,
  "the erased edge of the live player HP/EXP HUD is restored")

battle.restoredPlayerPic = nil
battle.restoredPlayerHud = nil
battle.dramaticShapeShot = { canvas = true }
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
Runtime.call("battle.overlay", function() end, battle)
T.eq(battle.restoredPlayerPic, nil,
  "a staged voxel battle retains sole ownership of its player Pokemon")
T.eq(battle.restoredPlayerHud, nil,
  "a staged voxel battle retains sole ownership of its player HUD")
battle.dramaticShapeShot = nil

panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
local hudOK, hudErr = pcall(function()
  Runtime.call("render.hud", function() end, game, {
    width = 1024, height = 768,
    gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
    scale = 5,
  })
end)
T.check(hudOK,
  "detached two-by-two move panel draws: " .. tostring(hudErr))
local cardLayers = {}
for _, layer in ipairs(buttonLayers) do
  if #layer.points == 16 then cardLayers[#cardLayers + 1] = layer end
end
T.eq(#cardLayers, 15,
  "four move buttons and one PP/type card use the layered card hierarchy")
T.eq(#marks, 0,
  "the finished-frame panel does not write stale canvas palette marks")
T.eq(cardLayers[5].color[1], 0,
  "the detached selected move also uses the black focus rim")
T.check(cardLayers[3].color[1] == 254 / 255
    and cardLayers[3].color[2] == 156 / 255
    and cardLayers[3].color[3] == 85 / 255,
  "the unselected Fire card face renders with the exact reference colour")
local sawPP, sawSelectedPP = false, false
for _, call in ipairs(text) do
  if call.value == "PP" then sawPP = true end
  if call.value == "18/25" then sawSelectedPP = true end
end
T.check(sawPP and sawSelectedPP,
  "the side details card shows the selected move's current and maximum PP")
T.eq(#circles, 0,
  "ordinary, resisted and super-effective HP attacks use arrows, not circles")
T.eq(#panels, 2,
  "effect arrows use head-only polygons without rectangular stems")
local arrowLayers = {}
for _, layer in ipairs(buttonLayers) do
  if #layer.points == 6 then arrowLayers[#arrowLayers + 1] = layer end
end
T.eq(#arrowLayers, 5,
  "the three single arrows and one double arrow are geometric arrowheads")
T.check(arrowLayers[1].points[1] > 90
    and arrowLayers[1].points[2] > 20,
  "effect indicators sit in the bottom-right corner of their move cards")

buttonLayers = {}
current = { usefulMoveInfoTextBox = true }
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
})
T.eq(#buttonLayers, 0,
  "a modal above the battle suppresses the detached selector")
current = battle

translations = {}
local portraitHudOK, portraitHudErr = pcall(function()
  Runtime.call("render.hud", function() end, game, {
    width = 920, height = 2048,
    gameX = 60, gameY = 664, gameWidth = 800, gameHeight = 720,
    scale = 5,
  })
end)
T.check(portraitHudOK,
  "portrait detached panel draws: " .. tostring(portraitHudErr))
T.eq(translations[1] and translations[1].y, 1184,
  "the rendered portrait panel starts at the native move-menu row")

battle.enemy.curTypes = { "GROUND" }
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_ELECTRIC), "circle",
  "an immune attack receives the same non-HP circle as a status move")
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
})
T.check(#circles > 0,
  "the immune circle is drawn as geometry instead of font text")

rows[4].step(game, 1)
T.eq(run.loader.modOptions.typed_move_colors.effect_hints, false,
  "the main Options toggle disables effect hints")
T.eq(inputPatch.effectIndicator(battle, data.moves.FIX_ELECTRIC), nil,
  "the disabled setting suppresses indicator classification")
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
})
T.eq(#circles, 0,
  "disabled effectiveness hints draw no circle geometry")
T.eq(#buttonLayers, 15,
  "disabled effectiveness hints draw no arrow geometry")
rows[4].step(game, 1) -- restore effect hints
battle.enemy.curTypes = { "GRASS" }

-- GAME restores the original compact overlay when the engine itself is OG.
rows[3].step(game, 1)
panels, buttonLayers, marks, text = {}, {}, {}, {}
local battleOK, battleErr = pcall(function()
  Runtime.call("battle.overlay", function() end, battle)
end)
T.check(battleOK, "classic battle colours draw: " .. tostring(battleErr))
T.eq(#marks, 4, "every battle move receives one protected colour chip")
T.eq(#buttonLayers, 12,
  "each classic move button has shadow, rim and face layers")
T.eq(marks[1].x, 4, "classic buttons use the available full width")
T.eq(marks[1].y, 104, "classic chips follow the first move row")
T.eq(marks[1].w, 152, "classic buttons retain complete move names")
T.eq(marks[2].y, 114, "classic selection follows the live move index")

rows[3].step(game, 1) -- restore WIDE
panels, buttonLayers, marks, text = {}, {}, {}, {}
battle.wideLayout = function() return true end
local wideOK, wideErr = pcall(function()
  Runtime.call("battle.overlay", function() end, battle)
end)
T.check(wideOK, "widescreen battle colours draw: " .. tostring(wideErr))
T.eq(#marks, 4, "the widescreen two-by-two grid colours all four moves")
T.eq(marks[1].x, 4, "the first wide button fills the left move cell")
T.eq(marks[1].w, 104, "the left move cell retains twelve-character names")
T.eq(marks[2].x, 109,
  "the selected wide button rises one pixel beyond its cell")
T.eq(marks[2].w, 112,
  "the selected wide button grows two pixels for dominant focus")
T.eq(marks[2].h, 18,
  "the selected wide button is taller than unselected buttons")
T.eq(buttonLayers[5].color[1], 0,
  "the selected button's outer rim uses the black ink shade")
T.eq(marks[3].y, 124, "the third wide button starts the lower row")
T.eq(marks[1].h, 16, "wide buttons have a full framed card height")

panels, buttonLayers, marks, text = {}, {}, {}, {}
local summary = setmetatable({ game = game, page = 2,
  mon = { moves = moves } }, SummaryMenu)
current = summary
local summaryOK, summaryErr = pcall(summary.draw, summary)
T.check(summaryOK, "summary move colours draw: " .. tostring(summaryErr))
T.check(summary.baseDrawn, "the native summary presentation runs first")
T.eq(#marks, 4, "all four summary rows are tinted")
T.eq(marks[1].x, 8, "summary chips stay inside the native move box")
T.eq(marks[1].w, 144, "summary chips retain room for PP and type")
local sawFireLabel, sawWaterLabel = false, false
for _, call in ipairs(text) do
  if call.value == "FIR" then sawFireLabel = true end
  if call.value == "WTR" then sawWaterLabel = true end
end
T.check(sawFireLabel and sawWaterLabel,
  "summary rows include readable type abbreviations")

panels, buttonLayers, marks, text = {}, {}, {}, {}
local learner = setmetatable({ game = game, selecting = true, index = 2,
  mon = { moves = moves } }, MoveLearnMenu)
current = learner
local learnOK, learnErr = pcall(learner.draw, learner)
T.check(learnOK, "move-forgetting colours draw: " .. tostring(learnErr))
T.check(learner.baseDrawn, "the native move-forgetting screen runs first")
T.eq(#marks, 4, "each forgettable move receives its type chip")
T.eq(marks[1].x, 46, "forgetting chips leave the cursor visible")

panels, buttonLayers, marks, text = {}, {}, {}, {}
local items = {}
for i, move in ipairs(moves) do
  items[i] = { label = data.moves[move.id].name,
    value = i, right = tostring(move.pp) }
end
local list = ListMenu.new(game, "Which move?", items, {})
current = list
local listOK, listErr = pcall(list.draw, list)
T.check(listOK, "PP-item move colours draw: " .. tostring(listErr))
T.check(list.baseDrawn, "the native PP-item picker runs first")
T.eq(#marks, 4, "the PP-item picker discovers every live move definition")
T.eq(marks[1].x, 11,
  "the selected list button rises beyond its normal footprint")
T.eq(marks[1].h, 16,
  "the selected list button grows without entering the next row")
T.eq(marks[2].x, 12,
  "unselected list buttons preserve the list cursor column")

-- A modal above one of the patched menus must own the final pixels. Skipping
-- the underlay prevents a true-colour rectangle from punching through it.
panels, buttonLayers, marks, text = {}, {}, {}, {}
current = { popup = true }
summary:draw()
T.eq(#marks, 0, "covered menu rows do not restore through a popup")

graphics.rectangle = realRectangle
graphics.polygon = realPolygon
graphics.circle = realCircle
graphics.setColor = realSetColor
graphics.translate = realTranslate
Font.draw = realFontDraw
PaletteFX.markTrueColor = realMark
PaletteFX.setMode(previousMode)
run.release()

-- The intended pairing must compose: both mods append Options rows and only
-- Modern Party UI owns PartyMenu, while this mod augments move surfaces.
local comboData = T.fixtures.fresh()
Font.load(comboData)
local combined = T.sdk.loadMods({
  "mods/modern_party_ui", "mods/typed_move_colors",
}, { data = comboData, dev = true })
T.eq(#combined.errors, 0,
  "loads beside Modern Party UI without registry conflicts")
local comboGame = {
  data = combined.data,
  save = { options = {} },
  mods = combined.loader,
}
local comboRows = Runtime.call("ui.options.rows",
  function(_, base) return base end, comboGame, { { id = "text_speed" } })
T.eq(#comboRows, 14,
  "both companions expose all thirteen settings in the main Options menu")
T.check(combined.data.screens and combined.data.screens.PartyMenu ~= nil,
  "Modern Party UI retains sole ownership of the party screen")
combined.release()

-- Useful Move Info registers its own MoveLearnMenu factory, then installs an
-- instance-level draw method for its inspectable NEW MOVE row. Typed Move
-- Colors must compose with that owner and must not paint over its battle
-- TextBox after the finished-frame HUD pass.
local usefulData = T.fixtures.fresh()
usefulData.moves = {
  FIX_FIRE = { name = "EMBER", type = "FIRE", power = 40, pp = 25 },
  FIX_WATER = { name = "WATER GUN", type = "WATER", power = 40, pp = 25 },
  FIX_GRASS = { name = "VINE WHIP", type = "GRASS", power = 35, pp = 10 },
  FIX_ELECTRIC = {
    name = "THUNDERBOLT", type = "ELECTRIC", power = 95, pp = 15,
  },
  FIX_NEW = { name = "BITE", type = "DARK", power = 60, pp = 25 },
}
Font.load(usefulData)
local usefulCombined = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/useful_move_info",
  "mods/typed_move_colors",
}, { data = usefulData, dev = true })
T.eq(#usefulCombined.errors, 0,
  "loads beside Useful Move Info without registry conflicts")
T.eq(usefulCombined.loader.order[1], "useful_move_info",
  "the optional companion loads before its Typed Move Colors adapter")

local usefulTop
local usefulStack = {}
function usefulStack:top() return usefulTop end
local usefulGame = {
  data = usefulCombined.data,
  save = { options = {} },
  mods = usefulCombined.loader,
  stack = usefulStack,
}
local usefulMon = { moves = {
  { id = "FIX_FIRE", pp = 20 },
  { id = "FIX_WATER", pp = 18 },
  { id = "FIX_GRASS", pp = 7 },
  { id = "FIX_ELECTRIC", pp = 12 },
} }
local usefulRecord = usefulCombined.data.screens.MoveLearnMenu
local usefulLearn = usefulRecord.new(
  usefulGame, usefulMon, "FIX_NEW", function() end)
usefulLearn.selecting = true
usefulLearn.index = 5
usefulTop = usefulLearn

local usefulMarks, usefulLabels = {}, {}
local usefulRealMark = PaletteFX.markTrueColor
local usefulRealDraw = Font.draw
PaletteFX.markTrueColor = function(x, y, w, h)
  usefulMarks[#usefulMarks + 1] = { x = x, y = y, w = w, h = h }
end
Font.draw = function(value, x, y)
  usefulLabels[#usefulLabels + 1] = value
  return usefulRealDraw(value, x, y)
end
local usefulDrawOK, usefulDrawErr = pcall(usefulLearn.draw, usefulLearn)
PaletteFX.markTrueColor = usefulRealMark
Font.draw = usefulRealDraw
T.check(usefulDrawOK,
  "Useful Move Info move-learning colours draw: " .. tostring(usefulDrawErr))
T.check(usefulLearn.usefulMoveInfoDrawn,
  "Useful Move Info retains ownership of its instance-level presentation")
T.eq(#usefulMarks, 5,
  "all four current moves and the inspectable NEW MOVE row are coloured")
local sawNewMove = false
for _, label in ipairs(usefulLabels) do
  if label == "BITE NEW" then sawNewMove = true break end
end
T.check(sawNewMove,
  "the coloured added row keeps Useful Move Info's NEW label")

usefulMarks = {}
usefulTop = { usefulMoveInfoTextBox = true }
PaletteFX.markTrueColor = function(x, y, w, h)
  usefulMarks[#usefulMarks + 1] = { x = x, y = y, w = w, h = h }
end
usefulLearn:draw()
PaletteFX.markTrueColor = usefulRealMark
T.eq(#usefulMarks, 0,
  "Useful Move Info's modal remains above the move-learning colours")
usefulCombined.release()

-- Gen 3 Inspired UI Overhaul draws its move selector in final screen pixels
-- after the native battle canvas. Typed Move Colors must yield its detached
-- panel, keep native vertical input semantics, and tint that finished panel
-- only after the companion renderer has run.
local gen3Data = T.fixtures.fresh()
gen3Data.moves = {
  FIX_FIRE = { name = "EMBER", type = "FIRE", power = 40, pp = 25 },
  FIX_WATER = { name = "WATER GUN", type = "WATER", power = 40, pp = 25 },
  FIX_GRASS = { name = "VINE WHIP", type = "GRASS", power = 35, pp = 10 },
  FIX_ELECTRIC = {
    name = "THUNDERBOLT", type = "ELECTRIC", power = 95, pp = 15,
  },
}
Font.load(gen3Data)
local gen3Combined = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/gen3_battle_ui",
  "mods/typed_move_colors",
}, { data = gen3Data, dev = true })
T.eq(#gen3Combined.errors, 0,
  "loads beside Gen 3 Inspired UI Overhaul without hook conflicts")
T.eq(gen3Combined.loader.order[1], "gen3_battle_ui",
  "the Gen 3 companion loads before its Typed Move Colors adapter")

local gen3Battle = {
  phase = "moveSelect",
  moveIndex = 2,
  player = { curMoves = {
    { id = "FIX_FIRE", pp = 20 },
    { id = "FIX_WATER", pp = 18 },
    { id = "FIX_GRASS", pp = 7 },
    { id = "FIX_ELECTRIC", pp = 12 },
  } },
  wideLayout = function() return false end,
}
local gen3Stack = {}
function gen3Stack:top() return gen3Battle end
local gen3Game = {
  data = gen3Combined.data,
  save = { options = {} },
  mods = gen3Combined.loader,
  stack = gen3Stack,
}
gen3Battle.game = gen3Game

local gen3Patch = rawget(BattleState, "_typedMoveColorsInputPatch")
T.eq(gen3Patch.detached(gen3Battle), false,
  "the Gen 3 panel suppresses the duplicate detached selector")

local gen3Graphics = love.graphics
local gen3RealDimensions = gen3Graphics.getDimensions
local gen3RealSetColor = gen3Graphics.setColor
local gen3RealBlend = gen3Graphics.setBlendMode
local gen3RealRectangle = gen3Graphics.rectangle
local gen3RealPolygon = gen3Graphics.polygon
local gen3Blend = "alpha"
local gen3Color = { 1, 1, 1, 1 }
local gen3Rects, gen3Polygons = {}, 0
gen3Graphics.getDimensions = function() return 1280, 720 end
gen3Graphics.setBlendMode = function(mode, alphaMode)
  gen3Blend = mode
  return gen3RealBlend(mode, alphaMode)
end
gen3Graphics.setColor = function(r, g, b, a)
  gen3Color = { r, g, b, a }
  return gen3RealSetColor(r, g, b, a)
end
gen3Graphics.rectangle = function(mode, x, y, w, h, rx, ry)
  gen3Rects[#gen3Rects + 1] = {
    mode = mode, x = x, y = y, w = w, h = h,
    color = gen3Color, blend = gen3Blend,
  }
  return gen3RealRectangle(mode, x, y, w, h, rx, ry)
end
gen3Graphics.polygon = function(...)
  gen3Polygons = gen3Polygons + 1
  if gen3RealPolygon then return gen3RealPolygon(...) end
end

local gen3DrawOK, gen3DrawErr = pcall(function()
  Runtime.call("render.hud", function() end, gen3Game,
    { width = 1280, height = 720 })
end)
gen3Graphics.getDimensions = gen3RealDimensions
gen3Graphics.setColor = gen3RealSetColor
gen3Graphics.setBlendMode = gen3RealBlend
gen3Graphics.rectangle = gen3RealRectangle
gen3Graphics.polygon = gen3RealPolygon

T.check(gen3DrawOK,
  "Gen 3 finished-frame colours draw: " .. tostring(gen3DrawErr))
T.check(gen3Game.gen3FixtureDrawn,
  "the companion retains ownership of its move panel renderer")
local gen3Tints = {}
for _, call in ipairs(gen3Rects) do
  if call.mode == "fill" and call.blend == "multiply" then
    gen3Tints[#gen3Tints + 1] = call
  end
end
T.eq(#gen3Tints, 5,
  "all four Gen 3 move rows and its TYPE/PP strip receive type colour")
T.check(gen3Tints[1].color[1] == 254 / 255
    and gen3Tints[1].color[2] == 156 / 255
    and gen3Tints[1].color[3] == 85 / 255,
  "the Gen 3 Fire row uses the exact bold reference colour")
T.check(gen3Tints[2].color[1] > 77 / 255
    and gen3Tints[5].color[1] == 77 / 255,
  "the selected row stays light while its details strip uses the bold type")
T.eq(gen3Polygons, 0,
  "the old chamfered selector is not drawn beside the Gen 3 panel")
gen3Combined.loader.modOptions.gen3_battle_ui = {
  revampedBattleUI = false,
}
T.eq(gen3Patch.detached(gen3Battle), true,
  "the responsive selector returns when the Gen 3 battle UI is disabled")
gen3Combined.release()

T.finish("typed_move_colors")
