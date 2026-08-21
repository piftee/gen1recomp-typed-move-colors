-- Typed Move Colors is deliberately presentation-only. Move definitions,
-- PP, effects, targeting and battle behavior stay owned by the engine; every
-- tint is resolved from the live merged move table so content mods compose.
return function(mod)
  local optionSchema = {
    { key = "battle_colors", label = "BATTLE COLORS", type = "toggle",
      default = true },
    { key = "layout", label = "MOVE LAYOUT", type = "choice",
      default = "wide", choices = {
        { "WIDE", "wide" }, { "GAME", "game" },
      } },
    { key = "effect_hints", label = "MOVE EFFECT", type = "toggle",
      default = true },
    { key = "menu_colors", label = "MENU COLORS", type = "toggle",
      default = true },
    { key = "strength", label = "COLOR STRENGTH", type = "choice",
      default = "bold", choices = {
        { "SOFT", "soft" }, { "BOLD", "bold" },
      } },
    { key = "opacity", label = "BATTLE OPACITY", type = "choice",
      default = "100", choices = {
        { "100%", "100" }, { "85%", "85" },
        { "70%", "70" }, { "55%", "55" },
      } },
    { key = "text_only", label = "TEXT ONLY", type = "toggle",
      default = false },
  }
  mod.options:define(optionSchema)

  local mainLabels = {
    battle_colors = "MOVE BATTLE",
    layout = "MOVE LAYOUT",
    effect_hints = "MOVE EFFECT",
    menu_colors = "MOVE MENUS",
    strength = "MOVE TINT",
    opacity = "CARD OPACITY",
    text_only = "TEXT ONLY",
  }

  local function setOption(game, key, value)
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[mod.id] = options.modOptions[mod.id] or {}
      options.modOptions[mod.id][key] = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[mod.id] = loader.modOptions[mod.id] or {}
      loader.modOptions[mod.id][key] = value
      if loader.events then
        loader.events:emit("mod.options_changed",
          { mod = mod.id, key = key, value = value })
      end
    end
  end

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    for _, sourceRow in ipairs(optionSchema) do
      local row = sourceRow
      local rendered = {
        id = "typed_move_colors_" .. row.key,
        label = mainLabels[row.key] or row.label,
      }
      if row.type == "toggle" then
        rendered.value = function()
          return mod.options:get(row.key) and "ON" or "OFF"
        end
        rendered.step = function(g)
          setOption(g, row.key, not mod.options:get(row.key))
          return true
        end
      else
        rendered.value = function()
          local current = mod.options:get(row.key)
          for _, choice in ipairs(row.choices or {}) do
            if choice[2] == current then return choice[1] end
          end
          return "----"
        end
        rendered.step = function(g, direction)
          local choices = row.choices or {}
          local current, index = mod.options:get(row.key), 1
          for i, choice in ipairs(choices) do
            if choice[2] == current then index = i break end
          end
          index = (index - 1 + (direction or 1)) % #choices + 1
          setOption(g, row.key, choices[index][2])
          return true
        end
      end
      out[#out + 1] = rendered
    end
    return out
  end)

  local source, readErr = mod:read("ui.lua")
  if not source then
    mod.log:error("ui.lua is missing (%s); reinstall the mod",
      tostring(readErr or "unknown read error"))
    return
  end
  local chunk, compileErr = load(source, "@" .. mod.path .. "/ui.lua")
  if not chunk then
    mod.log:error("ui.lua did not compile: %s", tostring(compileErr))
    return
  end
  local ok, install = pcall(chunk)
  if not ok or type(install) ~= "function" then
    mod.log:error("ui.lua must return an installer: %s", tostring(install))
    return
  end
  local installed, installErr = pcall(install, mod)
  if not installed then
    mod.log:error("typed move UI failed: %s", tostring(installErr))
    return
  end
  mod.log:info("type-coloured battle and menu moves enabled")
end
