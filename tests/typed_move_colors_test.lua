-- Standalone: luajit mods/typed_move_colors/tests/typed_move_colors_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local BattleState = require("src.battle.BattleState")
local Font = require("src.render.Font")
local ListMenu = require("src.ui.ListMenu")
local MoveLearnMenu = require("src.ui.MoveLearnMenu")
local PaletteFX = require("src.render.PaletteFX")
local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")
local SummaryMenu = require("src.ui.SummaryMenu")
local TypeChart = require("src.battle.TypeChart")

local data = T.fixtures.fresh()
data.moves = {
  FIX_FIRE = { name = "EMBER", type = "FIRE", power = 40, pp = 25 },
  FIX_WATER = { name = "WATER GUN", type = "WATER", power = 40, pp = 25 },
  FIX_GRASS = {
    name = "SEMENTE SUGA-VIDA", type = "GRASS", power = 40, pp = 10,
  },
  FIX_ELECTRIC = {
    name = "THUNDERBOLT", type = "ELECTRIC", power = 95, pp = 15,
  },
  FIX_STATUS = { name = "GROWL", type = "NORMAL", power = 0, pp = 40 },
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

local run = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/battle_art_voxel_fork",
  "mods/typed_move_colors",
}, { data = data, dev = true })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local schema = run.loader.optionSchemas.typed_move_colors or {}
T.eq(#schema, 7, "all seven presentation settings are registered")
T.eq(schema[3].key, "effect_hints",
  "the mod settings page exposes the effectiveness toggle")
T.eq(schema[3].label, "MOVE EFFECT",
  "the mod settings page uses the same Move Effect label")
T.eq(schema[7].key, "text_only",
  "the mod settings page exposes the native text-only mode")

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
T.eq(#rows, 8, "the seven settings appear in the main Options menu")
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
T.eq(rows[7].id, "typed_move_colors_opacity",
  "detached battle-card opacity is exposed in the main Options menu")
T.eq(rows[7].value(game), "100%",
  "battle cards remain solid by default")
T.eq(rows[8].id, "typed_move_colors_text_only",
  "text-only compatibility is exposed in the main Options menu")
T.eq(rows[8].value(game), "OFF",
  "the existing card presentation remains the default")

local layoutProbe = setmetatable({ game = { save = { options = {
  battleLayout = "og",
} } } }, BattleState)
T.eq(BattleState.wideLayout(layoutProbe), false,
  "the mod does not alter the engine's battlefield renderer")
local inputPatch = rawget(BattleState, "_typedMoveColorsInputPatch")
local fixedDetailScale, stockTypeScale = inputPatch.detailInkScales(
  "ELECTRIC", 90, 2.5)
local sameFixedScale, longTypeScale = inputPatch.detailInkScales(
  "EXTRA-LONG-TYPE", 90, 2.5)
T.eq(fixedDetailScale, sameFixedScale,
  "Power and PP use one stable nine-character reference scale")
T.eq(stockTypeScale, fixedDetailScale,
  "all stock eight-character type names use the same stable scale")
T.check(longTypeScale < fixedDetailScale,
  "only custom type names beyond nine characters shrink further")
rows[7].step(game, -1)
T.eq(rows[7].value(game), "55%",
  "card opacity can be reduced for voxel and world backgrounds")
T.eq(inputPatch.detachedOpacity(), 0.55,
  "the lowest opacity choice resolves to its exact alpha")
rows[7].step(game, 1) -- restore 100% for baseline drawing checks
T.eq(inputPatch.navigate(1, 4, "right"), 2,
  "the detached panel maps RIGHT across its first row")
T.eq(inputPatch.navigate(2, 4, "down"), 4,
  "the detached panel maps DOWN into its second row")
T.eq(inputPatch.detachedSurfaceFits(160, 144, 1, 1), true,
  "a 160x144 faithful surface retains the normal detached selector")
T.eq(inputPatch.detachedSurfaceFits(140, 144, 1, 1), false,
  "a genuinely sub-minimum surface still uses the compact fallback")
local faithfulLayout = inputPatch.detachedLayout(160, 144)
T.eq(faithfulLayout.scale, 0.5,
  "Faithful 1x uses the normal selector geometry at half scale")
T.check(faithfulLayout.originX >= 0
    and faithfulLayout.originX + faithfulLayout.panelW
      * faithfulLayout.scale <= 160,
  "the half-scale normal selector fits the faithful drawable width")

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
local touchClearedPortrait = inputPatch.detachedLayout(
  360, 800, 0, 0, 360, 800, nil, 653)
T.eq(touchClearedPortrait.originY, 565,
  "portrait fallback docks immediately above the visible touch controls")
T.check(touchClearedPortrait.originY + touchClearedPortrait.panelH
    * touchClearedPortrait.scale < 653,
  "the portrait selector leaves a margin above the D-pad and A/B buttons")

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
local realScale = graphics.scale
local realNewShader = graphics.newShader
local realFontDraw = Font.draw
local realMark = PaletteFX.markTrueColor
local panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
local translations, scales = {}, {}
local activeColor
-- Headless LOVE has no shader compiler. Supply a harmless shader token so
-- the test can observe the requested foreground colours used by drawInk.
graphics.newShader = function() return {} end
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
graphics.scale = function(x, y)
  scales[#scales + 1] = { x = x, y = y }
  return realScale(x, y)
end
PaletteFX.markTrueColor = function(x, y, w, h)
  marks[#marks + 1] = { x = x, y = y, w = w, h = h }
end
Font.draw = function(value, x, y)
  text[#text + 1] = {
    value = value, x = x, y = y, color = activeColor,
  }
end

local moves = {
  { id = "FIX_FIRE", pp = 20 },
  { id = "FIX_WATER", pp = 18 },
  { id = "FIX_GRASS", pp = 7 },
  { id = "FIX_ELECTRIC", pp = 12 },
}
local battle = {
  game = game,
  data = game.data,
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

-- TEXT ONLY is a maximum-compatibility presentation: all native geometry,
-- labels, cursors and input stay in charge while move-name and selected-type
-- glyphs are redrawn with brighter, readable type ink.
rows[8].step(game, 1)
T.eq(rows[8].value(game), "ON",
  "the main Options row enables text-only compatibility live")
T.eq(inputPatch.detached(battle), false,
  "text-only mode never activates the detached Wide selector")
T.eq(inputPatch.replacementPresentationOwnsPhase(battle), false,
  "text-only mode never claims a native or voxel battle surface")
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
BattleState.drawTextArea(battle)
T.check(#panels > 0,
  "text-only mode leaves the complete native move GUI drawing intact")
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
Runtime.call("battle.overlay", function() end, battle)
T.eq(#buttonLayers, 0,
  "text-only mode draws no replacement card geometry")
T.eq(#panels, 0,
  "text-only mode neither clears nor repaints native panel rectangles")
T.eq(#marks, 5,
  "text-only mode recolours four move names and the selected type value")
T.eq(marks[1].x, 48,
  "text-only battle ink starts at the native move-name column")
T.eq(marks[1].y, 104,
  "text-only battle ink follows the native first move row")
T.check(text[1] and text[1].value == "EMBER"
    and text[1].color[1] == 165 / 255
    and text[1].color[2] == 101 / 255
    and text[1].color[3] == 55 / 255,
  "Fire names use a brighter readable form of the live Fire palette")
T.check(text[2] and text[2].value == "WATER GUN"
    and text[2].color[1] == 50 / 255
    and text[2].color[2] == 94 / 255
    and text[2].color[3] == 139 / 255,
  "Water names use a brighter readable form of the live Water palette")
T.check(text[5] and text[5].value == "WATER"
    and text[5].x == 16 and text[5].y == 80
    and text[5].color[1] == text[2].color[1]
    and text[5].color[2] == text[2].color[2]
    and text[5].color[3] == text[2].color[3],
  "the native TYPE/PP panel links the selected type word to its move colour")
buttonLayers = {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
})
T.eq(#buttonLayers, 0,
  "text-only mode cannot draw detached or compatibility-owned cards")
rows[8].step(game, 1)
T.eq(rows[8].value(game), "OFF",
  "text-only compatibility can be disabled live")
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}

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
  "detached grid leaves the battle canvas untouched: " .. tostring(detachedErr))
T.eq(#marks, 0,
  "detached mode leaves the battlefield renderer and palette zones alone")
T.eq(#panels, 0,
  "detached mode does not erase TYPE/PP or move-menu rectangles afterward")
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "Wide suppresses the complete native move GUI before any box is drawn")
T.eq(battle.restoredPlayerPic.onlySide, "player",
  "flat detached battles restore only the natively clipped player sprite")
T.eq(battle.restoredPlayerPic.skipMenuClip, true,
  "the restored flat-battle sprite is complete without a TYPE/PP clip")
T.eq(battle.restoredPlayerHud, nil,
  "no post-erasure HUD redraw is necessary")

battle.restoredPlayerPic = nil
battle.restoredPlayerHud = nil
battle.dramaticShapeShot = { canvas = true }
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
Runtime.call("battle.overlay", function() end, battle)
T.eq(#panels, 0,
  "Battle Art battles never erase or repaint its transparent UI canvas")
T.eq(battle.restoredPlayerPic, nil,
  "a staged voxel battle retains sole ownership of its player Pokemon")
T.eq(battle.restoredPlayerHud, nil,
  "a staged voxel battle retains sole ownership of its player HUD")

inputPatch.trackPresentationBattle(battle)
local presentation = run.loader.exports.BATTLE_ART_VOXEL_FORK
  .battlePresentation
local textClaim = Runtime.call(presentation.suppressHook,
  function() return false end, {
    apiVersion = 1,
    sourceModId = "BATTLE_ART_VOXEL_FORK",
    surface = "text",
    battle = battle,
  })
local panelClaim = Runtime.call(presentation.suppressHook,
  function() return false end, {
    apiVersion = 1,
    sourceModId = "BATTLE_ART_VOXEL_FORK",
    surface = "panels",
  })
local hudClaim = Runtime.call(presentation.suppressHook,
  function() return false end, {
    apiVersion = 1,
    sourceModId = "BATTLE_ART_VOXEL_FORK",
    surface = "hud",
    battle = battle,
  })
T.eq(textClaim, true,
  "Battle Art yields its native move-menu text to the detached selector")
T.eq(panelClaim, true,
  "Battle Art omits the obsolete TYPE/PP backing panel during selection")
T.eq(hudClaim, false,
  "Battle Art retains ownership of Pokemon names, levels and HP bars")
translations, scales = {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
T.check((translations[1] and translations[1].x or 999) < 112,
  "Battle Art retains its established full-window Wide presentation")
battle.dramaticShapeShot = nil

-- A macOS Faithful 1x window is only 160 drawable units even when the OS
-- captures it at 320 Retina pixels. Keep the normal two-by-two selector and
-- its grid input, but render that same geometry at half scale.
local realDimensions = graphics.getDimensions
local realPixelDimensions = graphics.getPixelDimensions
local realSafeArea = love.window and love.window.getSafeArea
graphics.getDimensions = function() return 160, 144 end
graphics.getPixelDimensions = function() return 160, 144 end
if love.window then
  love.window.getSafeArea = function() return 0, 0, 160, 144 end
end
battle.restoredPlayerPic = nil
battle.restoredPlayerHud = nil
panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
local faithfulOK, faithfulErr = pcall(function()
  Runtime.call("battle.overlay", function() end, battle)
end)
T.check(faithfulOK,
  "Faithful 1x presentation succeeds: " .. tostring(faithfulErr))
T.eq(#marks, 0,
  "Faithful 1x keeps move cards in the normal finished-frame selector")
T.eq(#panels, 0,
  "Faithful 1x never writes transparent cleanup rectangles into the battle")
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "Faithful 1x suppresses native TYPE/PP and move boxes before drawing")
T.check(battle.restoredPlayerPic ~= nil,
  "Faithful 1x retains the complete standard player sprite")

buttonLayers, translations, scales = {}, {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 160, height = 144,
  gameX = 0, gameY = 0, gameWidth = 160, gameHeight = 144,
  scale = 1, dpiX = 1, dpiY = 1,
})
local faithfulCards = {}
for _, layer in ipairs(buttonLayers) do
  if #layer.points == 16 then faithfulCards[#faithfulCards + 1] = layer end
