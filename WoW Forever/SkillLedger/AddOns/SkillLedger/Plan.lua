-- Cheapest path. tools/plan.py is the same rules; tools/test_plan.py checks them.
--
-- Reputation discount is the Classic curve from patch 2.3 on (Friendly 5%,
-- Honored 10%, Revered 15%, Exalted 20%). Neutral and below pay full price.
-- Unfriendly and worse cannot buy. The client truncates:
-- floor(base * (20 - steps) / 20). A merchant-window price is kept while the
-- standing saved with it is unchanged. Pre-2.3 was a flat 10% from Honored;
-- Forever's server is not in the client tables, so this follows the curve
-- Jon named. No goblin racial and no PvP-rank discount.

SkillLedgerPlan = SkillLedgerPlan or {}
local P = SkillLedgerPlan

local STANDING_NAME = {
  [1] = "Hated",
  [2] = "Hostile",
  [3] = "Unfriendly",
  [4] = "Neutral",
  [5] = "Friendly",
  [6] = "Honored",
  [7] = "Revered",
  [8] = "Exalted",
}

function P.DiscountSteps(standing)
  if standing == 5 then return 1 end
  if standing == 6 then return 2 end
  if standing == 7 then return 3 end
  if standing == 8 then return 4 end
  return 0
end

function P.DiscountPercent(standing)
  return P.DiscountSteps(standing) * 5
end

function P.ApplyDiscount(base, steps)
  if not base then return nil end
  base = math.floor(base)
  if steps <= 0 then return base end
  if steps > 4 then steps = 4 end
  return math.floor(base * (20 - steps) / 20)
end

function P.StandingName(standing)
  if not standing then return "" end
  return STANDING_NAME[standing] or ""
end

function P.Money(copper)
  copper = math.floor((copper or 0) + 0.5)
  local neg = copper < 0
  if neg then copper = -copper end
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local coppers = copper % 100
  local text
  if gold > 0 then
    text = string.format("%dg %02ds %02dc", gold, silver, coppers)
  elseif silver > 0 then
    text = string.format("%ds %02dc", silver, coppers)
  else
    text = string.format("%dc", coppers)
  end
  if neg then return "-" .. text end
  return text
end

local function allows(mask, bit)
  if mask == nil or mask == 0 or mask < 0 then return true end
  if bit == nil or bit == 0 then return true end
  return (mask % (bit * 2)) >= bit
end

local function opposite(side)
  if side == "Horde" then return "Alliance" end
  if side == "Alliance" then return "Horde" end
  return nil
end

local function item_name(state, itemId)
  return state.items[itemId] or ("Item " .. tostring(itemId))
end

local function vendor_quote(state, itemId)
  local catalog = state.vendor[itemId]
  local captured = state.captured[itemId]
  if captured and captured.unit and captured.unit > 0 then
    local standingNow = nil
    if captured.factionId then standingNow = state.standings[captured.factionId] end
    if not captured.factionId or not standingNow or standingNow == captured.standingId then
      return captured.unit, {
        source = "merchant",
        base = catalog and catalog.price or nil,
        discount = captured.standingId and P.DiscountPercent(captured.standingId) or 0,
        factionId = captured.factionId,
        faction = captured.faction or "",
        standing = P.StandingName(captured.standingId),
        assumed = false,
      }
    end
  end
  if not catalog or not catalog.price then
    if captured and captured.unit and captured.unit > 0 then
      return captured.unit, {
        source = "merchant", base = nil, discount = 0,
        factionId = captured.factionId, faction = captured.faction or "",
        standing = P.StandingName(captured.standingId), assumed = false,
      }
    end
    return nil, nil
  end
  local base = catalog.price
  local factions = catalog.factions or {}
  if #factions == 0 then
    return base, {
      source = "vendor-nofaction", base = base, discount = 0,
      factionId = nil, faction = "", standing = "Neutral", assumed = true,
    }
  end
  local blocked = opposite(state.side or "")
  local best, bestUnit, bestId
  for i = 1, #factions do
    local faction = factions[i]
    if not (blocked and faction.side == blocked) then
      local standing = state.standings[faction.id]
      local assumed = standing == nil
      if not standing then standing = 4 end
      if standing >= 4 then
        local unit = P.ApplyDiscount(base, P.DiscountSteps(standing))
        if not best or unit < bestUnit or (unit == bestUnit and faction.id < bestId) then
          bestUnit = unit
          bestId = faction.id
          best = {
            source = assumed and "vendor-assumed" or "vendor",
            base = base,
            discount = P.DiscountPercent(standing),
            factionId = faction.id,
            faction = faction.name or "",
            standing = P.StandingName(standing),
            assumed = assumed,
          }
        end
      end
    end
  end
  if not best then return nil, nil end
  return bestUnit, best
