return function(mod)
  local Font = require("src.render.Font")
  local BattleState = require("src.battle.BattleState")
  local ListMenu = require("src.ui.ListMenu")
  local MoveLearnMenu = require("src.ui.MoveLearnMenu")
  local PaletteFX = require("src.render.PaletteFX")
  local SummaryMenu = require("src.ui.SummaryMenu")
  local TypeChart = require("src.battle.TypeChart")
  local WideBattle = require("src.battle.WideBattle")

  -- Exact flat fills sampled from the supplied type-colour reference. The
  -- Gen 1 set uses fifteen entries; DARK, FAIRY and STEEL are included so
  -- content mods that add later types receive the same coherent system.
  local TYPE_BASE_COLORS = {
    NORMAL = { 144, 152, 162 },
    FIGHTING = { 206, 63, 107 },
    FLYING = { 143, 168, 222 },
    POISON = { 171, 106, 200 },
    GROUND = { 217, 119, 70 },
    ROCK = { 201, 182, 139 },
    BUG = { 144, 192, 44 },
    GHOST = { 82, 105, 173 },
    FIRE = { 254, 156, 85 },
    WATER = { 77, 144, 214 },
    GRASS = { 101, 188, 94 },
    ELECTRIC = { 244, 210, 59 },
    PSYCHIC_TYPE = { 249, 113, 119 },
    ICE = { 115, 206, 191 },
    DRAGON = { 9, 109, 195 },
    DARK = { 91, 82, 101 },
    FAIRY = { 236, 144, 231 },
    STEEL = { 91, 142, 161 },
  }

  local function typeRamp(base)
    local light = {}
    for i = 1, 3 do
      light[i] = math.floor(base[i] + (255 - base[i]) * 0.30 + 0.5)
    end
    return {
      { 255, 255, 255 }, light,
      { base[1], base[2], base[3] }, { 0, 0, 0 },
    }
  end

  local TYPE_COLORS = {}
  for id, base in pairs(TYPE_BASE_COLORS) do
    TYPE_COLORS[id] = typeRamp(base)
  end

  -- OG RED/BLUE and OG YELLOW are hardware palettes rather than the modern
  -- type set. Keep their established named-palette mapping when that display
  -- mode is selected; monochrome, inverted and Classic transformations are
  -- handled by PaletteFX.effectiveColors below.
  local OG_TYPE_PALETTES = {
    NORMAL = "GRAYMON",
    FIGHTING = "REDMON",
    FLYING = "CYANMON",
    POISON = "PURPLEMON",
    GROUND = "BROWNMON",
    ROCK = "BROWNMON",
    BUG = "GREENMON",
    GHOST = "PURPLEMON",
    FIRE = "REDMON",
    WATER = "BLUEMON",
    GRASS = "GREENMON",
    ELECTRIC = "YELLOWMON",
    PSYCHIC_TYPE = "PINKMON",
    ICE = "CYANMON",
    DRAGON = "PURPLEMON",
  }

  local TYPE_SHORT = {
    NORMAL = "NRM", FIGHTING = "FGT", FLYING = "FLY",
    POISON = "PSN", GROUND = "GRD", ROCK = "RCK", BUG = "BUG",
    GHOST = "GHO", FIRE = "FIR", WATER = "WTR", GRASS = "GRS",
    ELECTRIC = "ELC", PSYCHIC_TYPE = "PSY", ICE = "ICE",
    DRAGON = "DRG",
  }

  local function setting(key, fallback)
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function engineWide(battle)
    if not (battle and battle.wideLayout) then return false end
    local ok, wide = pcall(battle.wideLayout, battle)
    return ok and wide and true or false
  end

  -- WIDE now owns only the move selector. If the engine itself is already
  -- wide, the in-canvas overlay below decorates that grid. Otherwise a
  -- window-space panel supplies the same 2x2 grid without changing the
  -- battlefield canvas, HUDs, sprites or background. This is the seam staged
  -- voxel battles need: they keep their transparent 160px scene intact.
  local function detachedGrid(battle)
    return setting("layout", "wide") == "wide"
      and not engineWide(battle)
  end

  -- The classic controller treats moves as a vertical list. When the
  -- detached panel is showing, correct only its directional result after the
  -- native update runs; A/B/SELECT, PP validation and move execution remain
  -- entirely native. The wrapper is process-stable across mod reloads.
  local inputPatch = rawget(BattleState, "_typedMoveColorsInputPatch")
  if not inputPatch then
    inputPatch = { original = BattleState.update }
    rawset(BattleState, "_typedMoveColorsInputPatch", inputPatch)
    BattleState.update = function(self, ...)
      local phase = self.phase
      local indexKey = phase == "moveSelect" and "moveIndex"
        or phase == "mimicSelect" and "mimicIndex" or nil
      local moves = phase == "moveSelect"
        and self.player and self.player.curMoves or self.mimicMoves
      local before = indexKey and self[indexKey] or nil
      local direction
      if before and type(moves) == "table" and inputPatch.detached
          and inputPatch.detached(self) then
        local input = self.game and self.game.input
        for _, key in ipairs({ "left", "right", "up", "down" }) do
          if input and input.wasPressed and input:wasPressed(key) then
            direction = key
            break
          end
        end
      end
      local result = inputPatch.original(self, ...)
      if direction and self.phase == phase and indexKey then
        self[indexKey] = inputPatch.navigate(before, #moves, direction)
      end
      return result
    end
  end
  inputPatch.detached = detachedGrid
  inputPatch.navigate = WideBattle.moveGridIndex

  local function isTop(screen)
    local stack = screen and screen.game and screen.game.stack
    return not (stack and stack.top) or stack:top() == screen
  end

  local function moveDef(game, move)
    local id = type(move) == "table" and move.id or move
    local moves = game and game.data and game.data.moves
    return moves and moves[id] or nil
  end

  local function colorsFor(game, moveType)
    local data = game and game.data
    local colors
    if PaletteFX.mode == "ogred" then
      local named = OG_TYPE_PALETTES[moveType] or "GRAYMON"
      colors = PaletteFX.pal(data, named)
        or PaletteFX.pal(data, "GRAYMON") or PaletteFX.GRAYS
    else
      colors = TYPE_COLORS[moveType] or TYPE_COLORS.NORMAL
    end
    return PaletteFX.effectiveColors(colors) or colors
  end
  inputPatch.colorsFor = colorsFor

  local rgb

  -- Effect indicators use the same merged chart as damage calculation and
  -- the opponent's live battle types, so Conversion and type/content mods are
  -- reflected immediately. Fixed-damage and Super Fang effects deliberately
  -- skip the chart in Gen 1; because they still change HP, they receive the
  -- ordinary single-up indicator. OHKO moves consult only immunity.
  local DIRECT_HP_DAMAGE = {
    SPECIAL_DAMAGE_EFFECT = true,
    SUPER_FANG_EFFECT = true,
  }

  local function effectIndicator(battle, def)
    if not setting("effect_hints", true) or not battle or not def then
      return nil
    end
    local target = battle.enemy
    if type(target and target.curTypes) ~= "table" then return nil end
    if DIRECT_HP_DAMAGE[def.effect] then return "up" end
    if type(def.power) ~= "number" or def.power <= 0 then return "circle" end
    local ok, mult = pcall(TypeChart.effectiveness,
      def.type, target.curTypes)
    if not ok or type(mult) ~= "number" then return "circle" end
    if mult == 0 then return "circle" end
    if def.effect == "OHKO_EFFECT" then return "up" end
    if mult > 10 then return "double_up" end
    if mult < 10 then return "down" end
    return "up"
  end
  inputPatch.effectIndicator = effectIndicator

  local function drawEffectArrow(cx, cy, direction, color)
    love.graphics.setColor(rgb(color))
    if direction == "up" then
      love.graphics.polygon("fill", {
        cx, cy - 4, cx - 4, cy + 3, cx + 4, cy + 3,
      })
    else
      love.graphics.polygon("fill", {
        cx, cy + 4, cx - 4, cy - 3, cx + 4, cy - 3,
      })
    end
  end

  local function drawEffectIndicator(kind, x, y, w, h, color)
    if not kind then return end
    local cx = x + w - 10
    local cy = y + h - 9
    if kind == "circle" then
      love.graphics.push("all")
      love.graphics.setColor(rgb(color))
      if love.graphics.setLineWidth then love.graphics.setLineWidth(1) end
      love.graphics.circle("line", cx, cy, 3)
      love.graphics.pop()
    elseif kind == "double_up" then
      drawEffectArrow(cx - 4, cy, "up", color)
      drawEffectArrow(cx + 4, cy, "up", color)
    else
      drawEffectArrow(cx, cy, kind, color)
    end
  end

  local inkShader
  local function shaderForInk()
    if inkShader == nil then
      if not love.graphics.newShader then
        inkShader = false
      else
        local ok, shader = pcall(love.graphics.newShader, [[
          vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            vec4 pixel = Texel(tex, tc);
            return vec4(color.rgb, pixel.a * color.a);
          }
        ]])
        inkShader = ok and shader or false
      end
    end
    return inkShader or nil
  end

  local function fitText(text, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(0, math.floor(maxWidth or Font.width(text)))
    if Font.width(text) <= maxWidth then return text end
    local spans = Font.split and Font.split(text) or nil
    if spans and Font.spansFitting then
      local count = Font.spansFitting(spans, maxWidth)
      return count > 0 and text:sub(1, spans[count].to) or ""
    end
    while #text > 0 and Font.width(text) > maxWidth do
      text = text:sub(1, -2)
    end
    return text
  end

  rgb = function(color)
    return color[1] / 255, color[2] / 255, color[3] / 255
  end

  local function drawInk(text, x, y, maxWidth, color)
    text = fitText(text, maxWidth)
    love.graphics.push("all")
    local shader = shaderForInk()
    if shader then
      love.graphics.setShader(shader)
      love.graphics.setColor(rgb(color))
    else
      love.graphics.setColor(0, 0, 0, 1)
    end
    Font.draw(text, math.floor(x), math.floor(y))
    love.graphics.pop()
  end

  local function chamfer(mode, x, y, w, h, cut)
    cut = math.max(1, math.min(cut or 2,
      math.floor(w / 2), math.floor(h / 2)))
    if love.graphics.polygon then
      love.graphics.polygon(mode, {
        x + cut, y, x + w - cut, y,
        x + w, y + cut, x + w, y + h - cut,
        x + w - cut, y + h, x + cut, y + h,
        x, y + h - cut, x, y + cut,
      })
    else
      love.graphics.rectangle(mode, x, y, w, h)
    end
  end

  local function clearRegion(game, x, y, w, h)
    local r, g, b = PaletteFX.paperShade(game and game.data)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", x, y, w, h)
  end

  -- Remove an already-drawn native menu from the transparent UI canvas.
  -- Replace blending writes alpha zero instead of painting paper, so a voxel
  -- or other custom battlefield remains visible underneath the detached
  -- panel. The real LÖVE runtime supports this blend mode; the guarded
  -- fallback keeps headless tooling harmless.
  local function eraseRegion(x, y, w, h)
    local g = love.graphics
    g.push("all")
    if g.setBlendMode then
      pcall(g.setBlendMode, "replace", "premultiplied")
    end
    g.setColor(0, 0, 0, 0)
    g.rectangle("fill", x, y, w, h)
    g.pop()
  end

  -- Classic move selection clips the player pic at y=64 because the Game
  -- Boy TYPE/PP box replaced those tile rows. The detached selector removes
  -- that box, so a flat battle needs its complete player pic drawn once more
  -- after cleanup. Staged renderers deliberately own the Pokemon themselves:
  -- Voxel Battle Art exposes its live shot on the battle and makes the battle
  -- surface transparent, either of which keeps this compatibility redraw out
  -- of its composition.
  local function restoreDetachedPlayerPic(battle)
    if not (battle and battle.drawPicsLayer) then return end
    if rawget(battle, "dramaticShapeShot") ~= nil
        or battle.letterboxWhite == false then
      return
    end
    local fx = battle.fx
    local sx = fx and fx.shakeX or 0
    local sy = fx and fx.shakeY or 0
    if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
      sx = (battle.frame or 0) % 4 < 2 and 2 or -2
    end
    -- Gen1Recomp advances the intro at four pixels per draw. Move selection
    -- normally has no remaining slide, but mirroring it keeps this redraw
    -- correct for custom transitions into the menu.
    local slide = (battle.introSlide or 0) * 4
    battle:drawPicsLayer(slide, sx, sy, "player", true)
  end

  -- Mirrors Modern Party UI's card hierarchy at the scale available here:
  -- offset black shadow, pale outer rim, type-coloured face and a bright
  -- selection rail. Dense buttons retain the same hierarchy with one-pixel
  -- insets so the native 8px font still fits.
  local function drawButton(game, moveType, x, y, w, h, selected, dense,
      content, detached)
    local colors = colorsFor(game, moveType)
    local bold = setting("strength", "bold") == "bold"
    -- Selected cards use the palette's ink shade rather than another type
    -- shade. The black frame remains legible for pale types such as WATER,
    -- ICE and NORMAL, where the old light rim blended into the selected face.
    local rim = colors[selected and 4 or 2]
    local face = colors[selected and 2 or (bold and 3 or 2)]
    local foreground = colors[selected and 4 or (bold and 1 or 4)]
    local inset = dense and 1 or 2
    local shadow = dense and 1 or 2
    local cut = dense and 1 or math.min(3, math.floor(h / 3))

    -- The wide battle grid has enough breathing room to let the focused
    -- button rise one pixel on every side. Dense 8-15px menu rows retain
    -- their footprint so adjacent cards never cover one another.
    if selected and not dense then
      x, y, w, h = x - 1, y - 1, w + 2, h + 2
      cut = math.min(3, math.floor(h / 3))
    end

    -- The engine's original move text and cursor are still underneath this
    -- additive overlay. Clear the exact footprint first so neither can peek
    -- through a button's deliberately transparent chamfer corners.
    if not detached then clearRegion(game, x, y, w, h) end
    love.graphics.setColor(rgb(colors[4]))
    chamfer("fill", x + shadow, y + shadow,
      w - shadow, h - shadow, cut)
    love.graphics.setColor(rgb(rim))
    chamfer("fill", x, y, w - shadow, h - shadow, cut)
    love.graphics.setColor(rgb(face))
    chamfer("fill", x + inset, y + inset,
      w - shadow - inset * 2, h - shadow - inset * 2,
      math.max(1, cut - 1))

    if selected then
      love.graphics.setColor(rgb(colors[3]))
      love.graphics.rectangle("fill", x + inset, y + inset + 1,
        dense and 1 or 2,
        math.max(1, h - shadow - inset * 2 - 2))
    end

    content(foreground)
    if not detached then PaletteFX.markTrueColor(x, y, w, h) end
  end

  local typeShort

  local function renderBattle(battle)
    if not setting("battle_colors", true) then return end
    local phase = battle and battle.phase
    if phase ~= "moveSelect" and phase ~= "mimicSelect" then return end
    local moves = phase == "moveSelect"
      and battle.player and battle.player.curMoves or battle.mimicMoves
    local selected = phase == "moveSelect" and battle.moveIndex
      or battle.mimicIndex
    if type(moves) ~= "table" then return end

    if detachedGrid(battle) then
      -- TYPE/PP occupies (0,64)-(88,104), while the move list occupies the
      -- bottom 160x48 box. Remove only those native menu pixels: the player's
      -- status block to their right and every battlefield pixel stay owned by
      -- the engine/custom renderer.
      if phase == "moveSelect" then
        eraseRegion(0, 64, 88, 40)
        eraseRegion(0, 96, 160, 48)
        restoreDetachedPlayerPic(battle)
      else
        eraseRegion(0, 56, 128, 48)
      end
      return
    end

    local wide = engineWide(battle)
    if not wide and phase == "moveSelect" then
      -- Replace the cramped lower half of the native list with four full-
      -- width buttons. The TYPE/PP panel immediately above remains native.
      clearRegion(battle.game, 0, 104, 160, 40)
    elseif not wide then
      -- Mimic's original narrow box has the same four-row constraint but no
      -- details panel, so its modal buttons can use the complete width.
      clearRegion(battle.game, 0, 64, 160, 40)
    end

    for i, move in ipairs(moves) do
      local def = moveDef(battle.game, move)
      if def then
        local x, y, w, h, textX, textY, dense, typeX
        if wide then
          local col = (i - 1) % 2
          local row = math.floor((i - 1) / 2)
          x, y, w, h = col == 0 and 4 or 110,
            106 + row * 18, col == 0 and 104 or 110, 16
          textX, textY, dense = x + 4, y + 4, false
        else
          x, y, w, h = 4,
            (phase == "moveSelect" and 104 or 64) + (i - 1) * 10,
            152, 9
          textX, textY, dense, typeX = 12, y + 1, true, 128
        end
        drawButton(battle.game, def.type, x, y, w, h,
          i == selected, dense,
          function(foreground)
            drawInk(def.name or move.id, textX, textY,
              typeX and typeX - textX - 4
                or w - (textX - x) - 5, foreground)
            if typeX then
              drawInk(typeShort(def.type), typeX, textY, 24, foreground)
            end
          end)
      end
    end
  end

  -- A low-priority post-link draws before higher-priority post-overlays, so
  -- another mod's HUD or modal remains on top of these move chips.
  mod.hooks:wrap("battle.overlay", function(next, battle)
    next(battle)
    renderBattle(battle)
  end, -100)

  typeShort = function(moveType)
    if TYPE_SHORT[moveType] then return TYPE_SHORT[moveType] end
    local shown = TypeChart.displayName(moveType) or moveType or "???"
    return fitText(tostring(shown):upper(), 24)
  end

  local function activeBattle(game)
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) == "table" then
      for i = #states, 1, -1 do
        local state = states[i]
        if state and state.game == game
            and (state.phase == "moveSelect"
              or state.phase == "mimicSelect") then
          return state
        end
      end
    end
    local top = stack and stack.top and stack:top() or nil
    if top and (top.phase == "moveSelect" or top.phase == "mimicSelect") then
      return top
    end
  end

  -- Responsive move-only panel drawn after the completed world/UI composite.
  -- It never changes Renderer.uiSize or BattleState's drawing path, so staged
  -- 3D battles keep every pixel of their background. The coordinates below
  -- are a 304x80 native-pixel control area scaled by an integer to nearly the
  -- full window width. It stays in the bottom band beneath the battling
  -- Pokémon, including in staged voxel renderers. Only the five chamfered
  -- cards cover the world.
  local function renderDetachedBattle(game, viewport)
    if not setting("battle_colors", true) then return end
    local battle = activeBattle(game)
    if not battle or not detachedGrid(battle) then return end
    local phase = battle.phase
    local moves = phase == "moveSelect"
      and battle.player and battle.player.curMoves or battle.mimicMoves
    local selected = phase == "moveSelect" and battle.moveIndex
      or battle.mimicIndex
    if type(moves) ~= "table" or #moves == 0 then return end

    local screenW = viewport and viewport.width
      or love.graphics.getWidth and love.graphics.getWidth() or 304
    local screenH = viewport and viewport.height
      or love.graphics.getHeight and love.graphics.getHeight() or 144
    local panelW, panelH = 304, 80
    local scale = math.floor((screenW - 16) / panelW)
    scale = math.max(1, math.min(6, scale))
    local margin = math.max(8, scale * 2)
    local originX = math.floor((screenW - panelW * scale) / 2)
    local originY = math.floor(screenH - panelH * scale - margin)

    love.graphics.push("all")
    love.graphics.translate(originX, originY)
    love.graphics.scale(scale, scale)

    local twoRows = #moves > 2
    local buttonH = twoRows and 36 or 74
    local rowStep = twoRows and 38 or 0
    for i, move in ipairs(moves) do
      if i > 4 then break end
      local def = moveDef(game, move)
      if def then
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x, y = col == 0 and 2 or 110, 2 + row * rowStep
        local w, h = col == 0 and 105 or 108, buttonH
        local indicator = phase == "moveSelect"
          and effectIndicator(battle, def)
        drawButton(game, def.type, x, y, w, h, i == selected, false,
          function(foreground)
            local textX = x + 4
            local textY = y + math.floor((h - 8) / 2)
            drawInk(def.name or move.id, textX, textY,
              w - 9, foreground)
            drawEffectIndicator(indicator, x, y, w, h, foreground)
          end, true)
      end
    end

    local selectedMove = moves[selected]
    local def = selectedMove and moveDef(game, selectedMove)
    if def then
      -- The details card shares the focused type and black selected rim, so
      -- PP is visually attached to the selected move without touching the
      -- staged renderer's own HUDs.
      drawButton(game, def.type, 222, 2, 80, 74, true, false,
        function(foreground)
          if phase == "moveSelect" then
            local maxPP = (def.pp or 0)
              + (selectedMove.ppUps or 0) * math.floor((def.pp or 0) / 5)
            drawInk("PP", 228, 21, 16, foreground)
            drawInk(("%2d/%2d"):format(selectedMove.pp or 0, maxPP),
              251, 21, 44, foreground)
          else
            drawInk("COPY", 228, 21, 48, foreground)
          end
          local shown = TypeChart.displayName(def.type) or def.type or "???"
          drawInk(tostring(shown):upper(), 228, 51, 66, foreground)
        end, true)
    end

    love.graphics.pop()
  end

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local result = next(game, viewport)
    local ok, err = pcall(renderDetachedBattle, game, viewport)
    if not ok and not mod._typedMoveHudWarned then
      mod._typedMoveHudWarned = true
      mod.log:warn("responsive move panel skipped: %s", tostring(err))
    end
    return result
  end, -100)

  local function renderSummary(screen)
    if not setting("menu_colors", true) or screen.page ~= 2
        or not isTop(screen) then return end
    local game, mon = screen.game, screen.mon
    for i = 1, 4 do
      local move = mon and mon.moves and mon.moves[i]
      local def = move and moveDef(game, move)
      if def then
        local y = 72 + (i - 1) * 16
        drawButton(game, def.type, 8, y, 144, 15, false, true,
          function(foreground)
            drawInk(def.name or move.id, 16, y, 104, foreground)
            drawInk(typeShort(def.type), 126, y, 24, foreground)
            drawInk("PP", 88, y + 7, 16, foreground)
            local maxPP = (def.pp or 0)
              + (move.ppUps or 0) * math.floor((def.pp or 0) / 5)
            drawInk(("%2d/%2d"):format(move.pp or 0, maxPP),
              110, y + 7, 40, foreground)
          end)
      end
    end
  end

  local function renderMoveLearn(screen)
    if not setting("menu_colors", true) or not screen.selecting
        or not isTop(screen) then return end
    for i, move in ipairs(screen.mon and screen.mon.moves or {}) do
      local def = moveDef(screen.game, move)
      if def then
        local y = (5 + i) * 8
        drawButton(screen.game, def.type, 46, y, 106, 8,
          i == screen.index, true, function(foreground)
            drawInk(def.name or move.id, 48, y, 102, foreground)
          end)
      end
    end
  end

  local function safeDrawPatch(class, key, renderer)
    local state = rawget(class, key)
    if not state then
      state = { original = class.draw, renderer = renderer }
      rawset(class, key, state)
      class.draw = function(self, ...)
        state.original(self, ...)
        if state.renderer then
          local ok, err = pcall(state.renderer, self)
          if not ok and not state.warned then
            state.warned = true
            mod.log:warn("move-colour overlay skipped: %s", tostring(err))
          end
        end
      end
    else
      state.renderer = renderer
      state.warned = nil
    end
  end

  safeDrawPatch(SummaryMenu, "_typedMoveColorsPatch", renderSummary)
  safeDrawPatch(MoveLearnMenu, "_typedMoveColorsPatch", renderMoveLearn)

  local listState = rawget(ListMenu, "_typedMoveColorsPatch")
  if not listState then
    listState = { originalNew = ListMenu.new, originalDraw = ListMenu.draw }
    rawset(ListMenu, "_typedMoveColorsPatch", listState)
    ListMenu.new = function(...)
      local screen = listState.originalNew(...)
      if listState.decorate then
        local ok, err = pcall(listState.decorate, screen, ...)
        if not ok and not listState.warned then
          listState.warned = true
          mod.log:warn("move-list detection skipped: %s", tostring(err))
        end
      end
      return screen
    end
    ListMenu.draw = function(self, ...)
      listState.originalDraw(self, ...)
      if listState.renderer then
        local ok, err = pcall(listState.renderer, self)
        if not ok and not listState.warned then
          listState.warned = true
          mod.log:warn("move-list colours skipped: %s", tostring(err))
        end
      end
    end
  end

  listState.decorate = function(screen, game, title, items)
    if title ~= "Which move?" or type(items) ~= "table" then return end
    local byName = {}
    for id, def in pairs(game.data and game.data.moves or {}) do
      if def.name then byName[def.name] = { id = id, type = def.type } end
    end
    local types, found = {}, 0
    for i, item in ipairs(items) do
      local hit = byName[item.label]
      if hit then types[i], found = hit.type, found + 1 end
    end
    if found > 0 then screen._typedMoveColors = types end
  end

  listState.renderer = function(screen)
    if not setting("menu_colors", true) or not screen._typedMoveColors
        or not isTop(screen) then return end
    for row = 1, screen.rows do
      local i = screen.scroll + row
      local item, moveType = screen.items[i], screen._typedMoveColors[i]
      if not item then break end
      if moveType then
        local y = 8 + row * 16
        drawButton(screen.game, moveType, 12, y - 2, 142, 14,
          i == screen.index, false, function(foreground)
            drawInk(item.label, 18, y + 1,
              item.right and 102 or 130, foreground)
            if item.right then
              local width = Font.width(item.right)
              drawInk(item.right, 148 - width, y + 1, width, foreground)
            end
          end)
      end
    end
  end
end