end
T.eq(#faithfulCards, 15,
  "Faithful 1x retains four normal move cards and the PP details card")
T.eq(scales[1] and scales[1].x, 0.5,
  "Faithful 1x applies the normal selector's half-scale transform")
T.check((translations[1] and translations[1].x or -1) >= 0,
  "Faithful 1x normal selector starts inside the drawable")

graphics.getDimensions = function() return 140, 144 end
graphics.getPixelDimensions = function() return 140, 144 end
if love.window then
  love.window.getSafeArea = function() return 0, 0, 140, 144 end
end
T.eq(inputPatch.detached(battle), false,
  "a truly sub-minimum window uses the compact fallback")
panels = {}
Runtime.call("battle.overlay", function() end, battle)
local sawCompactTypeMask = false
for _, panel in ipairs(panels) do
  if panel.x == 8 and panel.y == 72
      and panel.w == 72 and panel.h == 16 then
    sawCompactTypeMask = true
    break
  end
end
T.check(sawCompactTypeMask,
  "the compact fallback erases native TYPE text while preserving its PP row")
graphics.getDimensions = realDimensions
graphics.getPixelDimensions = realPixelDimensions
if love.window then love.window.getSafeArea = realSafeArea end

panels, buttonLayers, circles, marks, text = {}, {}, {}, {}, {}
local hudOK, hudErr = pcall(function()
  translations, scales = {}, {}
  Runtime.call("render.hud", function() end, game, {
    width = 1024, height = 768,
    gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
    scale = 5,
  })
end)
T.check(hudOK,
  "detached two-by-two move panel draws: " .. tostring(hudErr))
