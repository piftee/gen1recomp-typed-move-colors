-- Minimal public seam from Potato Voxel. The real mod calls textRects from
-- both its HUD-panel compositor and its transition snapshot path.
return function(mod)
  local OverworldBattle = {}

  function OverworldBattle.textRects(battle)
    local rects = { box = { 0, 96, 160, 48 } }
    if battle and battle.phase == "moveSelect" then
      rects.moves = { 0, 64, 88, 32 }
    elseif battle and battle.phase == "mimicSelect" then
      rects.mimic = { 0, 56, 128, 40 }
    end
    return rects
  end

  local lib = {}
  function lib.require(name)
    if name == "OverworldBattle" then return OverworldBattle end
  end

  mod.exports.lib = lib
  mod.exports.overworldBattle = OverworldBattle
end
