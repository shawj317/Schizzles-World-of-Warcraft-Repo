-- Schizzle's Warrior: Details! profile switching by specialization (MoP Classic)
-- Details! has no working profile-per-spec option in MoP Classic, so this small Auto Run Code
-- snippet does it. Paste it into Details! > Options > Auto Run Code > "On Spec Change", press
-- Save, then type /reload. Details! keeps Auto Run Code account wide, so paste it only once.
--
-- It only switches when your current Details! profile is one of the three Schizzle's Warrior
-- profiles, so your other characters keep their own profiles. It waits until you leave combat.

local PROFILES = {
  [71] = "Schizzle's Warrior Arms",
  [72] = "Schizzle's Warrior Fury",
  [73] = "Schizzle's Warrior Protection",
}
local ONLY_FROM_OUR_PROFILES = true -- false: also switch away from any other profile on a Warrior

if Details.SchizzleWarriorSpecSwitch then return end -- already running this session
local state = {pending = false, lastSwitch = 0, warned = {}}
Details.SchizzleWarriorSpecSwitch = state

local _, playerClass = UnitClass("player")
if playerClass ~= "WARRIOR" then return end

local ours = {}
for _, name in pairs(PROFILES) do ours[name] = true end

local function currentSpecId()
  local index
  if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    index = C_SpecializationInfo.GetSpecialization()
  elseif GetSpecialization then
    index = GetSpecialization()
  end
  if not index or index < 1 then return nil end
  local specId
  if GetSpecializationInfo then
    specId = GetSpecializationInfo(index)
  elseif C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
    specId = C_SpecializationInfo.GetSpecializationInfo(index)
  end
  return specId or ({71, 72, 73})[index] -- Warrior spec order: Arms, Fury, Protection
end

local function check()
  state.pending = false
  local want = PROFILES[currentSpecId() or 0]
  if not want then return end
  local current = Details:GetCurrentProfileName()
  if current == want then return end
  if ONLY_FROM_OUR_PROFILES and not ours[current] then return end
  if not Details:GetProfile(want) then
    if not state.warned[want] then
      state.warned[want] = true
      print("|cffc79c6eSchizzle's Warrior:|r Details! profile \"" .. want .. "\" not found. Import it with that exact name.")
    end
    return
  end
  if InCombatLockdown() then
    state.waitForCombat = true
    return
  end
  if GetTime() - state.lastSwitch < 5 then
    state.pending = true
    C_Timer.After(5, check)
    return
  end
  state.lastSwitch = GetTime()
  Details:ApplyProfile(want)
end

local function queue(delay)
  if state.pending then return end
  state.pending = true
  C_Timer.After(delay or 1, check)
end

local frame = CreateFrame("Frame")
state.frame = frame
local events = {"PLAYER_ENTERING_WORLD", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_REGEN_ENABLED"}
for _, event in ipairs(events) do
  if not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event) then
    frame:RegisterEvent(event)
  end
end
frame:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_REGEN_ENABLED" then
    if state.waitForCombat then
      state.waitForCombat = false
      queue(1)
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    if unit == nil or unit == "player" then queue(1) end
  else
    queue(1.5)
  end
end)
queue(1)