T.check((translations[1] and translations[1].x or 0) >= 112,
  "flat OG battle controls start inside the presented 160x144 battle area")
T.check((translations[1].x + 392 * (scales[1] and scales[1].x or 0)) <= 912,
  "flat OG battle controls end inside the presented 160x144 battle area")
T.eq(translations[1] and translations[1].y, 504,
  "flat OG controls rise to meet the Pokemon composition at row 12")
T.eq(scales[1] and scales[1].x, 2,
  "flat OG controls size from the battle area rather than the full window")
T.eq((scales[1] and scales[1].x or 0)
    * (scales[2] and scales[2].x or 0), 5,
  "short card labels match the native Pokemon-name pixel scale")
local cardLayers = {}
for _, layer in ipairs(buttonLayers) do
  if #layer.points == 16 then cardLayers[#cardLayers + 1] = layer end
end
T.eq(#cardLayers, 15,
  "four move buttons and one PP card use the layered card hierarchy")
T.eq(#marks, 0,
  "the finished-frame panel does not write stale canvas palette marks")
T.eq(cardLayers[5].color[1], 0,
  "the detached selected move also uses the black focus rim")
T.check(cardLayers[6].color[1] == 42 / 255
    and cardLayers[6].color[2] == 79 / 255
    and cardLayers[6].color[3] == 118 / 255,
  "the selected Water card uses a dark type face behind white text")
