-- Loaded before the recipe data. Slash commands are registered here so a later
-- file can fail without taking /skillledger with it.

SkillLedger = SkillLedger or {}
local SL = SkillLedger

local function say(message)
  local text = "|cffe0b060SkillLedger|r " .. tostring(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  elseif print then
    print(text)
  end
end
SL.Say = say

function SL.PublishSlash()
  _G.SLASH_SKILLLEDGER1 = "/skillledger"
  _G.SLASH_SKILLLEDGER2 = "/sl"
  if type(SlashCmdList) ~= "table" then
    SlashCmdList = {}
  end
  SlashCmdList.SKILLLEDGER = function(message)
    if type(SL.HandleSlash) == "function" then
      local ok, err = pcall(SL.HandleSlash, message)
      if not ok then say("command error: " .. tostring(err)) end
      return
    end
    say("did not finish loading. Check the error window, then /reload.")
  end
  if type(hash_SlashCmdList) == "table" then
    hash_SlashCmdList["/SKILLLEDGER"] = "SKILLLEDGER"
    local taken = hash_SlashCmdList["/SL"]
    if not taken or taken == "SKILLLEDGER" then
      hash_SlashCmdList["/SL"] = "SKILLLEDGER"
    end
  end
end

SL.PublishSlash()

local boot = CreateFrame and CreateFrame("Frame") or nil
if boot and boot.SetScript and boot.RegisterEvent then
  boot:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_LOGIN" then return end
    if SL.PublishSlash then SL.PublishSlash() end
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if SL.PublishSlash then SL.PublishSlash() end
      end)
    end
    if SL.ready then
      say("loaded. Type /skillledger.")
    else
      say("did not finish loading. Type /skillledger after /reload if this stays on screen.")
    end
  end)
  pcall(boot.RegisterEvent, boot, "PLAYER_LOGIN")
end
