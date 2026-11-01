local M = {}
M.file = "05 Threat Percent"
M.name = "Schizzle's Warrior Threat %"
M.icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
M.desc = "Small threat % readout just above the left end of the health bar, in groups. DPS mode: shows when your threat is at or above the warning %. Tank mode: shows on mobs you are not securely tanking, so you can see how close you are to taking them back."
M.revision = 1
M.options = {
  {Type=4, Name="Only In Groups", Key="groupOnly", Desc="Hide the readout while solo.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=2, Name="DPS Warning %", Key="dpsPct", Desc="In DPS mode, only show the readout at or above this threat %.", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=70, Min=0, Max=100, Fraction=false},
  {Type=4, Name="Show In Tank Mode", Key="tankShow", Desc="Show the readout on mobs you are not securely tanking.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=2, Name="Font Size", Key="fontSize", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=9, Min=6, Max=16, Fraction=false},
  {Type=1, Name="Safe Colour", Key="lowColor", Desc="Colour well below the warning % (tank: far from regaining).", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={1, 0.85, 0.2, 1}},
  {Type=1, Name="Danger Colour", Key="highColor", Desc="Colour near 100%.", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={1, 0.2, 0.2, 1}},
}
M.hooks = {}
M.hooks["Initialization"] = [==[
function (modTable)
    function modTable.GetText(unitFrame)
        local t = unitFrame.SchizzleThreatText
        if not t then
            t = unitFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t:SetPoint("BOTTOMLEFT", unitFrame.healthBar, "TOPLEFT", 0, 1)
            Plater.SetFontOutlineAndShadow(t, "OUTLINE")
            unitFrame.SchizzleThreatText = t
        end
        local font, _, flags = t:GetFont()
        if font then
            t:SetFont(font, modTable.config.fontSize or 9, flags)
        end
        return t
    end

    function modTable.Hide(unitFrame)
        if unitFrame.SchizzleThreatText then
            unitFrame.SchizzleThreatText:Hide()
        end
    end
end
]==]
M.hooks["Nameplate Updated"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    local cfg = modTable.config
    if not unitId or not unitFrame.CanCheckAggro or not unitFrame.InCombat or not UnitAffectingCombat("player")
       or (cfg.groupOnly and not IsInGroup()) then
        modTable.Hide(unitFrame)
        return
    end

    local status = unitFrame.namePlateThreatStatus
    local pct = unitFrame.namePlateThreatPercent or 0
    local show
    if Plater.PlayerIsTank then
        show = cfg.tankShow and status ~= nil and status < 3
    else
        show = status ~= nil and pct >= (cfg.dpsPct or 70)
    end
    if not show then
        modTable.Hide(unitFrame)
        return
    end

    local t = modTable.GetText(unitFrame)
    t:SetText(string.format("%d%%", math.floor(pct + 0.5)))
    local f = math.min(math.max(pct / 100, 0), 1)
    local a, b = cfg.lowColor, cfg.highColor
    t:SetTextColor(a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f, 1)
    t:Show()
end
]==]
M.hooks["Nameplate Removed"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    modTable.Hide(unitFrame)
end
]==]
return M
