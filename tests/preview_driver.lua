-- Visual smoke test for Typed Move Colors.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local BattleState = require("src.battle.BattleState")
  local PaletteFX = require("src.render.PaletteFX")
  local Pipelines = require("src.render.Pipelines")
  local Pokemon = require("src.pokemon.Pokemon")
  local SummaryMenu = require("src.ui.SummaryMenu")
  local DIR = os.getenv("SHOT_DIR") or "/tmp/typed-move-colors"

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
  -- Match an early-game two-move party member for the custom-renderer
  -- capture: its two buttons should expand to fill the lower control area.
  mon.moves = { allMoves[1], allMoves[2] }
  -- A staged battle renderer owns its transparent classic surface. Simulate
  -- that ownership while WIDE remains the mod default; this capture must
  -- stay classic rather than widening the whole battlefield underneath it.
  moveLayout(nil)
  game.save.options.battleLayout = "og"
  local realWorldPipeline = Pipelines.worldPipeline
  Pipelines.worldPipeline = function()
    return "preview_world_renderer", { drawWorld = function() end }
  end
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
  U.log("PASS custom renderer keeps its classic battle surface")
  U.shot(game, DIR .. "/typed_move_battle_classic.png")

  Pipelines.worldPipeline = realWorldPipeline
  -- Also verify compatibility when the user explicitly enables the engine's
  -- complete wide battle renderer: the mod decorates it without replacing it.
  moveLayout(nil)
  game.save.options.battleLayout = "wide"
  battle.player.curMoves = allMoves
  U.wait(12)
  U.log("PASS wide battle move colours prepared")
  U.shot(game, DIR .. "/typed_move_battle_wide.png")
end