T.check(cardLayers[3].color[1] == 254 / 255
    and cardLayers[3].color[2] == 156 / 255
    and cardLayers[3].color[3] == 85 / 255,
  "the unselected Fire card face renders with the exact reference colour")
local sawSelectedPP = false
local sawFullType, sawPower = false, false
local sawAbbreviatedType = false
local sawLongFirst, sawLongSecond = false, false
local sawBlackNormalText, sawWhiteSelectedText = false, false
for _, call in ipairs(text) do
  if call.value == "PP 18/25" then sawSelectedPP = true end
  if call.value == "WATER" then sawFullType = true end
  if call.value == "POWER 40" then sawPower = true end
  if call.value == "SEMENTE" then sawLongFirst = true end
  if call.value == "SUGA-VIDA" then sawLongSecond = true end
  if call.value == "EMBER" and call.color
      and call.color[1] == 0 and call.color[2] == 0
      and call.color[3] == 0 then
    sawBlackNormalText = true
  end
  if call.value == "WATER GUN" and call.color
      and call.color[1] == 1 and call.color[2] == 1
      and call.color[3] == 1 then
    sawWhiteSelectedText = true
  end
  if call.value == "WTR" or call.value == "FGT"
      or call.value == "TYPE/" then
    sawAbbreviatedType = true
  end
end
T.check(sawSelectedPP,
  "the side details card shows the selected move's current and maximum PP")
T.check(sawFullType and sawPower,
  "the side details card shows the full move type and base power")
T.eq(sawAbbreviatedType, false,
  "the side details card never falls back to three-letter type labels")
T.check(sawLongFirst and sawLongSecond,
  "long translated move names wrap to retain a readable font size")
T.check(sawBlackNormalText and sawWhiteSelectedText,
  "normal move text is black while the selected move text is white")