end

local function buy_quote(state, itemId)
  local vendorUnit, info = vendor_quote(state, itemId)
  local ah = state.prices[itemId]
  local ahSource = (state.priceSources and state.priceSources[itemId]) or "ah"
  if vendorUnit and ah and ah > 0 then
    if ah < vendorUnit then
      return ah, { source = ahSource, base = nil, discount = 0, factionId = nil, faction = "", standing = "", assumed = false }
    end
    return vendorUnit, info
  end
  if vendorUnit then return vendorUnit, info end
  if ah and ah > 0 then
    return ah, { source = ahSource, base = nil, discount = 0, factionId = nil, faction = "", standing = "", assumed = false }
  end
  return nil, nil
end

local function leaf_unit(state, itemId, seen)
  if seen[itemId] then return nil end
  local buyUnit = buy_quote(state, itemId)
  local craftUnit = nil
  local makers = state.madeBy[itemId]
  if makers then
    seen[itemId] = true
    for i = 1, #makers do
      local recipe = makers[i]
      local count = recipe.count or 0
      if count > 0 then
        local total, ok = 0, true
        for r = 1, #recipe.reagents do
          local unit = leaf_unit(state, recipe.reagents[r][1], seen)
          if not unit then ok = false break end
          total = total + unit * recipe.reagents[r][2]
        end
        if ok then
          local each = total / count
          if not craftUnit or each < craftUnit then craftUnit = each end
        end
      end
    end
    seen[itemId] = nil
  end
  if buyUnit and craftUnit then
    if buyUnit < craftUnit then return buyUnit end
    return craftUnit
  end
  return buyUnit or craftUnit
end

local function best_craft(state, itemId, seen)
  if seen[itemId] then return nil, nil end
  local makers = state.madeBy[itemId]
  if not makers then return nil, nil end
  seen[itemId] = true
  local bestUnit, bestRecipe
  for i = 1, #makers do
    local recipe = makers[i]
    local count = recipe.count or 0
    if count > 0 then
      local total, ok = 0, true
      for r = 1, #recipe.reagents do
        local unit = leaf_unit(state, recipe.reagents[r][1], seen)
        if not unit then ok = false break end
        total = total + unit * recipe.reagents[r][2]
      end
      if ok then
        local each = total / count
        if not bestUnit or each < bestUnit or (each == bestUnit and recipe.spell < bestRecipe.spell) then
          bestUnit = each
          bestRecipe = recipe
        end
      end
    end
  end
  seen[itemId] = nil
  return bestUnit, bestRecipe
end

local function discount_label(name, info)
  if not info then return "" end
  local source = info.source or ""
  local percent = info.discount or 0
  local faction = info.faction or ""
  local standing = info.standing or ""
  if source == "merchant" then
    local where = standing
    if faction ~= "" then
      if where ~= "" then where = where .. ", " .. faction else where = faction end
    end
    if where ~= "" then return name .. ": merchant price (" .. where .. ")" end
    return name .. ": merchant price"
  end
  if source == "vendor-nofaction" then
    return name .. ": vendor price, faction unknown, no discount"
  end
  if source == "vendor" or source == "vendor-assumed" then
    local assumed = ""
    if info.assumed then assumed = " (standing not saved, treated as Neutral)" end
    if percent > 0 then
      return name .. ": " .. percent .. "% " .. standing .. ", " .. faction .. assumed
    end
    return name .. ": no discount, " .. standing .. ", " .. faction .. assumed
  end
  return ""
end

