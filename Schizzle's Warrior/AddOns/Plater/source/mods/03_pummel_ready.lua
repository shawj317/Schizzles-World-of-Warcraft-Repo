local M = {}
M.file = "03 Pummel Ready"
M.name = "Schizzle's Warrior Pummel Ready"
M.icon = "Interface\\Icons\\INV_Gauntlets_04"
M.desc = "Interruptible casts glow when Pummel is ready (and in range), and turn a muted bronze while Pummel is on cooldown so you know someone else has to kick. If Pummel is down and you have Disrupting Shout talented and ready, that counts as ready instead. Casts you can't interrupt keep the grey colour and shield from the profile."
M.revision = 1
M.options = {
  {Type=5, Name="Interrupt", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Interrupt"},
  {Type=3, Name="Interrupt Spell ID", Key="kickSpell", Desc="Spell ID of your main interrupt. Warrior Pummel = 6552.", Icon="Interface\\AddOns\\Plater\\images\\option_text", Value="6552"},
  {Type=3, Name="Backup Interrupt Spell ID", Key="backupSpell", Desc="Used when the main interrupt is on cooldown. Disrupting Shout (talent) = 102060. Leave empty to disable.", Icon="Interface\\AddOns\\Plater\\images\\option_text", Value="102060"},
  {Type=4, Name="Require Range", Key="requireRange", Desc="Only glow when the caster is in range of the interrupt.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=4, Name="Target/Focus Only", Key="onlyTargetFocus", Desc="Only glow casts from your target or focus.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
  {Type=5, Name="Look", Key="", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_label", Value="Look"},
  {Type=1, Name="Ready Glow Colour", Key="glowColor", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={0.2, 1, 0.75, 1}},
  {Type=2, Name="Glow Lines", Key="glowLines", Desc="Number of pixel-glow lines.", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=10, Min=4, Max=20, Fraction=false},
  {Type=2, Name="Glow Thickness", Key="glowThickness", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_number", Value=2, Min=1, Max=4, Fraction=false},
  {Type=4, Name="Tint While Interrupt On Cooldown", Key="tintOnCd", Desc="Recolour interruptible casts while your interrupts are on cooldown.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=true},
  {Type=1, Name="On-Cooldown Cast Colour", Key="cdColor", Desc="", Icon="Interface\\AddOns\\Plater\\images\\option_color", Value={0.62, 0.36, 0.12, 1}},
  {Type=4, Name="Flash Plate On Kickable Cast", Key="flash", Desc="Flash the nameplate border once when a kickable cast starts while an interrupt is ready.", Icon="Interface\\AddOns\\Plater\\images\\option_bool", Value=false},
}
M.hooks = {}
M.hooks["Initialization"] = [==[
function (modTable)
    local GLOW_KEY = "schizzleWarKick"

    function modTable.SpellId()
        return tonumber(modTable.config.kickSpell) or 6552
    end

    function modTable.BackupId()
        return tonumber(modTable.config.backupSpell)
    end

    function modTable.Known(spellId)
        if IsPlayerSpell and IsPlayerSpell(spellId) then return true end
        if IsSpellKnown and IsSpellKnown(spellId) then return true end
        return false
    end

    --seconds left on cooldown, ignoring the global cooldown
    function modTable.CdLeft(spellId)
        local start, duration
        if C_Spell and C_Spell.GetSpellCooldown then
            local info = C_Spell.GetSpellCooldown(spellId)
            if info then
                start, duration = info.startTime, info.duration
            end
        elseif GetSpellCooldown then
            start, duration = GetSpellCooldown(spellId)
        end
        if start and duration and start > 0 and duration > 1.5 then
            local left = start + duration - GetTime()
            if left > 0 then return left end
        end
        return 0
    end

    function modTable.InRange(spellId, unitId)
        local r
        if C_Spell and C_Spell.IsSpellInRange then
            r = C_Spell.IsSpellInRange(spellId, unitId)
        elseif IsSpellInRange and C_Spell and C_Spell.GetSpellName then
            local name = C_Spell.GetSpellName(spellId)
            if name then r = IsSpellInRange(name, unitId) end
        end
        if r == nil then return true end --unknown: don't block the glow
        return r == true or r == 1
    end

    local function stopGlow(castBar)
        if castBar.schizzleWarKickGlow then
            Plater.StopPixelGlow(castBar, GLOW_KEY)
            castBar.schizzleWarKickGlow = nil
        end
    end
    modTable.StopGlow = stopGlow

    --state: "ready", "cd", "none"
    function modTable.Evaluate(castBar, unitId, unitFrame, isStart)
        local cfg = modTable.config
        local state = "none"
        local active = (castBar.casting or castBar.channeling) and not castBar.interrupted
        if active and castBar.canInterrupt and unitId then
            local okUnit = true
            if cfg.onlyTargetFocus then
                okUnit = UnitIsUnit(unitId, "target") or UnitIsUnit(unitId, "focus")
            end
            if okUnit then
                local anyKnown = false
                for _, spellId in ipairs({modTable.SpellId(), modTable.BackupId()}) do
                    if spellId and modTable.Known(spellId) then
                        anyKnown = true
                        if modTable.CdLeft(spellId) <= 0 and ((not cfg.requireRange) or modTable.InRange(spellId, unitId)) then
                            state = "ready"
                            break
                        end
                    end
                end
                if anyKnown and state ~= "ready" then
                    --known but nothing usable: on cooldown (or only out of range, which stays "none")
                    local main, backup = modTable.SpellId(), modTable.BackupId()
                    local mainCd = modTable.Known(main) and modTable.CdLeft(main) > 0
                    local backupCd = (not backup) or (not modTable.Known(backup)) or modTable.CdLeft(backup) > 0
                    if mainCd and backupCd then
                        state = "cd"
                    end
                end
            end
        end

        if state == castBar.schizzleWarKickState and not isStart then
            return
        end
        local previous = castBar.schizzleWarKickState
        castBar.schizzleWarKickState = state

        if state == "ready" then
            if not castBar.schizzleWarKickGlow then
                local c = cfg.glowColor
                Plater.StartPixelGlow(castBar, c, {
                    glowType = "pixel", color = c, N = cfg.glowLines or 10, frequency = 0.3,
                    th = cfg.glowThickness or 2, xOffset = 2, yOffset = 2, border = false, key = GLOW_KEY,
                }, GLOW_KEY)
                castBar.schizzleWarKickGlow = true
            end
            if isStart and cfg.flash then
                Plater.FlashNameplateBorder(unitFrame, 0.35)
            end
        else
            stopGlow(castBar)
        end

        if state == "cd" and cfg.tintOnCd then
            castBar.schizzleWarKickTinted = true
            Plater.SetCastBarColor(unitFrame, cfg.cdColor)
        elseif castBar.schizzleWarKickTinted then
            castBar.schizzleWarKickTinted = nil
            if active then
                Plater.SetCastBarColor(unitFrame) --back to the profile colour
            end
        end
    end
end
]==]
M.hooks["Cast Start"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    self.schizzleWarKickState = nil
    self.schizzleWarKickTinted = nil
    self.schizzleWarKickNext = GetTime() + 0.1
    modTable.Evaluate(self, unitId, unitFrame, true)
end
]==]
M.hooks["Cast Update"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    local now = GetTime()
    if now < (self.schizzleWarKickNext or 0) then
        return
    end
    self.schizzleWarKickNext = now + 0.1
    modTable.Evaluate(self, unitId, unitFrame, false)
end
]==]
M.hooks["Cast Stop"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    modTable.StopGlow(self)
    self.schizzleWarKickState = nil
    self.schizzleWarKickTinted = nil
end
]==]
M.hooks["Nameplate Removed"] = [==[
function (self, unitId, unitFrame, envTable, modTable)
    local castBar = unitFrame.castBar
    if castBar then
        modTable.StopGlow(castBar)
        castBar.schizzleWarKickState = nil
        castBar.schizzleWarKickTinted = nil
    end
end
]==]
return M
