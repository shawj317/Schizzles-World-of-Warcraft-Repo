-- TomTom waypoints and numbered pins on the world map and minimap.
-- QuestRoute by Jon Shaw (Schizzle).

local _, ns = ...

local routePins = {}
local routeKey
local activePlan
local arrowUID
local miniPool = {}
local worldPool = {}
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
				from = "Wayfarer",
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

local worldDots = {}
local miniDots = {}
local trailDistance = 0
local TEX = "Interface\\AddOns\\Wayfarer\\Textures\\"

local function HidePool(pool)
	ns.ReleaseAll(pool)
end

local function Tex(parent, layer, name, point, x, y)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetTexture(TEX .. name)
	texture:SetPoint("CENTER", parent, point or "CENTER", x or 0, y or 0)
	return texture
end

local function MakePin(parent)
	local pin = CreateFrame("Button", nil, parent)
	pin:SetSize(20, 20)
	if pin.SetClipsChildren then
		pin:SetClipsChildren(false)
	end
	pin.shadow = Tex(pin, "BACKGROUND", "disc", "CENTER", 1, -2)
	pin.glow = Tex(pin, "BACKGROUND", "glow", "CENTER", 0, 0)
	pin.ring = Tex(pin, "BORDER", "ring", "CENTER", 0, 0)
	pin.disc = Tex(pin, "ARTWORK", "disc", "CENTER", 0, 0)
	local label = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("CENTER", 0.5, 0)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	pin.label = label
	pin:SetScript("OnEnter", function(self)
		if not self.tip or not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tip, 1, 0.82, 0)
		GameTooltip:Show()
	end)
	pin:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	return pin
end

local function TakeMapPin(pool, parent)
	local pin = ns.Claim(pool, function()
		return MakePin(parent)
	end)
	pin:SetParent(parent)
	pin:Show()
	return pin
end

local function PinDisc(verb)
	if verb == "pick up" then
		return 1, 0.82, 0
	end
	if verb == "turn in" then
		return 1, 0.47, 0
	end
	return 0.72, 0.45, 0.2
end

local function StylePin(pin, index, step, current)
	local db = ns.Settings()
	local size = db.pinSize or 20
	local text = tostring(index)
	local wide = string.len(text) > 1
	pin:SetSize(size, size)
	local function fit(texture, scale, dx, dy)
		texture:SetSize(size * scale, size * scale)
		texture:ClearAllPoints()
		texture:SetPoint("CENTER", pin, "CENTER", dx or 0, dy or 0)
	end
	fit(pin.shadow, 0.92, 1, -2)
	pin.shadow:SetVertexColor(0, 0, 0, 0.45)
	fit(pin.glow, 1.55, 0, 0)
	fit(pin.ring, 1, 0, 0)
	fit(pin.disc, 0.72, 0, 0)
	local dr, dg, dbc = PinDisc(step and step.verb)
	pin.disc:SetVertexColor(dr, dg, dbc, 0.96)
	if current then
		local ar, ag, ab = 1, 0.82, 0
		if ns.ResolveTheme then
			local theme = ns.ResolveTheme(ns.Settings().theme, ns.PlayerClassColor and ns.PlayerClassColor() or nil)
			ar, ag, ab = theme.accent[1], theme.accent[2], theme.accent[3]
		end
		pin.ring:SetVertexColor(ar, ag, ab, 1)
		pin.glow:SetVertexColor(ar, ag, ab, 0.55)
		pin.glow:Show()
	else
		local rr, rg, rb = 0.93, 0.88, 0.78
		if ns.ResolveTheme then
			local theme = ns.ResolveTheme(ns.Settings().theme, ns.PlayerClassColor and ns.PlayerClassColor() or nil)
			rr, rg, rb = theme.pinRing[1], theme.pinRing[2], theme.pinRing[3]
		end
		pin.ring:SetVertexColor(rr, rg, rb, 0.95)
		pin.glow:Hide()
	end
	pin.label:SetText(text)
	local face = GameFontHighlight and GameFontHighlight:GetFont()
	local pixels = wide and math.max(8, size * 0.38) or math.max(9, size * 0.46)
	if face then
		pcall(pin.label.SetFont, pin.label, face, pixels, "OUTLINE")
	end
	pin.label:SetTextColor(1, 0.98, 0.94)
end

local function NudgePins(placed)
	local gap = (ns.Settings().pinSize or 20) + 4
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
			if dx * dx + dy * dy < gap * gap then
				local angle = n * 1.2
				point.x = other.x + math.cos(angle) * (gap + 2)
				point.y = other.y + math.sin(angle) * (gap + 2)
			end
		end
	end
end

local function MakeDot(parent)
	local dot = parent:CreateTexture(nil, "ARTWORK")
	dot:SetTexture(TEX .. "dot")
	dot:SetSize(7, 7)
	return dot
end

local function TakeDot(pool, parent)
	local dot = ns.Claim(pool, function()
		return MakeDot(parent)
	end)
	dot:SetParent(parent)
	dot:Show()
	return dot