local function acquire(state, itemId, count, seen, bag, bought, pay, unpriced, notes, discounts)
  if count <= 1e-9 then return end
  local name = item_name(state, itemId)
  local have = state.inventory[itemId] or 0
  local orig = state.original[itemId] or 0
  local fromOrig = count
  if orig < fromOrig then fromOrig = orig end
  if have < fromOrig then fromOrig = have end
  if fromOrig > 0 then
    state.original[itemId] = orig - fromOrig
    state.inventory[itemId] = have - fromOrig
    bag[itemId] = (bag[itemId] or 0) + fromOrig
    have = have - fromOrig
    orig = orig - fromOrig
  end
  local fromCrafted = count - fromOrig
  local craftedHave = have - orig
  if craftedHave < 0 then craftedHave = 0 end
  if fromCrafted > craftedHave then fromCrafted = craftedHave end
  if fromCrafted > 0 then
    state.inventory[itemId] = have - fromCrafted
  end
  local need = count - fromOrig - fromCrafted
  if need <= 1e-9 then return end
  local buyUnit, buyInfo = buy_quote(state, itemId)
  local craftUnit, craftRecipe = best_craft(state, itemId, seen)
  local useCraft = craftRecipe and (not buyUnit or (craftUnit and craftUnit < buyUnit - 1e-9))
  if useCraft then
    if buyUnit then notes["crafting " .. name .. " beats buying it"] = true end
    local crafts = need / craftRecipe.count
    seen[itemId] = true
    for r = 1, #craftRecipe.reagents do
      acquire(state, craftRecipe.reagents[r][1], craftRecipe.reagents[r][2] * crafts, seen, bag, bought, pay, unpriced, notes, discounts)
    end
    seen[itemId] = nil
    return
  end
  if buyUnit then
    if craftUnit then notes["buying " .. name .. " beats crafting it"] = true end
    pay[1] = pay[1] + need * buyUnit
    bought[itemId] = (bought[itemId] or 0) + need
    local label = discount_label(name, buyInfo)
    if label ~= "" then discounts[label] = true end
    return
  end
  unpriced[name] = true
end

local function chance(recipe, skill)
  if skill < recipe.orange or skill >= recipe.grey then return 0 end
  local yellow, grey = recipe.yellow, recipe.grey
  if grey <= yellow then return 1 end
  local value = (grey - skill) / (grey - yellow)
  if value > 1 then return 1 end
  if value < 0 then return 0 end
  return value
end

local function color_at(recipe, skill)
  if skill < recipe.yellow then return "orange" end
  if skill < recipe.green then return "yellow" end
  if skill < recipe.grey then return "green" end
  return "grey"
end

local function copy_map(src)
  local out = {}
  for k, v in pairs(src) do out[k] = v end
  return out
end

