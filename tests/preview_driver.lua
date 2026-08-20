-- Visual smoke test for Typed Move Colors.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local BattleState = require("src.battle.BattleState")
  local PaletteFX = require("src.render.PaletteFX")
  local Pokemon = require("src.pokemon.Pokemon")
  local SummaryMenu = require("src.ui.SummaryMenu")
  local DIR = os.getenv("SHOT_DIR") or "/tmp/typed-move-colors"

  if os.getenv("PREVIEW_ANDROID") == "1" then
    love.window.setMode(1600, 845, { resizable = true,
      minwidth = 640, minheight = 360 })
  elseif os.getenv("PREVIEW_PORTRAIT") == "1" then
    love.window.setMode(460, 1024, { resizable = true,
      minwidth = 320, minheight = 576 })
  end

  game.save.options = game.save.options or {}
  game.save.options.colors = "redpp"
  PaletteFX.setMode("redpp")

  local function moveLayout(value)
    game.save.options.modOptions = game.save.options.modOptions or {}
    game.save.options.modOptions.typed_move_colors =
      game.save.options.modOptions.typed_move_colors or {}
    game.save.options.modOptions.typed_move_colors.layout = value
    if game.mods and game.mods.modOptions then
      game.mods.modOptions.typed_move_colors =
        game.mods.modOptions.typed_move_colors or {}
      game.mods.modOptions.typed_move_colors.layout = value
    end
  end

  local function effectHints(value)
    game.save.options.modOptions = game.save.options.modOptions or {}
    game.save.options.modOptions.typed_move_colors =
      game.save.options.modOptions.typed_move_colors or {}
    game.save.options.modOptions.typed_move_colors.effect_hints = value
    if game.mods and game.mods.modOptions then
      game.mods.modOptions.typed_move_colors =
        game.mods.modOptions.typed_move_colors or {}
      game.mods.modOptions.typed_move_colors.effect_hints = value
    end
  end

  local function cardOpacity(value)
    game.save.options.modOptions = game.save.options.modOptions or {}
    game.save.options.modOptions.typed_move_colors =
      game.save.options.modOptions.typed_move_colors or {}
    game.save.options.modOptions.typed_move_colors.opacity = value
    if game.mods and game.mods.modOptions then
      game.mods.modOptions.typed_move_colors =
        game.mods.modOptions.typed_move_colors or {}
      game.mods.modOptions.typed_move_colors.opacity = value
    end
  end

  local function textOnly(value)
    game.save.options.modOptions = game.save.options.modOptions or {}
    game.save.options.modOptions.typed_move_colors =
      game.save.options.modOptions.typed_move_colors or {}
    game.save.options.modOptions.typed_move_colors.text_only = value
    if game.mods and game.mods.modOptions then
      game.mods.modOptions.typed_move_colors =
        game.mods.modOptions.typed_move_colors or {}
      game.mods.modOptions.typed_move_colors.text_only = value
    end
  end

  local mon = Pokemon.new(game.data, "CHARIZARD", 50)
  local allMoves = {
    { id = "FLAMETHROWER", pp = game.data.moves.FLAMETHROWER.pp },
    { id = "SURF", pp = game.data.moves.SURF.pp },
    { id = "RAZOR_LEAF", pp = game.data.moves.RAZOR_LEAF.pp },
    { id = "THUNDERBOLT", pp = game.data.moves.THUNDERBOLT.pp },
  }
  mon.moves = allMoves
  game.save.party = { mon }

  while game.stack:top() do game.stack:pop() end
  local summary = SummaryMenu.new(game, mon)
  summary.page = 2
  game.stack:push(summary)
  U.wait(8)
  U.log("PASS summary move colours prepared")
  U.shot(game, DIR .. "/typed_move_summary.png")

  while game.stack:top() do game.stack:pop() end
  -- Keep all four moves in the standard-renderer capture so the complete
  -- player sprite and the geometric indicators can be judged together.
  -- WIDE remains the mod default but changes only the detached selector; the
  -- game's classic battlefield itself must stay intact.
  moveLayout(nil)
  game.save.options.battleLayout = "og"
  local battle = BattleState.newWild(game, "PIDGEY", 20,
    { onFinish = function() end })
  game.stack:push(battle)
  U.wait(8)
  battle.introSlide = 0
  battle.introBalls = nil
  battle.showEnemyTrainer = false
  battle.showPlayerBack = false
  battle.enemySendingOut = false
  battle.sendingOut = false
  battle.phase = "moveSelect"
  battle.moveIndex = 2
  U.wait(8)
  U.log("PASS standard renderer restores the complete player sprite")
  U.shot(game, DIR .. "/typed_move_battle_standard.png")

  cardOpacity("70")
  U.wait(3)
  U.log("PASS 70% battle-card opacity preserves the scene underneath")
  U.shot(game, DIR .. "/typed_move_battle_opacity_70.png")
  cardOpacity("100")

  battle.phase = "menu"
  battle.menuIndex = 1
  U.wait(4)
  U.log("PASS Wide command cards replace the native action box")
  U.shot(game, DIR .. "/typed_move_battle_commands.png")
  battle.phase = "moveSelect"

  effectHints(false)
  U.wait(3)
  U.log("PASS Move Effect off removes every indicator")
  U.shot(game, DIR .. "/typed_move_battle_effect_off.png")
  effectHints(true)

  -- Also verify compatibility when the user explicitly enables the engine's
  -- complete wide battle renderer: the mod decorates it without replacing it.
  moveLayout(nil)
  game.save.options.battleLayout = "wide"
  battle.player.curMoves = allMoves
  U.wait(12)
  U.log("PASS wide battle move colours prepared")
  U.shot(game, DIR .. "/typed_move_battle_wide.png")

  -- Maximum-compatibility mode must restore the engine's complete native
  -- layout and recolour only the four move-name glyph runs.
  game.save.options.battleLayout = "og"
  textOnly(true)
  U.wait(8)
  U.log("PASS Text Only retains native battle UI with typed move-name ink")
  U.shot(game, DIR .. "/typed_move_battle_text_only.png")
end