end

local function Polylines(steps, placed, origin)
	local groups, current = {}, {}
	local function flush()
		if #current >= 2 then
			groups[#groups + 1] = current
		end
		current = {}
	end
	local seen = false
	if origin then
		current[1] = origin
	end
	for i = 1, #steps do
		local spot = placed[i]
		if spot then
			current[#current + 1] = { x = spot.x, y = spot.y }
			seen = true
		elseif origin and not seen then
			current = {}
		else
			flush()
		end
	end
	flush()
	return groups
end

local function PaintTrail(pool, parent, anchor, groups, spacing, cap)
	local db = ns.Settings()
	local phase = db.trailAnimated and trailDistance or 0
	local tr, tg, tb = db.trailR, db.trailG, db.trailB
	if not db.trailCustom and ns.ResolveTheme then
		local trail = ns.ResolveTheme(db.theme, ns.PlayerClassColor and ns.PlayerClassColor() or nil).trail
		tr, tg, tb = trail[1], trail[2], trail[3]
	end
	local budget = cap
	for g = 1, #groups do
		if budget < 1 then
			break
		end
		local samples = ns.TrailSamples(groups[g], spacing, phase, budget)
		for i = 1, #samples do
			local dot = TakeDot(pool, parent)
			dot:SetSize(7, 7)
			dot:SetVertexColor(tr, tg, tb, db.trailAlpha)
			dot:ClearAllPoints()
			dot:SetPoint("CENTER", parent, anchor, samples[i].x, samples[i].y)
		end
		budget = budget - #samples
	end
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
	HidePool(worldPool)
	HidePool(worldDots)
	local canvas, mapID = ShownWorldMap()
	local db = ns.Settings()
	if not canvas or not plan or (not db.showOnMap and not db.showTrail) then
		return
	end
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if not width or width < 20 or ns.IsSecret(width) then
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
	if db.showOnMap then
		for i = 1, #steps do
			local spot = placed[i]
			if spot then
				local pin = TakeMapPin(worldPool, canvas)
				pin:SetFrameStrata("HIGH")
				pin:SetFrameLevel(baseLevel + 20 + i)
				StylePin(pin, i, spot.step, i == 1)
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", canvas, "TOPLEFT", spot.x, spot.y)
				pin.tip = StepTitle(spot.step, i)
				local captured = spot.step
				pin:SetScript("OnClick", function()
					PointAt(captured, true)
				end)
			end
		end
	end
	if db.showTrail then
		local origin
		local player, playerMap = ns.PlayerPosition()
		if player and playerMap and (not mapID or playerMap == mapID) then
			origin = { x = player.x / 100 * width, y = -player.y / 100 * height }
		end
		PaintTrail(worldDots, canvas, "TOPLEFT", Polylines(steps, placed, origin), 18, 64)
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
	HidePool(miniPool)
	HidePool(miniDots)
	local db = ns.Settings()
	if not Minimap or not plan or (not db.showOnMap and not db.showTrail) then
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
					if db.showOnMap then
						local drawX, drawY = dx, dy
						if dist > radiusPx and dist > 0 then
							drawX = dx / dist * radiusPx
							drawY = dy / dist * radiusPx
						end
						shown = shown + 1
						local pin = TakeMapPin(miniPool, Minimap)
						pin:SetFrameStrata("MEDIUM")
						pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
						StylePin(pin, i, step, i == 1)
						pin:ClearAllPoints()
						pin:SetPoint("CENTER", Minimap, "CENTER", drawX, drawY)
						pin.tip = StepTitle(step, i)
						local captured = step
						pin:SetScript("OnClick", function()
							PointAt(captured, true)
						end)
					end
					if inside then
						placed[i] = { x = dx, y = dy }
					end
				end
			end
		end
	end
	if db.showTrail then
		PaintTrail(miniDots, Minimap, "CENTER", Polylines(steps, placed, { x = 0, y = 0 }), 12, 28)
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
		HidePool(worldDots)
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
	local db = ns.Settings()
	local waitFor = (db.showTrail and db.trailAnimated) and 0.05 or 0.2
	if mapWait < waitFor then
		return
	end
	local step = mapWait
	mapWait = 0
	if db.showTrail and db.trailAnimated and not ns.InCombat() then
		trailDistance = trailDistance + 42 * step
	end
	local ok, err = pcall(function()
		EnsureMapHooks()
		if not db.showOnMap and not db.showTrail then
			HidePool(miniPool)
			HidePool(worldPool)
			HidePool(miniDots)
			HidePool(worldDots)
			return
		end
		if ns.InCombat() or ns.Restriction("Map") then
			return
		end
		UpdateMinimapPins(activePlan)
		if WorldMapFrame and WorldMapFrame:IsShown() then
			UpdateWorldPins(activePlan)
		else
			HidePool(worldPool)
			HidePool(worldDots)
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
	if not db.showOnMap and not db.showTrail then
		HidePool(miniPool)
		HidePool(worldPool)
		HidePool(miniDots)
		HidePool(worldDots)
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
