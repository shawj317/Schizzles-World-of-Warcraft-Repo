-- Load every addon file the way the TOC does, with a client that rejects
-- unknown events. Slash commands must exist even if a later RegisterEvent throws.
local root = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("tools[\\/]test_load%.lua$", "")
local addon = root .. "AddOns/SkillLedger/"

hash_SlashCmdList = {}
SlashCmdList = {}
local frames = {}
function CreateFrame()
  local frame = { events = {} }
  function frame:SetScript(_, fn) self.script = fn end
  function frame:RegisterEvent(name)
    if name == "AUCTION_ITEM_LIST_UPDATE" then
      error("unknown event " .. name)
    end
    self.events[name] = true
  end
  function frame:SetSize() end
  function frame:SetFrameStrata() end
  function frame:SetClampedToScreen() end
  function frame:SetMovable() end
  function frame:EnableMouse() end
  function frame:RegisterForDrag() end
  function frame:EnableKeyboard() end
  function frame:SetPropagateKeyboardInput() end
  function frame:SetPoint() end
  function frame:Show() self.shown = true end
  function frame:Hide() self.shown = false end
  function frame:IsShown() return self.shown end
  function frame:CreateFontString()
    local fs = {}
    function fs:SetFont() end
    function fs:SetTextColor() end
    function fs:SetText() end
    function fs:SetPoint() end
    function fs:SetJustifyH() end
    function fs:SetJustifyV() end
    function fs:SetWidth() end
    function fs:GetStringHeight() return 10 end
    function fs:SetHeight() end
    function fs:GetParent() return frame end
    return fs
  end
  function frame:CreateTexture()
    local tex = {}
    function tex:SetAllPoints() end
    function tex:SetPoint() end
    function tex:SetColorTexture() end
    function tex:SetTexture() end
    function tex:SetVertexColor() end
    return tex
  end
  frames[#frames + 1] = frame
  return frame
end

local files = { "Init.lua", "Data.lua", "Plan.lua", "Core.lua", "Scan.lua", "AH.lua", "UI.lua" }
for i = 1, #files do
  local chunk, err = loadfile(addon .. files[i])
  if not chunk then
    io.stderr:write(files[i] .. " failed to compile: " .. tostring(err) .. "\n")
    os.exit(1)
  end
  local ok, runErr = pcall(chunk)
  if not ok then
    io.stderr:write(files[i] .. " failed to run: " .. tostring(runErr) .. "\n")
    os.exit(1)
  end
end

assert(SlashCmdList.SKILLLEDGER, "slash handler missing")
assert(SLASH_SKILLLEDGER1 == "/skillledger", SLASH_SKILLLEDGER1)
assert(SLASH_SKILLLEDGER2 == "/sl", SLASH_SKILLLEDGER2)
assert(hash_SlashCmdList["/SKILLLEDGER"] == "SKILLLEDGER")
assert(hash_SlashCmdList["/SL"] == "SKILLLEDGER")
assert(SkillLedger.ready, "ready flag missing")
assert(SkillLedger.EnsureAHTab, "auction tab missing")
assert(not SkillLedger.AnchorScanButton, "old overlapping button is still defined")
SlashCmdList.SKILLLEDGER("help")
print("load test passed")
