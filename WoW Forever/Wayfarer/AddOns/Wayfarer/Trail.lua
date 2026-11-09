local _, ns = ...

-- Pure helpers for the ant trail and the texture pools. No client API.

local function Length(ax, ay, bx, by)
	local dx, dy = bx - ax, by - ay
	return math.sqrt(dx * dx + dy * dy)
end

-- Points are {x, y} in one coordinate space. `phase` moves the dots toward the
-- end of the path (phase 0 puts a dot on the start). The last point is left
-- empty so a dot does not sit under the arrival pin. If the path would need
-- more than maxCount dots, the gap widens so the cap still covers the path.
function ns.TrailSamples(points, spacing, phase, maxCount)
	if type(points) ~= "table" or #points < 2 then
		return {}
	end
	spacing = tonumber(spacing) or 16
	if spacing < 4 then
		spacing = 4
	end
	phase = tonumber(phase) or 0
	if phase < 0 then
		phase = 0
	end
	maxCount = math.floor(tonumber(maxCount) or 64)
	if maxCount < 1 then
		return {}
	end
	local segs = {}
	local total = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if type(a) == "table" and type(b) == "table" and a.x and b.x then
			local len = Length(a.x, a.y, b.x, b.y)
			if len >= 1 then
				segs[#segs + 1] = { a = a, b = b, len = len, start = total }
				total = total + len
			end
		end
	end
	if total < 4 or #segs == 0 then
		return {}
	end
	local count = math.floor(total / spacing)
	if count > maxCount then
		spacing = total / maxCount
	end
	phase = phase % spacing
	local function at(dist)
		for i = 1, #segs do
			local seg = segs[i]
			local endAt = seg.start + seg.len
			if dist <= endAt or i == #segs then
				local t = (dist - seg.start) / seg.len
				if t < 0 then
					t = 0
				elseif t > 1 then
					t = 1
				end
				return {
					x = seg.a.x + (seg.b.x - seg.a.x) * t,
					y = seg.a.y + (seg.b.y - seg.a.y) * t,
				}
			end
		end
	end
	local out = {}
	local dist = phase
	while dist < total - 0.5 and #out < maxCount do
		out[#out + 1] = at(dist)
		dist = dist + spacing
	end
	return out
end

function ns.ReleaseAll(pool)
	if type(pool) ~= "table" then
		return
	end
	for i = 1, #pool do
		pool[i].free = true
		if pool[i].Hide then
			pool[i]:Hide()
		end
	end
end

function ns.Claim(pool, create)
	for i = 1, #pool do
		if pool[i].free then
			pool[i].free = false
			if pool[i].Show then
				pool[i]:Show()
			end
			return pool[i]
		end
	end
	local item = create()
	item.free = false
	pool[#pool + 1] = item
	return item
end