local function keys_sorted(map)
  local out = {}
  for key in pairs(map) do out[#out + 1] = key end
  table.sort(out)
  return out
end

local function cost_crafts(state, recipe, crafts)
  local bag, bought, unpriced, notes, discounts = {}, {}, {}, {}, {}
  local pay = { 0 }
  local seen = {}
  for i = 1, #recipe.reagents do
    acquire(state, recipe.reagents[i][1], recipe.reagents[i][2] * crafts, seen, bag, bought, pay, unpriced, notes, discounts)
  end
  if recipe.made and recipe.made ~= 0 and recipe.count and recipe.count > 0 then
    state.inventory[recipe.made] = (state.inventory[recipe.made] or 0) + crafts * recipe.count
  end
  return { pay = pay[1], bag = bag, bought = bought, unpriced = unpriced, notes = notes, discounts = discounts }
end

local function eligible(recipe, skill, state)
  if recipe.skillup == false then return false end
  if skill < recipe.orange or skill >= recipe.grey then return false end
  if not allows(recipe.classMask or 0, state.classMask or 0) then return false end
  if not allows(recipe.raceMask or 0, state.raceMask or 0) then return false end
  return chance(recipe, skill) > 0
end

local function iround(value)
  return math.floor(value + 0.5)
end

function P.PlanProfession(state, skillId, rank, cap)
  local recipes = {}
  for i = 1, #state.recipes do
    if state.recipes[i].skill == skillId then recipes[#recipes + 1] = state.recipes[i] end
  end
  table.sort(recipes, function(a, b) return a.spell < b.spell end)
  local prof
  for i = 1, #state.professions do
    if state.professions[i].id == skillId then prof = state.professions[i] end
  end
  local name = prof and prof.name or tostring(skillId)
  local notes = {}
  if prof and prof.gathering and skillId == 186 then
    notes[#notes + 1] = "Mining points also come from mining nodes. This path is only smelts and other crafts that grant Mining skill."
  elseif prof and prof.gathering then
    notes[#notes + 1] = name .. " is a gathering skill. The client tables have no node-by-node craft path, so there is nothing to buy for the points that come from gathering."
  end
  rank = math.floor(rank or 0)
  cap = math.floor(cap or 0)
  if cap > 300 then cap = 300 end
  if rank >= cap then
    notes[#notes + 1] = "Already at " .. rank .. ", the current cap."
    return { skill = skillId, name = name, rank = rank, cap = cap, steps = {}, gaps = {}, notes = notes, total = 0, unpriced = {}, reached = rank }
  end
  local stepsRaw, gaps = {}, {}
  local skill, guard = rank, 0
  while skill < cap and guard < 400 do
    guard = guard + 1
    local best, bestKey, bestCrafts
    for i = 1, #recipes do
      local recipe = recipes[i]
      if eligible(recipe, skill, state) then
        local crafts = 1 / (chance(recipe, skill) * (recipe.ups or 1))
        local savedInv = copy_map(state.inventory)
        local savedOrig = copy_map(state.original)
        local result = cost_crafts(state, recipe, crafts)
        state.inventory = savedInv
        state.original = savedOrig
        local unpricedFlag = 0
        if next(result.unpriced) then unpricedFlag = 1 end
        local keyPay, keySpell = result.pay, recipe.spell
        local better = false
        if not bestKey then
          better = true
        elseif unpricedFlag < bestKey[1] then
          better = true
        elseif unpricedFlag == bestKey[1] and keyPay < bestKey[2] then
          better = true
        elseif unpricedFlag == bestKey[1] and keyPay == bestKey[2] and keySpell < bestKey[3] then
          better = true
        end
        if better then
          best = recipe
          bestKey = { unpricedFlag, keyPay, keySpell }
          bestCrafts = crafts
        end
      end
    end
    if not best then
      gaps[#gaps + 1] = skill
      notes[#notes + 1] = "No skill-up recipe from " .. skill .. " to " .. cap .. "."
      break
    end
    local committed = cost_crafts(state, best, bestCrafts)
    local row = {
      spell = best.spell, recipe = best.name, start = skill, finish = skill + 1,
      crafts = bestCrafts, color = color_at(best, skill), pay = committed.pay,
      bag = committed.bag, bought = committed.bought, unpriced = committed.unpriced,
      notes = committed.notes, discounts = committed.discounts, rankSource = best.rankSource or "",
    }
    local prev = stepsRaw[#stepsRaw]
    if prev and prev.spell == row.spell then
      prev.finish = row.finish
      prev.crafts = prev.crafts + row.crafts
      prev.pay = prev.pay + row.pay
      for itemId, count in pairs(row.bag) do prev.bag[itemId] = (prev.bag[itemId] or 0) + count end
      for itemId, count in pairs(row.bought) do prev.bought[itemId] = (prev.bought[itemId] or 0) + count end
      for key, value in pairs(row.unpriced) do prev.unpriced[key] = value end
      for key, value in pairs(row.notes) do prev.notes[key] = value end
      for key, value in pairs(row.discounts) do prev.discounts[key] = value end
    else
      stepsRaw[#stepsRaw + 1] = row
    end
    skill = skill + 1
  end
  local steps, running, unpriced = {}, 0, {}
  local seenMissing = {}
  for i = 1, #stepsRaw do
    local row = stepsRaw[i]
    local cost = iround(row.pay)
    running = running + cost
    local reagents, seenItem = {}, {}
    for itemId in pairs(row.bag) do seenItem[itemId] = true end
    for itemId in pairs(row.bought) do seenItem[itemId] = true end
    local ids = keys_sorted(seenItem)
    for n = 1, #ids do
      local itemId = ids[n]
      reagents[#reagents + 1] = {
        id = itemId,
        name = item_name(state, itemId),
        fromStock = row.bag[itemId] or 0,
        buy = row.bought[itemId] or 0,
      }
    end
    for missing in pairs(row.unpriced) do
      if not seenMissing[missing] then
        seenMissing[missing] = true
        unpriced[#unpriced + 1] = missing
      end
    end
    table.sort(unpriced)
    steps[#steps + 1] = {
      spell = row.spell, recipe = row.recipe, start = row.start, finish = row.finish,
      crafts = row.crafts, color = row.color, reagents = reagents, cost = cost, running = running,
      unpriced = keys_sorted(row.unpriced), notes = keys_sorted(row.notes),
      discounts = keys_sorted(row.discounts), rankSource = row.rankSource,
    }
  end
  if rank < 300 and cap < 300 and skill >= cap and #gaps == 0 then
    notes[#notes + 1] = "Stopped at " .. cap .. ", the current trained cap. The next trainer ranks are 75, 150, 225 and 300."
  end
  return {
    skill = skillId, name = name, rank = rank, cap = cap, steps = steps, gaps = gaps,
    notes = notes, total = running, unpriced = unpriced, reached = skill,
  }
end

local function made_by(recipes)
  local out = {}
  for i = 1, #recipes do
    local recipe = recipes[i]
    if recipe.made and recipe.made ~= 0 and recipe.count and recipe.count > 0 then
      out[recipe.made] = out[recipe.made] or {}
      local list = out[recipe.made]
      list[#list + 1] = recipe
    end
  end
  for _, list in pairs(out) do
    table.sort(list, function(a, b) return a.spell < b.spell end)
  end
  return out
end

function P.PlanCharacter(data, inventory, professions, prices, standings, captured, side, classMask, raceMask, priceSources)
  local clean = {}
  for key, value in pairs(inventory or {}) do
    if value and value > 0 then clean[key] = value end
  end
  local state = {
    recipes = data.recipes,
    professions = data.professions,
    items = data.items,
    vendor = data.vendor,
    madeBy = made_by(data.recipes),
    inventory = copy_map(clean),
    original = copy_map(clean),
    prices = prices or {},
    priceSources = priceSources or {},
    standings = standings or {},
    captured = captured or {},
    side = side or "",
    classMask = classMask or 0,
    raceMask = raceMask or 0,
  }
  local plans, gross = {}, {}
  for i = 1, #professions do
    local profession = professions[i]
    state.inventory = copy_map(clean)
    state.original = copy_map(clean)
    local skillId = profession.skillLine or profession.skill
    if not skillId and profession.name then
      for n = 1, #data.professions do
        if data.professions[n].name == profession.name then skillId = data.professions[n].id end
      end
    end
    if skillId then
      local cap = profession.maxRank or profession.cap or 300
      local result = P.PlanProfession(state, skillId, profession.rank or 0, cap)
      plans[#plans + 1] = result
      for s = 1, #result.steps do
        local reagents = result.steps[s].reagents
        for r = 1, #reagents do
          local reagent = reagents[r]
          gross[reagent.id] = (gross[reagent.id] or 0) + reagent.fromStock + reagent.buy
        end
      end
    end
  end
  local shopping, ids = {}, keys_sorted(gross)
  for i = 1, #ids do
    local itemId = ids[i]
    local need = gross[itemId]
    local have = (inventory and inventory[itemId]) or 0
    local fromStock = need
    if have < fromStock then fromStock = have end
    if fromStock < 0 then fromStock = 0 end
    local buy = need - fromStock
    if buy < 1e-9 then buy = 0 end
    local buyWhole = 0
    if buy > 0 then buyWhole = math.ceil(buy - 1e-9) end
    local unit, info = buy_quote(state, itemId)
    local line = 0
    if unit and buyWhole > 0 then line = buyWhole * unit end
    local source = "stock"
    if info and info.source then source = info.source end
    if buyWhole > 0 and not unit then source = "missing" end
    shopping[#shopping + 1] = {
      id = itemId, name = item_name(state, itemId), need = need, fromStock = fromStock,
      buy = buy, buyWhole = buyWhole, unit = unit, cost = line, source = source,
      discount = info and info.discount or 0, faction = info and info.faction or "",
      standing = info and info.standing or "", base = info and info.base or nil,
      assumed = info and info.assumed or false,
    }
  end
  return plans, shopping
end
