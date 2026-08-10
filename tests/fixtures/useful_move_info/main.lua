-- Minimal v1.4.0-compatible screen seam. The real mod creates the vanilla
-- controller, then owns draw on the returned instance to add NEW MOVE.
return function(mod)
  mod.content.screens:register("MoveLearnMenu", {
    new = function(game, mon, newMoveId, onDone)
      local MoveLearnMenu = require("src.ui.MoveLearnMenu")
      local screen = MoveLearnMenu.new(game, mon, newMoveId, onDone)
      screen.draw = function(self)
        self.usefulMoveInfoDrawn = true
      end
      return screen
    end,
  })
  mod.exports.infoText = function() return "fixture" end
end