rows[7].step(game, 2) -- 100% -> 70%
panels, buttonLayers = {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
local sawTranslucentFace = false
for _, layer in ipairs(buttonLayers) do
  if layer.mode == "fill" and layer.color[4] == 0.7 then
    sawTranslucentFace = true
    break
  end
end
T.eq(sawTranslucentFace, true,
  "the 70% option draws detached card faces at exactly 70% alpha")
rows[7].step(game, -2) -- restore 100%
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

local selectedWater = moves[2]
moves[2] = { id = "FIX_STATUS", pp = 39 }
text, buttonLayers = {}, {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
local sawNoBasePower = false
for _, call in ipairs(text) do
  if call.value == "POWER ---" then sawNoBasePower = true end
end
T.eq(sawNoBasePower, true,
  "status moves show a dash instead of a misleading zero base power")
moves[2] = selectedWater

-- WIDE owns the preceding command phase too, so selecting FIGHT no longer
-- swaps from a classic Game Boy menu into the finished-frame move selector.
battle.phase = "menu"
battle.menuIndex = 3
panels, buttonLayers, text = {}, {}, {}
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "Wide suppresses the native FIGHT/PKMN/ITEM/RUN box before drawing")
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
local sawFight, sawPkmn, sawItem, sawRun = false, false, false, false
for _, call in ipairs(text) do
  if call.value == "FIGHT" then sawFight = true end
  if call.value == "PKMN" then sawPkmn = true end
  if call.value == "ITEM" then sawItem = true end
  if call.value == "RUN" then sawRun = true end
end
T.check(sawFight and sawPkmn and sawItem and sawRun,
  "the finished-frame Wide command panel draws all four native actions")
T.eq(#buttonLayers, 15,
  "four command cards and one prompt card share the move selector hierarchy")
local fightX = buttonLayers[1] and buttonLayers[1].points[1]
local promptX = buttonLayers[13] and buttonLayers[13].points[1]
T.check(promptX and fightX and promptX < fightX,
  "the WHAT WILL prompt card sits to the left of the action grid")

-- Replacement labels must read the engine string catalog at draw time so a
-- translation mod does not fall back to English inside Typed Move Colors.
game.data.strings = game.data.strings or {}
game.data.strings["battle|FIGHT"] = "LUTAR"
game.data.strings.PKMN = "POKEMON"
game.data.strings["battle|ITEM"] = "ITENS"
game.data.strings["battle|RUN"] = "FUGIR"
game.data.strings.POWER = "PODER"
Strings.load(game.data)
text = {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
local translated, translatedValues = {}, {}
for _, call in ipairs(text) do
  translated[call.value] = true
  translatedValues[#translatedValues + 1] = tostring(call.value)
end
T.check(translated.LUTAR and translated.POKEMON
    and translated.ITENS and translated.FUGIR,
  "Wide command labels use the active engine translation catalog ("
    .. table.concat(translatedValues, ", ") .. ")")

battle.phase = "moveSelect"
text = {}
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
translated = {}
for _, call in ipairs(text) do translated[call.value] = true end
T.eq(translated["PODER 40"], true,
  "the details-card Power label uses the active translation catalog")
battle.phase = "menu"
game.data.strings["battle|FIGHT"] = nil
game.data.strings.PKMN = nil
game.data.strings["battle|ITEM"] = nil
game.data.strings["battle|RUN"] = nil
game.data.strings.POWER = nil
Strings.load(game.data)

-- A transition/modal may become topmost while the battle is still included
-- in the visible stack for one closing draw. The native battle canvas must
-- stay suppressed underneath it even though the modern controls are hidden.
current = { closingTransition = true }
panels = {}
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "closing overlays cannot expose one final native command-menu frame")
current = battle

battle.phase = "messages"
battle.current = { text = true }
battle.shown = {}
panels, buttonLayers = {}, {}
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "Wide suppresses the native battle dialogue slab before drawing")
Runtime.call("render.hud", function() end, game, {
  width = 1024, height = 768,
  gameX = 112, gameY = 24, gameWidth = 800, gameHeight = 720,
  scale = 5,
})
T.eq(#buttonLayers, 3,
  "battle dialogue uses one neutral finished-frame card in Wide mode")
battle.current = nil
battle.shown = nil
battle.phase = "moveSelect"

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
T.eq(translations[1] and translations[1].y, 1144,
  "the rendered portrait panel rises to the Pokemon edge at row 12")

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
BattleState.drawTextArea(battle)
T.check(#panels > 0,
  "GAME mode leaves native move GUI drawing completely unchanged")
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

-- A staged renderer has transparent world pixels where the native paper box
-- used to be. In GAME, replace only its compact move phase so cleanup cannot
-- leave the empty white TYPE/PP slab reported with Potato Voxel.
battle.dramaticShapeShot = { canvas = true }
battle.letterboxWhite = false
panels, buttonLayers, marks, text = {}, {}, {}, {}
BattleState.drawTextArea(battle)
T.eq(#panels, 0,
  "GAME suppresses the native move box on a transparent battle surface")
local compactTextClaim = Runtime.call(presentation.suppressHook,
  function() return false end, {
    apiVersion = 1,
    sourceModId = "BATTLE_ART_VOXEL_FORK",
    surface = "text",
    battle = battle,
  })
T.eq(compactTextClaim, true,
  "GAME claims a staged renderer's obsolete native move text")
Runtime.call("battle.overlay", function() end, battle)
T.eq(#marks, 5,
  "transparent GAME draws four compact moves and one PP card")
T.eq(#buttonLayers, 15,
  "transparent GAME uses complete layered cards without a paper backing")
local sawPaperCleanup, sawCompactPP = false, false
for _, panel in ipairs(panels) do
  if (panel.x == 0 and panel.y == 104
      and panel.w == 160 and panel.h == 40)
      or (panel.x == 8 and panel.y == 72
        and panel.w == 72 and panel.h == 16) then
    sawPaperCleanup = true
  end
end
for _, call in ipairs(text) do
  if call.value == "PP 18/25" then sawCompactPP = true end
end
T.eq(sawPaperCleanup, false,
  "transparent GAME never paints the old white move or TYPE regions")
T.eq(sawCompactPP, true,
  "transparent GAME retains PP in a compact type-coloured card")
battle.dramaticShapeShot = nil
battle.letterboxWhite = nil

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

rows[8].step(game, 1)
panels, buttonLayers, marks, text = {}, {}, {}, {}
Runtime.call("battle.overlay", function() end, battle)
T.eq(#buttonLayers, 0,
  "text-only mode leaves the native Wide move grid card-free")
T.eq(#marks, 5,
  "text-only Wide colours four names and its selected type value")
T.eq(marks[1].x, 16,
  "text-only Wide uses the native first move-name column")
T.check(text[5] and text[5].value == "WATER"
    and text[5].x == 232 and text[5].y == 128,
  "text-only Wide colours the native selected-type details value")
rows[8].step(game, 1)

panels, buttonLayers, marks, text = {}, {}, {}, {}
local summary = setmetatable({ game = game, page = 2,
  mon = { moves = moves } }, SummaryMenu)
current = summary
local summaryOK, summaryErr = pcall(summary.draw, summary)
T.check(summaryOK, "summary move colours draw: " .. tostring(summaryErr))
T.check(summary.baseDrawn, "the native summary presentation runs first")
T.eq(#marks, 4, "all four summary rows are tinted")
T.eq(marks[1].x, 8, "summary chips stay inside the native move box")
T.eq(marks[1].w, 144, "summary chips retain room for PP")
local sawTypeLabel = false
local sawCompleteTranslatedName = false
for _, call in ipairs(text) do
  if call.value == "FIR" or call.value == "WTR"
      or call.value == "FGT" or call.value == "NRM" then
    sawTypeLabel = true
  end
  if call.value == "SEMENTE SUGA-VIDA" then
    sawCompleteTranslatedName = true
  end
end
T.eq(sawTypeLabel, false,
  "summary rows never print redundant type abbreviations")
T.eq(sawCompleteTranslatedName, true,
  "summary rows preserve the complete translated move name")

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

-- The compatibility option applies the same name-only treatment to native
-- move-management screens without tinting their PP, cursors or boxes.
rows[8].step(game, 1)
panels, buttonLayers, marks, text = {}, {}, {}, {}
current = summary
summary:draw()
T.eq(#buttonLayers, 0,
  "text-only summary keeps the native move/PP rows card-free")
T.eq(#marks, 4,
  "text-only summary recolours its four move names")
T.eq(marks[1].x, 16,
  "text-only summary uses the native move-name column")

panels, buttonLayers, marks, text = {}, {}, {}, {}
current = learner
learner:draw()
T.eq(#buttonLayers, 0,
  "text-only move learning keeps the native list and cursor")
T.eq(#marks, 4,
  "text-only move learning recolours its four move names")
T.eq(marks[1].x, 48,
  "text-only move learning uses the native move-name column")

panels, buttonLayers, marks, text = {}, {}, {}, {}
current = list
list:draw()
T.eq(#buttonLayers, 0,
  "text-only PP-item selection keeps the native list presentation")
T.eq(#marks, 4,
  "text-only PP-item selection recolours only its move names")
T.eq(marks[1].x, 16,
  "text-only PP-item names retain the native list alignment")
local recoloredPP = false
for _, call in ipairs(text) do
  if call.value == tostring(moves[1].pp) then recoloredPP = true end
end
T.eq(recoloredPP, false,
  "text-only PP-item selection does not recolour the PP column")
rows[8].step(game, 1)

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
graphics.scale = realScale
graphics.newShader = realNewShader
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
T.eq(#comboRows, 16,
  "both companions expose all fifteen settings in the main Options menu")
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
  "all four Gen 3 move rows and its PP strip receive type colour")
T.check(gen3Tints[1].color[1] == 254 / 255
    and gen3Tints[1].color[2] == 156 / 255
    and gen3Tints[1].color[3] == 85 / 255,
  "the Gen 3 Fire row uses the exact bold reference colour")
T.check(gen3Tints[2].color[1] > 77 / 255
    and gen3Tints[5].color[1] == 77 / 255,
  "the selected row stays light while its details strip uses the bold type")
local sawGen3TypeMask, sawGen3Tint = false, false
for _, call in ipairs(gen3Rects) do
  if call.mode == "fill" and call.blend == "multiply" then
    sawGen3Tint = true
  elseif sawGen3Tint and call.mode == "fill" and call.blend == "alpha"
      and call.x > 100 and call.w > 0 then
    sawGen3TypeMask = true
  end
end
T.check(sawGen3TypeMask,
  "the Gen 3 details strip removes repeated TYPE text but preserves PP")
T.eq(gen3Polygons, 0,
  "the old chamfered selector is not drawn beside the Gen 3 panel")
gen3Combined.loader.modOptions.gen3_battle_ui = {
  revampedBattleUI = false,
}
T.eq(gen3Patch.detached(gen3Battle), true,
  "the responsive selector returns when the Gen 3 battle UI is disabled")
gen3Combined.release()

-- Potato Voxel renders glass panels from its exported textRects list before
-- the native drawTextArea method runs. Typed Move Colors filters those text
-- surfaces while either Wide or the transparent GAME presentation owns the
-- phase, leaving Potato's separate Pokemon HUD surfaces untouched.
local potatoData = T.fixtures.fresh()
Font.load(potatoData)
local potatoCombined = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/potato_voxel",
  "mods/typed_move_colors",
}, { data = potatoData, dev = true })
T.eq(#potatoCombined.errors, 0,
  "loads beside Potato Voxel without compatibility errors")
