local M = {}
M.file = "04 Execute Indicator"
M.name = "Schizzle's Warrior Execute"
M.icon = "Interface\\Icons\\INV_Sword_48"
M.desc = "Enemies at or below 20% health (Execute range) get a red health %, a pixel glow and an EXE tag above the bar. Optionally only while you have the rage for Execute, and optionally recolours the bar (off by default so threat colours stay readable)."
M.revision = 1
M.options = {
  {Type=5, Name="Execute Range", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Execute range"},
  {Type=2, Name="Execute Health %", Key="lowPct", Desc="Health % at or below which Execute is usable (20% in Mists of Pandaria).", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=20, Min=1, Max=50, Fraction=false},
  {Type=1, Name="Health % Text Colour", Key="lowTextColor", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={1, 0.25, 0.25, 1}},
  {Type=4, Name="Recolour Bar In Execute Range", Key="lowBar", Desc="Also recolour the health bar. This overrides the threat colour, so it is off by default.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=1, Name="Execute Bar Colour", Key="lowBarColor", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={0.85, 0.1, 0.45, 1}},
  {Type=5, Name="Execute Glow", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Glow and tag"},
  {Type=4, Name="Execute Glow", Key="glowEnabled", Desc="Glow plates in Execute range (only if you know Execute).", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Only With Rage For Execute", Key="needRage", Desc="Hide the glow while you have less rage than Execute costs.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=2, Name="Execute Rage Cost", Key="rageCost", Desc="Rage needed for Execute (30 in Mists of Pandaria).", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=30, Min=0, Max=100, Fraction=false},
  {Type=4, Name="Only In Combat", Key="combatOnly", Desc="Only glow units that are in combat.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=1, Name="Glow Colour", Key="glowColor", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={1, 0.15, 0.15, 1}},
  {Type=4, Name="EXE Tag", Key="tag", Desc="Show a small EXE tag centred just above the bar.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
}
M.hooks = {}
M.hooks["Initialization"] = [==[
function (modTable)
    local EXECUTE = 5308
    local GLOW_KEY = "schizzleWarExecute"

    function modTable.HasExecute()
        if IsPlayerSpell and IsPlayerSpell(EXECUTE) then return true end
        if IsSpellKnown and IsSpellKnown(EXECUTE) then return true end
        return false
    end

    local function getTag(unitFrame)
        local tag = unitFrame.SchizzleExeTag
        if not tag then
            tag = unitFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tag:SetPoint("BOTTOM", unitFrame.healthBar, "TOP", 0, 1)
            tag:SetText("EXE")
            Plater.SetFontOutlineAndShadow(tag, "OUTLINE")
            unitFrame.SchizzleExeTag = tag
        end
        return tag
    end

    function modTable.Clear(unitFrame, envTable)
        if envTable.exeGlow then
            Plater.StopPixelGlow(unitFrame.healthBar, GLOW_KEY)
            envTable.exeGlow = nil
        end
        if unitFrame.SchizzleExeTag then
            unitFrame.SchizzleExeTag:Hide()
        end
        if envTable.lowText then
            local lp = unitFrame.healthBar and unitFrame.healthBar.lifePercent
            local c = envTable.origTextColor
            if lp and c then lp:SetTextColor(c[1], c[2], c[3], c[4]) end
            envTable.lowText = nil
        end
        if envTable.lowBar then
            envTable.lowBar = nil
            Plater.RefreshNameplateColor(unitFrame)
        end
    end

    function modTable.Update(unitFrame, unitId, envTable)
        local cfg = modTable.config
        if not unitId or not UnitExists(unitId) or not UnitCanAttack("player", unitId) or UnitIsDead(unitId) then
            modTable.Clear(unitFrame, envTable)
            return
        end
        local hp, maxHp = UnitHealth(unitId), UnitHealthMax(unitId)
        if not hp or not maxHp or maxHp <= 0 then
            return
        end
        local inRange = hp > 0 and (hp / maxHp * 100) <= (cfg.lowPct or 20)

        --health % text (and optional bar)
        local lp = unitFrame.healthBar.lifePercent
        if inRange then
            if lp then
                if not envTable.lowText then
                    local r, g, b, a = lp:GetTextColor()
                    envTable.origTextColor = {r, g, b, a}
                    envTable.lowText = true
                end
                local c = cfg.lowTextColor
                lp:SetTextColor(c[1], c[2], c[3], c[4] or 1)
            end
            if cfg.lowBar then
                envTable.lowBar = true
                Plater.SetNameplateColor(unitFrame, cfg.lowBarColor)
            end
        else
            if envTable.lowText then
                local c = envTable.origTextColor
                if lp and c then lp:SetTextColor(c[1], c[2], c[3], c[4]) end
                envTable.lowText = nil
            end
            if envTable.lowBar then
                envTable.lowBar = nil
                Plater.RefreshNameplateColor(unitFrame)
            end
        end

        --glow + tag
        local glow = inRange and cfg.glowEnabled and modTable.hasExecute
        if glow and cfg.combatOnly and not UnitAffectingCombat(unitId) then
            glow = false
        end
        if glow and cfg.needRage and not modTable.enoughRage then
            glow = false
        end

        if glow then
            if not envTable.exeGlow then
                local c = cfg.glowColor
                Plater.StartPixelGlow(unitFrame.healthBar, c, {
                    glowType = "pixel", color = c, N = 12, frequency = 0.4,
                    th = 2, xOffset = 2, yOffset = 2, border = false, key = GLOW_KEY,
                }, GLOW_KEY)
                envTable.exeGlow = true
            end
            if cfg.tag then
                local tag = getTag(unitFrame)
                local c = cfg.glowColor
                tag:SetTextColor(c[1], c[2], c[3], 1)
                tag:Show()
            elseif unitFrame.SchizzleExeTag then
                unitFrame.SchizzleExeTag:Hide()
            end
        else
            if envTable.exeGlow then
                Plater.StopPixelGlow(unitFrame.healthBar, GLOW_KEY)
                envTable.exeGlow = nil
            end
            if unitFrame.SchizzleExeTag then
                unitFrame.SchizzleExeTag:Hide()
            end
        end
    end

    --player-side state, refreshed at most 5x a second
    modTable.nextPlayerCheck = 0
    function modTable.RefreshPlayerState()
        local now = GetTime()
        if now >= modTable.nextPlayerCheck then
            modTable.nextPlayerCheck = now + 0.2
            modTable.hasExecute = modTable.HasExecute()
            local rage = UnitPower("player", 1) or 0
            modTable.enoughRage = rage >= (modTable.config.rageCost or 30)
        end
    end
end
]==]
M.hooks["Nameplate Added"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    envTable.lowText = nil
    envTable.lowBar = nil
    envTable.origTextColor = nil
    modTable.RefreshPlayerState()
    modTable.Update(unitFrame, unitId, envTable)
end
]==]
M.hooks["Health Update"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    modTable.RefreshPlayerState()
    modTable.Update(unitFrame, unitId, envTable)
end
]==]
M.hooks["Nameplate Updated"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    modTable.RefreshPlayerState()
    modTable.Update(unitFrame, unitId, envTable)
end
]==]
M.hooks["Nameplate Removed"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    modTable.Clear(unitFrame, envTable)
end
]==]
return M
