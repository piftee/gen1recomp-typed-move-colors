-- Minimal public OverworldBattle seam exported by Dramatic Shape 1.8.x.
return function(mod)
  local OverworldBattle = {}

  function OverworldBattle.textRects(battle)
    if not battle then return {} end
    local rects = { box = { 0, 96, 160, 48 } }
    if battle.phase == "moveSelect" then
      rects.moves = { 0, 64, 88, 32 }
    elseif battle.phase == "mimicSelect" then
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