T.eq(potatoCombined.loader.order[1], "potato_voxel",
  "Potato Voxel loads before its Typed Move Colors adapter")

local potatoBattle = {
  phase = "moveSelect",
  moveIndex = 1,
  player = { curMoves = {} },
  letterboxWhite = false,
  wideLayout = function() return false end,
}
local potatoStack = {}
function potatoStack:top() return potatoBattle end
local potatoGame = {
  data = potatoCombined.data,
  save = { options = {} },
  mods = potatoCombined.loader,
  stack = potatoStack,
}
potatoBattle.game = potatoGame
local potatoModule = potatoCombined.loader.exports.potato_voxel
  .overworldBattle
T.eq(rawget(BattleState, "_typedMoveColorsInputPatch")
    .potatoTextRectsPatched, true,
  "the Potato Voxel text-panel compatibility seam is installed")
T.eq(next(potatoModule.textRects(potatoBattle)), nil,
  "Wide suppresses Potato Voxel's obsolete white/glass move panel")

potatoCombined.loader.modOptions.typed_move_colors = { layout = "game" }
T.eq(next(potatoModule.textRects(potatoBattle)), nil,
  "GAME mode also suppresses Potato Voxel's obsolete move-panel glass")
potatoBattle.phase = "menu"
local nativePotatoRects = potatoModule.textRects(potatoBattle)
T.check(nativePotatoRects.box ~= nil,
  "GAME commands retain Potato Voxel's renderer-owned text panel")
