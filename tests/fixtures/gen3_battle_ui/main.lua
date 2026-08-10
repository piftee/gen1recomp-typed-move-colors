-- Minimal v1.3 move-panel seam. The real overhaul draws the same four
-- rounded rows in a priority-10000 finished-frame HUD link.
return function(mod)
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local result = next(game, viewport)
    local battle = game and game.stack and game.stack:top() or nil
    if battle and battle.phase == "moveSelect" then
      game.gen3FixtureDrawn = true
      love.graphics.setColor(0.97, 0.97, 0.95, 1)
      love.graphics.rectangle("fill", 1, 1, 8, 8, 2, 2)
    end
    return result
  end, 10000)
end
