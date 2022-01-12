CaveBot.Actions = {}
vBot.lastLabel = ""

local antiTrapTriggered = false
-- it adds an action widget to list
CaveBot.addAction = function(action, value, focus)
  action = action:lower()
  local raction = CaveBot.Actions[action]
  if not raction then
    return warn("Invalid cavebot action: " .. action)
  end
  if type(value) == 'number' then
    value = tostring(value)
  end
  local widget = UI.createWidget("CaveBotAction", CaveBot.actionList)
  widget:setText(action .. ":" .. value:split("\n")[1])
  widget.action = action
  widget.value = value
  if raction.color then
    widget:setColor(raction.color)
  end
  widget.onDoubleClick = function(cwidget) -- edit on double click
    if CaveBot.Editor then
      schedule(20, function() -- schedule to have correct focus
        CaveBot.Editor.edit(cwidget.action, cwidget.value, function(action, value)
          CaveBot.editAction(cwidget, action, value)
          CaveBot.save()
        end)
      end)
    end
  end
  if focus then
    widget:focus()
    CaveBot.actionList:ensureChildVisible(widget)
  end
  return widget
end

-- it updates existing widget, you should call CaveBot.save() later
CaveBot.editAction = function(widget, action, value)
  action = action:lower()
  local raction = CaveBot.Actions[action]
  if not raction then
    return warn("Invalid cavebot action: " .. action)
  end
  
  if not widget.action or not widget.value then
    return warn("Invalid cavebot action widget, has missing action or value")  
  end
  
  widget:setText(action .. ":" .. value:split("\n")[1])
  widget.action = action
  widget.value = value
  if raction.color then
    widget:setColor(raction.color)
  end
  return widget
end

--[[
registerAction:
action - string, color - string, callback = function(value, retries, prev)
value is a string value of action, retries is number which will grow by 1 if return is "retry"
prev is a true when previuos action was executed succesfully, false otherwise
it must return true if executed correctly, false otherwise
it can also return string "retry", then the function will be called again in 20 ms
]]--
CaveBot.registerAction = function(action, color, callback) 
  action = action:lower()
  if CaveBot.Actions[action] then
    return warn("Duplicated acction: " .. action)
  end
  CaveBot.Actions[action] = {
    color=color,
    callback=callback
  }
end

CaveBot.registerAction("label", "yellow", function(value, retries, prev)
  vBot.lastLabel = value
  return true
end)

CaveBot.registerAction("gotolabel", "#FFFF55", function(value, retries, prev)
  return CaveBot.gotoLabel(value) 
end)

CaveBot.registerAction("delay", "#AAAAAA", function(value, retries, prev)
  if retries == 0 then
    CaveBot.delay(tonumber(value)) 
    return "retry"
  end
  return true
end)

CaveBot.registerAction("follow", "#FF8400", function(value, retries, prev)
  local c = getCreatureByName(value)
  if not c then
    print("CaveBot[follow]: can't find creature to follow")
    return false
  end
  local cpos = c:getPosition()
  local pos = pos()
  if getDistanceBetween(cpos, pos) < 2 then
    g_game.cancelFollow()
    return true
  else
    follow(c)
    delay(200)
    return "retry"
  end
end)

CaveBot.registerAction("function", "red", function(value, retries, prev)
  local prefix = "local retries = " .. retries .. "\nlocal prev = " .. tostring(prev) .. "\nlocal delay = CaveBot.delay\nlocal gotoLabel = CaveBot.gotoLabel\n"
  prefix = prefix .. "local macro = function() warn('Macros inside cavebot functions are not allowed') end\n"
  for extension, callbacks in pairs(CaveBot.Extensions) do
    prefix = prefix .. "local " .. extension .. " = CaveBot.Extensions." .. extension .. "\n"
  end
  local status, result = pcall(function() 
    return assert(load(prefix .. value, "cavebot_function"))()
  end)
  if not status then
    warn("warn in cavebot function:\n" .. result)
    return false
  end  
  return result
end)