potatoCombined.release()

-- Dramatic Shape 1.8.x publishes the same OverworldBattle module. Its staged
-- shot marker scopes the GAME replacement to active 3D battles, so disabling
-- 3D-BTL returns the ordinary native selector.
local dramaticData = T.fixtures.fresh()
Font.load(dramaticData)
local dramaticCombined = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/dramatic_shape",
  "mods/typed_move_colors",
}, { data = dramaticData, dev = true })
T.eq(#dramaticCombined.errors, 0,
  "loads beside Dramatic Shape 1.8.4 without compatibility errors")
T.eq(dramaticCombined.loader.order[1], "DRAMATIC_SHAPE",
  "Dramatic Shape loads before its Typed Move Colors adapter")
dramaticCombined.loader.modOptions.typed_move_colors = { layout = "game" }

local dramaticBattle = {
  phase = "moveSelect",
  moveIndex = 1,
  player = { curMoves = {} },
  dramaticShapeShot = { canvas = true, scale = 4 },
  letterboxWhite = false,
  wideLayout = function() return false end,
}
local dramaticStack = {}
function dramaticStack:top() return dramaticBattle end
local dramaticGame = {
  data = dramaticCombined.data,
  save = { options = {} },
  mods = dramaticCombined.loader,
  stack = dramaticStack,
}
dramaticBattle.game = dramaticGame
local dramaticModule = dramaticCombined.loader.exports.DRAMATIC_SHAPE
  .overworldBattle
