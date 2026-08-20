-- The real Modern UI owns its final battle presentation through render.hud
-- when that WIP presenter is enabled. Its installed presence is the stable
-- compatibility seam needed here because its other presets can still edit the
-- composed battle while leaving the classic move-selection behavior active.
return function(mod)
  mod.exports.compatibilityApi = 1
end