CaveBot.registerAction("goto", "green", function(value, retries, prev)
  local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+),?\\s*([0-9]?)")
  if not pos[1] then
    warn("Invalid cavebot goto action value. It should be position (x,y,z), is: " .. value)
    return false
  end
  
  if CaveBot.Config.get("mapClick") then
    if retries >= 5 then
      return false -- tried 5 times, can't get there
    end
  else
    if retries >= 100 then
      return false -- tried 100 times, can't get there
    end  
  end

  local precision = tonumber(pos[1][5])
  pos = {x=tonumber(pos[1][2]), y=tonumber(pos[1][3]), z=tonumber(pos[1][4])}  
  local playerPos = player:getPosition()
  if pos.z ~= playerPos.z then 
    return false -- different floor
  end

  local maxDist = storage.extras.gotoMaxDistance or 40
  
  if math.abs(pos.x-playerPos.x) + math.abs(pos.y-playerPos.y) > maxDist then
    return false -- too far way
  end

  local minimapColor = g_map.getMinimapColor(pos)
  local stairs = (minimapColor >= 210 and minimapColor <= 213)
  
  if stairs then
    if math.abs(pos.x-playerPos.x) == 0 and math.abs(pos.y-playerPos.y) <= 0 then
      return true -- already at position
    end
  elseif math.abs(pos.x-playerPos.x) == 0 and math.abs(pos.y-playerPos.y) <= (precision or 1) then
      return true -- already at position
  end
  -- check if there's a path to that place, ignore creatures and fields
  local path = findPath(playerPos, pos, maxDist, { ignoreNonPathable = true, precision = 1, ignoreCreatures = true, allowUnseen = true, allowOnlyVisibleTiles = false  })
  if not path then
    return false -- there's no way
  end

  -- check if there's a path to destination but consider Creatures (attack only if trapped)
  local path2 = findPath(playerPos, pos, maxDist, { ignoreNonPathable = true, precision = 1 })
  if not path2 then
    local target = {} -- c = creature, d = distance
    for i, spec in pairs(getSpectators()) do
      local hppc = spec:getHealthPercent()
      if spec:isMonster() and (hppc and hppc > 0) then
        local path = findPath(playerPos, spec:getPosition(), 7, { ignoreNonPathable = true, precision = 1 })
        if path then
          local dist = getDistanceBetween(pos, spec:getPosition())
          if not target.d or target.d > dist then
            target = {c=spec, d=dist}
          end
        end
      end
    end
    if target.c then
      if target.c ~= getTarget() then
        attack(target.c)
      end
      g_game.setChaseMode(1)
      CaveBot.setOff()
      schedule(1000, function() CaveBot.setOn() end)
    else
      return false -- no other way
    end
  end
    
  -- try to find path, don't ignore creatures, don't ignore fields
  if not CaveBot.Config.get("ignoreFields") and CaveBot.walkTo(pos, 40) then
    return "retry"
  end
  
  -- try to find path, don't ignore creatures, ignore fields
  if CaveBot.walkTo(pos, maxDist, { ignoreNonPathable = true, allowUnseen = true, allowOnlyVisibleTiles = false }) then
    return "retry"
  end
  
  if retries >= 3 then
    -- try to lower precision, find something close to final position
    local precison = retries - 1
    if stairs then
      precison = 0
    end
    if CaveBot.walkTo(pos, 50, { ignoreNonPathable = true, precision = precison, allowUnseen = true, allowOnlyVisibleTiles = false }) then
      return "retry"
    end    
  end
  
  if not CaveBot.Config.get("mapClick") and retries >= 5 then
    return false
  end
  
  if CaveBot.Config.get("skipBlocked") then
    return false
  end

  -- everything else failed, try to walk ignoring creatures, maybe will work
  CaveBot.walkTo(pos, maxDist, { ignoreNonPathable = true, precision = 1, ignoreCreatures = true, allowUnseen = true, allowOnlyVisibleTiles = false })
  return "retry"
end)

CaveBot.registerAction("use", "#FFB272", function(value, retries, prev)
  local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)")
  if not pos[1] then
    local itemid = tonumber(value)
    if not itemid then
      warn("Invalid cavebot use action value. It should be (x,y,z) or item id, is: " .. value)
      return false
    end
    use(itemid)
    return true
  end

  pos = {x=tonumber(pos[1][2]), y=tonumber(pos[1][3]), z=tonumber(pos[1][4])}  
  local playerPos = player:getPosition()
  if pos.z ~= playerPos.z then 
    return false -- different floor
  end

  if math.max(math.abs(pos.x-playerPos.x), math.abs(pos.y-playerPos.y)) > 7 then
    return false -- too far way
  end

  local tile = g_map.getTile(pos)
  if not tile then
    return false
  end

  local topThing = tile:getTopUseThing()
  if not topThing then
    return false
  end

  use(topThing)
  CaveBot.delay(CaveBot.Config.get("useDelay") + CaveBot.Config.get("ping"))
  return true
end)

CaveBot.registerAction("usewith", "#EEB292", function(value, retries, prev)
  local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)")
  if not pos[1] then
    if not itemid then
      warn("Invalid cavebot usewith action value. It should be (itemid,x,y,z) or item id, is: " .. value)
      return false
    end
    use(itemid)
    return true
  end

  local itemid = tonumber(pos[1][2])
  pos = {x=tonumber(pos[1][3]), y=tonumber(pos[1][4]), z=tonumber(pos[1][5])}  
  local playerPos = player:getPosition()
  if pos.z ~= playerPos.z then 
    return false -- different floor
  end

  if math.max(math.abs(pos.x-playerPos.x), math.abs(pos.y-playerPos.y)) > 7 then
    return false -- too far way
  end

  local tile = g_map.getTile(pos)
  if not tile then
    return false
  end

  local topThing = tile:getTopUseThing()
  if not topThing then
    return false
  end

  usewith(itemid, topThing)
  CaveBot.delay(CaveBot.Config.get("useDelay") + CaveBot.Config.get("ping"))
  return true
end)

CaveBot.registerAction("say", "#FF55FF", function(value, retries, prev)
  say(value)
  return true
end)
CaveBot.registerAction("npcsay", "#FF55FF", function(value, retries, prev)
  NPC.say(value)
  return true
end)