local dramaticPatch = rawget(BattleState, "_typedMoveColorsInputPatch")
T.eq(dramaticPatch.dramaticTextRectsPatched, true,
  "Dramatic Shape's exported text-panel seam is installed")
T.eq(next(dramaticModule.textRects(dramaticBattle)), nil,
  "Dramatic Shape GAME omits its obsolete white/glass move panels")
dramaticBattle.phase = "menu"
T.check(dramaticModule.textRects(dramaticBattle).box ~= nil,
  "Dramatic Shape GAME retains its command and dialogue glass")
dramaticBattle.phase = "moveSelect"
dramaticBattle.dramaticShapeShot = nil
dramaticBattle.letterboxWhite = nil
local flatDramaticRects = dramaticModule.textRects(dramaticBattle)
T.check(flatDramaticRects.box ~= nil and flatDramaticRects.moves ~= nil,
  "Dramatic Shape with 3D-BTL off retains the ordinary GAME selector")
dramaticCombined.release()

-- Modern UI edits the final battle composition even when its full WIP battle
-- presenter is not selected. In GAME mode, omit the native paper selector and
-- draw the compact typed cards directly over that composition.
local modernData = T.fixtures.fresh()
modernData.moves.FIX_WATER = {
  name = "WATER GUN", type = "WATER", power = 40, pp = 25,
}
Font.load(modernData)
local modernCombined = T.sdk.loadMods({
  "mods/typed_move_colors/tests/fixtures/gen1_modern_ui",
  "mods/typed_move_colors",
}, { data = modernData, dev = true })
T.eq(#modernCombined.errors, 0,
  "loads beside Modern UI without compatibility errors")
T.eq(modernCombined.loader.order[1], "gen1_modern_ui",
  "Modern UI loads before its Typed Move Colors adapter")
modernCombined.loader.modOptions.typed_move_colors = { layout = "game" }

local modernBattle = {
  phase = "moveSelect",
  moveIndex = 1,
  player = { curMoves = { { id = "FIX_WATER", pp = 18 } } },
  wideLayout = function() return false end,
}
local modernStack = {}
function modernStack:top() return modernBattle end
local modernGame = {
  data = modernCombined.data,
  save = { options = {} },
  mods = modernCombined.loader,
  stack = modernStack,
}
modernBattle.game = modernGame
local modernPatch = rawget(BattleState, "_typedMoveColorsInputPatch")
T.eq(modernPatch.gen1ModernUIInstalled(), true,
  "the active Modern UI package is detected by its stable mod id")
T.eq(modernPatch.customBattleSurface(modernBattle), true,
  "Modern UI's edited battle is treated as a custom composition")
T.eq(modernPatch.compactPresentationOwnsPhase(modernBattle), true,
  "GAME mode owns move selection over Modern UI without native paper")

local modernRects, modernPolygons = {}, 0
local modernRealRectangle = love.graphics.rectangle
local modernRealPolygon = love.graphics.polygon
love.graphics.rectangle = function(mode, x, y, w, h, ...)
  if mode == "fill" then
    modernRects[#modernRects + 1] = { x = x, y = y, w = w, h = h }
  end
  return modernRealRectangle(mode, x, y, w, h, ...)
end
love.graphics.polygon = function(mode, points)
  modernPolygons = modernPolygons + 1
  if modernRealPolygon then return modernRealPolygon(mode, points) end
end
BattleState.drawTextArea(modernBattle)
T.eq(#modernRects, 0,
  "Modern UI GAME selection suppresses the native white details slab")
Runtime.call("battle.overlay", function() end, modernBattle)
local modernPaperCleanup = false
for _, rect in ipairs(modernRects) do
  if (rect.x == 0 and rect.y == 104 and rect.w == 160 and rect.h == 40)
      or (rect.x == 8 and rect.y == 72
        and rect.w == 72 and rect.h == 16) then
    modernPaperCleanup = true
  end
end
T.eq(modernPaperCleanup, false,
  "Modern UI GAME cards never repaint native paper cleanup rectangles")
T.eq(modernPolygons, 6,
  "Modern UI GAME draws one typed move card and one compact PP card")
love.graphics.rectangle = modernRealRectangle
love.graphics.polygon = modernRealPolygon
modernCombined.release()

T.finish("typed_move_colors")
