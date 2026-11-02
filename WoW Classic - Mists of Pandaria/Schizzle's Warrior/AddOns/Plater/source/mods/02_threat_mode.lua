local M = {}
M.file = "02 Threat Mode"
M.name = "Schizzle's Warrior Threat Mode"
M.icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
M.desc = "Chooses tank or DPS threat colours for a Warrior. Protection profile: tank colours in Protection spec or Defensive Stance. Arms/Fury profiles: DPS colours unless you turn on Defensive Stance = Tank. The colours themselves live in the profile (Threat & Aggro tab)."
M.revision = 1
M.options = {
  {Type=5, Name="Threat Mode", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Tank/DPS threat mode"},
  {Type=4, Name="Protection Spec = Tank", Key="useProtSpec", Desc="Use tank threat colours while your active spec is Protection.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Defensive Stance = Tank", Key="useDefensive", Desc="Use tank threat colours while in Defensive Stance, whatever your spec.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Group Role TANK = Tank", Key="useGroupRole", Desc="Also use tank colours when your assigned group role is TANK.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=4, Name="Force Tank Colours", Key="forceTank", Desc="Always use tank colours (overrides everything).", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=4, Name="Force DPS Colours", Key="forceDps", Desc="Always use DPS colours (ignored if Force Tank is on).", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=4, Name="Non-Warriors: Leave Plater Alone", Key="warriorOnly", Desc="On other classes, let Plater decide tank/DPS unless a Force option is on.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Print Mode Changes", Key="announce", Desc="Print a chat line when the threat mode flips.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
}
M.hooks = {}
M.hooks["Initialization"] = [==[
function (modTable)
    local DEFENSIVE = 71
    modTable.lastCheck = 0
    modTable.wantTank = nil
    modTable.serial = 0

    function modTable.InDefensive()
        local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
        for i = 1, numForms do
            local _, isActive, _, spellID = GetShapeshiftFormInfo(i)
            if isActive and spellID == DEFENSIVE then
                return true
            end
        end
        if AuraUtil and AuraUtil.FindAuraByName then
            if AuraUtil.FindAuraByName("Defensive Stance", "player", "HELPFUL") then
                return true
            end
        end
        return false
    end

    function modTable.SpecId()
        local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
        local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
        if not getSpec or not getInfo then return nil end
        local index = getSpec()
        if not index or index == 0 then return nil end
        return (getInfo(index))
    end

    --true (tank), false (dps) or nil (leave Plater's own decision)
    function modTable.WantTank()
        local cfg = modTable.config
        if cfg.forceTank then return true end
        if cfg.forceDps then return false end
        local _, class = UnitClass("player")
        if class ~= "WARRIOR" then
            if cfg.warriorOnly then return nil end
            return UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" or false
        end
        if cfg.useGroupRole and UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" then
            return true
        end
        if cfg.useProtSpec and modTable.SpecId() == 73 then
            return true
        end
        if cfg.useDefensive and modTable.InDefensive() then
            return true
        end
        return false
    end
end
]==]
M.hooks["Nameplate Updated"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    local now = GetTime()
    if now - (modTable.lastCheck or 0) > 0.2 then
        modTable.lastCheck = now
        modTable.wantTank = modTable.WantTank()
    end

    local want = modTable.wantTank
    if want == nil then
        return
    end

    local current = Plater.PlayerIsTank and true or false
    if current ~= want then
        Plater.PlayerIsTank = want
        modTable.serial = (modTable.serial or 0) + 1
        if modTable.config.announce then
            print("|cFFC79C6ESchizzle's Warrior Plater:|r threat colours -> " .. (want and "TANK" or "DPS"))
        end
    end

    if envTable.serial ~= modTable.serial then
        envTable.serial = modTable.serial
        if unitFrame.CanCheckAggro and UnitAffectingCombat("player") then
            Plater.UpdateNameplateThread(unitFrame)
        end
    end
end
]==]
return M
