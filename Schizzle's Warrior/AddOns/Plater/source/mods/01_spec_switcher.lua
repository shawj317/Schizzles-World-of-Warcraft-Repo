local M = {}
M.file = "01 Spec Switcher"
M.name = "Schizzle's Warrior Spec Switcher"
M.icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
M.desc = "Plater has no spec profiles of its own. This mod watches your active specialization (dual-spec swaps, respecs, logins) and switches Plater to the matching Schizzle's Warrior profile: Arms, Fury or Protection. It waits until you leave combat, and does nothing if the target profile doesn't exist."
M.revision = 1
M.options = {
  {Type=5, Name="Spec Switcher", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Spec profile switching"},
  {Type=4, Name="Enabled", Key="enabled", Desc="Switch Plater profile when your Warrior specialization changes.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Switch Automatically", Key="autoSwitch", Desc="On: switch the profile for you (Plater then asks whether to /reload; Yes is recommended). Off: only print which profile to pick.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=3, Name="Arms Profile Name", Key="armsProfile", Desc="Plater profile to use in Arms. Must match the name you typed when importing.", Icon="Interface\\AddOns\\Plater\\images\\option_text", Value="Schizzle's Warrior Arms"},
  {Type=3, Name="Fury Profile Name", Key="furyProfile", Desc="Plater profile to use in Fury.", Icon="Interface\\AddOns\\Plater\\images\\option_text", Value="Schizzle's Warrior Fury"},
  {Type=3, Name="Protection Profile Name", Key="protProfile", Desc="Plater profile to use in Protection.", Icon="Interface\\AddOns\\Plater\\images\\option_text", Value="Schizzle's Warrior Protection"},
}
M.hooks = {}
M.hooks["Initialization"] = [==[
function (modTable)
    --one event frame per session, shared by the copies of this mod in all three profiles
    local SPEC_KEY = {[71] = "armsProfile", [72] = "furyProfile", [73] = "protProfile"}
    local SPEC_NAME = {[71] = "Arms", [72] = "Fury", [73] = "Protection"}
    local S = SchizzleWarriorSpecSwitch
    if not S then
        S = {}
        SchizzleWarriorSpecSwitch = S
    end
    S.mod = modTable
    S.active = true
    modTable.S = S

    local function say(msg)
        print("|cFFC79C6ESchizzle's Warrior Plater:|r " .. msg)
    end

    function S.SpecId()
        local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
        local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
        if not getSpec or not getInfo then return nil end
        local index = getSpec()
        if not index or index == 0 then return nil end
        return (getInfo(index))
    end

    function S.ProfileExists(name)
        local list = PlaterAPI and PlaterAPI.GetProfileKeys and PlaterAPI:GetProfileKeys()
        if type(list) ~= "table" then return false end
        for k, v in pairs(list) do
            if k == name or v == name then return true end
        end
        return false
    end

    function S.Check()
        S.pending = nil
        if not S.active then return end
        local cfg = S.mod.config
        if not cfg.enabled then return end
        local _, class = UnitClass("player")
        if class ~= "WARRIOR" then return end
        local specId = S.SpecId()
        local key = specId and SPEC_KEY[specId]
        if not key then return end
        local want = cfg[key]
        if type(want) ~= "string" or want == "" then return end
        local current = PlaterAPI:GetCurrentProfileKey()
        if current == want then
            S.warned = nil
            return
        end
        if not S.ProfileExists(want) then
            if S.warned ~= want then
                S.warned = want
                say(SPEC_NAME[specId] .. " profile '" .. want .. "' not found. Import it, or fix the name in this mod's options.")
            end
            return
        end
        if InCombatLockdown() or UnitAffectingCombat("player") then
            S.waitCombat = true
            return
        end
        if not cfg.autoSwitch then
            if S.told ~= want then
                S.told = want
                say("you are " .. SPEC_NAME[specId] .. ". Switch Plater to '" .. want .. "' (/plater > Profiles).")
            end
            return
        end
        local now = GetTime()
        if S.lastSwitch and now - S.lastSwitch < 5 then return end
        S.lastSwitch = now
        say(SPEC_NAME[specId] .. " detected, switching Plater profile to '" .. want .. "'.")
        PlaterAPI:SetProfile(want)
    end

    function S.Schedule(delay)
        if S.pending then return end
        S.pending = true
        C_Timer.After(delay or 1.5, function() S.Check() end)
    end

    if not S.frame then
        local f = CreateFrame("Frame")
        S.frame = f
        local events = {"PLAYER_ENTERING_WORLD", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_REGEN_ENABLED"}
        for _, ev in ipairs(events) do
            if not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(ev) then
                f:RegisterEvent(ev)
            end
        end
        f:SetScript("OnEvent", function(_, event, unit)
            if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
            if event == "PLAYER_REGEN_ENABLED" then
                if not S.waitCombat then return end
                S.waitCombat = nil
            end
            S.Schedule()
        end)
    end

    S.Schedule(3)
end
]==]
M.hooks["Deinitialization"] = [==[
function (modTable)
    local S = modTable.S
    if S and S.mod == modTable then
        S.active = false
    end
end
]==]
return M
