-- TomTom waypoints and numbered pins on the world map and minimap.
-- QuestRoute by Jon Shaw (Schizzle).

local _, ns = ...

local routePins = {}
local routeKey
local activePlan
local arrowUID
local miniPool = {}
local worldPool = {}
local mapLinePool = {}
local miniLinePool = {}
local mapHooked = false

local function WorldOf(uiMap, x, y)
	if not uiMap or not x or not y or not C_Map or not C_Map.GetWorldPosFromMapPos then
		return nil
	end
	local ok, first, second = pcall(C_Map.GetWorldPosFromMapPos, uiMap, { x = x / 100, y = y / 100 })
	local pos = (type(first) == "table" and not ns.IsSecret(first.x) and first.x and first) or (type(second) == "table" and not ns.IsSecret(second.x) and second.x and second)
	if ok and pos and not ns.IsSecret(pos.x) and not ns.IsSecret(pos.y) then
		return pos.x, pos.y
	end
	return nil
end

local function RouteSignature(plan)
	local parts = {}
	local steps = plan and plan.steps or {}
	for i = 1, #steps do
		local step = steps[i]
		if step.x and step.y then
			parts[#parts + 1] = i .. ":" .. (step.uiMap or 0) .. ":" .. math.floor(step.x * 10) .. ":" .. math.floor(step.y * 10)
		end
	end
	return table.concat(parts, "|")
end

local function StepTitle(step, index)
	return index .. ". " .. (step.title or step.questName or "Step")
end

local function SameStep(a, b)
	if a == b then
		return true
	end
	if not a or not b then
		return false
	end
	return a.questId == b.questId and a.title == b.title and a.verb == b.verb and a.x == b.x and a.y == b.y
end

local function ClearTomTom()
	if TomTom and TomTom.RemoveWaypoint then
		for i = 1, #routePins do
			if routePins[i].uid then
				pcall(TomTom.RemoveWaypoint, TomTom, routePins[i].uid)
			end
		end
	end
	if arrowUID and TomTom and TomTom.RemoveWaypoint then
		pcall(TomTom.RemoveWaypoint, TomTom, arrowUID)
	end
	routePins = {}
	arrowUID = nil
	routeKey = nil
end

local function AddTomTom(step, index)
	if not TomTom or not step or not step.x or not step.y then
		return nil
	end
	local title = StepTitle(step, index)
	local uid
	if step.uiMap and TomTom.AddWaypoint then
		local ok, value = pcall(function()
			return TomTom:AddWaypoint(step.uiMap, step.x / 100, step.y / 100, {
				title = title,
				persistent = false,
				minimap = true,
				world = true,
				crazy = false,
				from = "QuestRoute",
				silent = true,
				cleardistance = 0,
			})
		end)
		if ok then
			uid = value
		end
	end
	if not uid and TomTom.AddZWaypoint and step.areaId then
		local ok, value = pcall(TomTom.AddZWaypoint, TomTom, 0, step.areaId, step.x, step.y, title, false, true, true, false)
		if ok then
			uid = value
		end
	end
	return uid
end

local function FocusArrow(step, announce)
	if not step then
		return
	end
	if not TomTom then
		if announce then
			ns:Print(ns.L.NO_TOMTOM)
		end
		return
	end
	if not step.x or not step.y then
		if announce then
			ns:Print(string.format(ns.L.NO_MAP_PIN_STEP, step.title or "That step"))
		end
		return
	end
	local pin, index
	for i = 1, #routePins do
		if SameStep(routePins[i].step, step) then
			pin = routePins[i]
			index = routePins[i].index
			break
		end
	end
	index = index or 1
	local uid = pin and pin.uid
	local title = StepTitle(step, index)
	if not uid then
		uid = AddTomTom(step, index)
		if uid then
			if pin then
				pin.uid = uid
			else
				arrowUID = uid
			end
		end
	end
	if uid and TomTom.SetCrazyArrow then
		pcall(TomTom.SetCrazyArrow, TomTom, uid, 10, title)
	end
	if uid and announce then
		ns:Print(string.format(ns.L.ARROW_SET, step.title or "the step"))
	elseif not uid and announce then
		ns:Print(ns.L.TOMTOM_REFUSED)
	end
end

local function PointAt(step, announce)
	FocusArrow(step, announce)
end

local function HidePool(pool)
	for i = 1, #pool do
		pool[i]:Hide()
	end
end

local function TakeMapPin(pool, parent)
	for i = 1, #pool do
		if pool[i].free then
			pool[i].free = false
			pool[i]:SetParent(parent)
			pool[i]:Show()
			return pool[i]
		end
	end
	local pin = CreateFrame("Button", nil, parent)
	pin:SetSize(18, 18)
	if pin.SetClipsChildren then
		pin:SetClipsChildren(false)
	end
	local ring = pin:CreateTexture(nil, "BACKGROUND")
	ring:SetTexture("Interface\\Buttons\\WHITE8X8")
	ring:SetPoint("TOPLEFT", -1, 1)
	ring:SetPoint("BOTTOMRIGHT", 1, -1)
	pin.ring = ring
	local plate = pin:CreateTexture(nil, "BORDER")
	plate:SetTexture("Interface\\Buttons\\WHITE8X8")
	plate:SetPoint("TOPLEFT", 1, -1)
	plate:SetPoint("BOTTOMRIGHT", -1, 1)
	pin.plate = plate
	local label = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("CENTER", 0, 0)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	pin.label = label
	pin:SetScript("OnEnter", function(self)
		if not self.tip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tip, 1, 0.82, 0)
		GameTooltip:Show()
	end)
	pin:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	pool[#pool + 1] = pin
	return pin
end

local function StylePin(pin, index, current)
	local text = tostring(index)
	local wide = string.len(text) > 1
	local width = wide and 28 or 18
	local height = 16
	pin:SetSize(width, height)
	pin.label:SetText(text)
	pin.label:SetWordWrap(false)
	pin.label:ClearAllPoints()
	pin.label:SetPoint("CENTER", pin, "CENTER", 0.5, 0)
	local face = GameFontHighlight and GameFontHighlight:GetFont()
	if face then
		pcall(pin.label.SetFont, pin.label, face, wide and 9 or 11, "OUTLINE")
	end
	if current then
		if pin.ring then
			pin.ring:SetVertexColor(1, 0.82, 0, 1)
		end
		pin.plate:SetVertexColor(0.72, 0.45, 0.2, 0.96)
		pin.label:SetTextColor(1, 0.98, 0.94)
	else
		if pin.ring then
			pin.ring:SetVertexColor(0.72, 0.45, 0.2, 1)
		end
		pin.plate:SetVertexColor(0.06, 0.06, 0.06, 0.94)
		pin.label:SetTextColor(1, 0.82, 0)
	end
end

local function NudgePins(placed)
	local order = {}
	for index, point in pairs(placed) do
		if type(index) == "number" and point.x then
			order[#order + 1] = index
		end
	end
	table.sort(order)
	for n = 2, #order do
		local point = placed[order[n]]
		for m = 1, n - 1 do
			local other = placed[order[m]]
			local dx = point.x - other.x
			local dy = point.y - other.y
			if dx * dx + dy * dy < 18 * 18 then
				local angle = n * 1.2
				point.x = other.x + math.cos(angle) * 20
				point.y = other.y + math.sin(angle) * 16
			end
		end
	end
end

local function TakeMapLine(pool)
	for i = 1, #pool do
		if pool[i].free then
			pool[i].free = false
			pool[i]:Show()
			return pool[i]
		end
	end
	local line = UIParent:CreateTexture(nil, "OVERLAY")
	line:SetTexture("Interface\\Buttons\\WHITE8X8")
	line:SetVertexColor(1, 0.82, 0, 0.85)
	pool[#pool + 1] = line
	return line
end

local function PlaceSegment(line, parent, anchor, x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	if length < 4 then
		line:Hide()
		line.free = true
		return
	end
	line:SetParent(parent)
	line:ClearAllPoints()
	line:SetSize(length, 2)
	line:SetPoint("CENTER", parent, anchor, (x1 + x2) / 2, (y1 + y2) / 2)
	if line.SetRotation then
		line:SetRotation(math.atan2(dy, dx))
	end
	line:Show()
end

local function ShownWorldMap()
	if not WorldMapFrame or not WorldMapFrame:IsShown() then
		return nil, nil
	end
	local mapID
	if WorldMapFrame.GetMapID then
		mapID = WorldMapFrame:GetMapID()
	elseif GetCurrentMapAreaID then
		mapID = GetCurrentMapAreaID()
	end
	local canvas
	if WorldMapFrame.GetCanvas then
		local ok, value = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
		if ok then
			canvas = value
		end
	end
	if not canvas and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
		canvas = WorldMapFrame.ScrollContainer.Child
	end
	if not canvas then
		canvas = WorldMapDetailFrame or WorldMapButton
	end
	return canvas, mapID
end

local function UpdateWorldPins(plan)
	for i = 1, #worldPool do
		worldPool[i].free = true
		worldPool[i]:Hide()
	end
	for i = 1, #mapLinePool do
		mapLinePool[i].free = true
		mapLinePool[i]:Hide()
	end
	local canvas, mapID = ShownWorldMap()
	if not canvas or not plan or not ns.Settings().showOnMap then
		return
	end
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if not width or width < 20 then
		return
	end
	local baseLevel = 1
	if type(canvas.GetFrameLevel) == "function" then
		baseLevel = canvas:GetFrameLevel() or 1
	end
	local placed = {}
	local steps = plan.steps or {}
	local shown = 0
	for i = 1, #steps do
		local step = steps[i]
		if step.x and step.y and step.uiMap and (not mapID or step.uiMap == mapID) and shown < 40 then
			shown = shown + 1
			local px = step.x / 100 * width
			local py = -step.y / 100 * height
			placed[i] = { x = px, y = py, step = step }
		end
	end
	NudgePins(placed)
	for i = 1, #steps do
		local spot = placed[i]
		if spot then
			local pin = TakeMapPin(worldPool, canvas)
			pin:SetFrameStrata("HIGH")
			pin:SetFrameLevel(baseLevel + 20 + i)
			StylePin(pin, i, i == 1)
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", canvas, "TOPLEFT", spot.x, spot.y)
			pin.tip = StepTitle(spot.step, i)
			local captured = spot.step
			pin:SetScript("OnClick", function()
				PointAt(captured, true)
			end)
		end
	end
	for i = 1, #steps - 1 do
		if placed[i] and placed[i + 1] then
			local line = TakeMapLine(mapLinePool)
			PlaceSegment(line, canvas, "TOPLEFT", placed[i].x, placed[i].y, placed[i + 1].x, placed[i + 1].y)
		end
	end
end

local function MinimapYards()
	local zoom = ns.Num(Minimap and Minimap.GetZoom and Minimap:GetZoom(), 0)
	local indoor = (IsInInstance and IsInInstance()) and true or false
	local outdoorRadius = { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 }
	local indoorRadius = { [0] = 300, 240, 180, 120, 80, 50 }
	local list = indoor and indoorRadius or outdoorRadius
	return list[zoom] or list[0] or 300
end

local function UpdateMinimapPins(plan)
	for i = 1, #miniPool do
		miniPool[i].free = true
		miniPool[i]:Hide()
	end
	if not Minimap or not plan or not ns.Settings().showOnMap then
		return
	end
	local player, playerMap = ns.PlayerPosition()
	if not player or not playerMap then
		return
	end
	local playerX, playerY = WorldOf(playerMap, player.x, player.y)
	if not playerX then
		return
	end
	local radiusYards = MinimapYards()
	local radiusPx = (Minimap:GetWidth() / 2) - 8
	if radiusPx < 20 then
		radiusPx = 60
	end
	local scale = radiusPx / radiusYards
	local facing = 0
	local rotate = false
	if GetCVar then
		local ok, value = pcall(GetCVar, "rotateMinimap")
		rotate = ok and not ns.IsSecret(value) and value == "1"
	end
	if rotate and GetPlayerFacing then
		local ok, facingValue = pcall(GetPlayerFacing)
		if ok and not ns.IsSecret(facingValue) and type(facingValue) == "number" then
			facing = facingValue
		end
	end
	local sinF = math.sin(facing)
	local cosF = math.cos(facing)
	for i = 1, #miniLinePool do
		miniLinePool[i].free = true
		miniLinePool[i]:Hide()
	end
	local placed = {}
	local steps = plan.steps or {}
	local shown = 0
	for i = 1, #steps do
		local step = steps[i]
		if step.x and step.y and step.uiMap and shown < 40 then
			local worldX, worldY = WorldOf(step.uiMap, step.x, step.y)
			if worldX then
				local dx = (worldX - playerX) * scale
				local dy = (worldY - playerY) * scale
				local spanX = worldX - playerX
				local spanY = worldY - playerY
				local yards = math.sqrt(spanX * spanX + spanY * spanY)
				if yards < 4000 then
					if rotate then
						dx, dy = dx * cosF - dy * sinF, dx * sinF + dy * cosF
					end
					local dist = math.sqrt(dx * dx + dy * dy)
					local inside = dist <= radiusPx
					if dist > radiusPx and dist > 0 then
						dx = dx / dist * radiusPx
						dy = dy / dist * radiusPx
					end
					shown = shown + 1
					local pin = TakeMapPin(miniPool, Minimap)
					pin:SetFrameStrata("MEDIUM")
					pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
					StylePin(pin, i, i == 1)
					pin:ClearAllPoints()
					pin:SetPoint("CENTER", Minimap, "CENTER", dx, dy)
					pin.tip = StepTitle(step, i)
					local captured = step
					pin:SetScript("OnClick", function()
						PointAt(captured, true)
					end)
					if inside then
						placed[i] = { x = dx, y = dy }
					end
				end
			end
		end
	end
	for i = 1, #steps - 1 do
		if placed[i] and placed[i + 1] then
			local line = TakeMapLine(miniLinePool)
			PlaceSegment(line, Minimap, "CENTER", placed[i].x, placed[i].y, placed[i + 1].x, placed[i + 1].y)
		end
	end
end

local function EnsureMapHooks()
	if mapHooked or not WorldMapFrame or not WorldMapFrame.HookScript then
		return
	end
	mapHooked = true
	WorldMapFrame:HookScript("OnShow", function()
		if activePlan then
			UpdateWorldPins(activePlan)
		end
	end)
	WorldMapFrame:HookScript("OnHide", function()
		HidePool(worldPool)
		HidePool(mapLinePool)
	end)
end

local mapTicker = CreateFrame("Frame")
local mapWait = 0
local pinError
mapTicker:SetScript("OnUpdate", function(_, elapsed)
	if not activePlan then
		return
	end
	mapWait = mapWait + (elapsed or 0)
	if mapWait < 0.2 then
		return
	end
	mapWait = 0
	local ok, err = pcall(function()
		EnsureMapHooks()
		if not ns.Settings().showOnMap then
			return
		end
		if ns.InCombat() or ns.Restriction("Map") then
			return
		end
		UpdateMinimapPins(activePlan)
		if WorldMapFrame and WorldMapFrame:IsShown() then
			UpdateWorldPins(activePlan)
		end
	end)
	if not ok and err ~= pinError then
		pinError = err
		ns:Print(string.format(ns.L.MAP_PINS_STOPPED, tostring(err)))
	end
end)

local function SyncRoute(plan, focusStep, announce)
	activePlan = plan
	local db = ns.Settings()
	local key = RouteSignature(plan)
	local changed = key ~= routeKey
	if not db.useTomTom or not TomTom then
		if #routePins > 0 or routeKey then
			ClearTomTom()
		end
	elseif changed then
		ClearTomTom()
		local steps = plan and plan.steps or {}
		for i = 1, #steps do
			local step = steps[i]
			if step.x and step.y then
				routePins[#routePins + 1] = {
					step = step,
					index = i,
					uid = AddTomTom(step, i),
				}
			end
		end
		routeKey = key
	end
	if db.useTomTom and TomTom then
		local aim = focusStep
		if not aim and changed and plan and plan.steps then
			aim = plan.steps[1]
		end
		if aim then
			FocusArrow(aim, announce and true or false)
		end
	elseif focusStep then
		FocusArrow(focusStep, announce and true or false)
	end
	if not db.showOnMap then
		HidePool(miniPool)
		HidePool(worldPool)
		HidePool(mapLinePool)
		HidePool(miniLinePool)
		return
	end
	UpdateMinimapPins(plan)
	UpdateWorldPins(plan)
end

ns.FocusArrow = FocusArrow
ns.PointAt = PointAt
ns.SyncRoute = SyncRoute
ns.EnsureMapHooks = EnsureMapHooks

function ns.InvalidateRoute()
	routeKey = nil
end
