local _, ns = ...

-- Travel time between two world points: walk, or walk to a known flight master,
-- fly (FlightData.lua), and walk the rest. Boats and zeppelins link continents.
-- The measured flight seconds and the idea of this search come from RutaMisiones
-- (Fastest Quest Route) by Nico, MIT. This file is Wayfarer's own version of that
-- search, and it also names the hop so the route window can show it.
-- Pure Lua: the client supplies positions and which flight masters you know.

local Travel = {}
ns.Travel = Travel

-- Average wait plus the crossing. An estimate, not a measured flight.
Travel.TRANSPORT_SECONDS = 360

-- nodeID pairs from C_TaxiMap, beside the docks, by faction.
-- kind is "boat" or "zeppelin".
Travel.TRANSPORTS = {
	A = {
		{ 7, 26, "boat" }, -- Menethil Harbor to Auberdine
		{ 7, 32, "boat" }, -- Menethil Harbor to Theramore
		{ 19, 80, "boat" }, -- Booty Bay to Ratchet
	},
	H = {
		{ 23, 11, "zeppelin" }, -- Orgrimmar to Undercity
		{ 23, 20, "zeppelin" }, -- Orgrimmar to Grom'gol
		{ 11, 20, "zeppelin" }, -- Undercity to Grom'gol
		{ 18, 80, "boat" }, -- Booty Bay to Ratchet
	},
}

local function Walk(a, b, speed)
	if not a or not b or a.c ~= b.c or not a.x or not b.x then
		return nil
	end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy) / speed
end

local function Clock(seconds)
	local minutes = math.floor((seconds / 60) + 0.5)
	if minutes < 1 then
		minutes = 1
	end
	return "~" .. minutes .. "m"
end

function Travel.Label(mode, fromName, toName, seconds)
	local verb = "Fly"
	if mode == "boat" then
		verb = "Boat"
	elseif mode == "zeppelin" then
		verb = "Zeppelin"
	elseif mode == "walk" then
		verb = "Run"
	end
	local clock = Clock(seconds or 0)
	if fromName and toName and fromName ~= "" and toName ~= "" then
		return verb .. " " .. fromName .. " → " .. toName .. ", " .. clock
	end
	return verb .. ", " .. clock
end

local function AddEdge(edges, a, b, seconds, mode)
	edges[a] = edges[a] or {}
	local prev = edges[a][b]
	if not prev or seconds < prev.seconds then
		edges[a][b] = { seconds = seconds, mode = mode or "fly" }
	end
end

function Travel.Graph(times, transports)
	local edges = {}
	for from, list in pairs(times or {}) do
		for to, seconds in pairs(list) do
			AddEdge(edges, from, to, seconds, "fly")
			AddEdge(edges, to, from, seconds, "fly")
		end
	end
	for i = 1, #(transports or {}) do
		local pair = transports[i]
		AddEdge(edges, pair[1], pair[2], Travel.TRANSPORT_SECONDS, pair[3] or "boat")
		AddEdge(edges, pair[2], pair[1], Travel.TRANSPORT_SECONDS, pair[3] or "boat")
	end
	return edges
end

-- Returns seconds, or nil when the points are on different continents and no
-- known flight or boat connects them. The second return is a table:
--   flew, mode, fromName, toName, label
function Travel.Seconds(from, to, opts)
	opts = opts or {}
	local speed = tonumber(opts.speed) or 7
	if speed < 1 then
		speed = 7
	end
	local best = Walk(from, to, speed)
	local bestHop = nil
	local nodes = opts.nodes or {}
	local edges = Travel.Graph(opts.times, opts.transports)
	local dist, done, hop = {}, {}, {}
	for id, node in pairs(nodes) do
		dist[id] = Walk(from, node, speed)
	end
	while true do
		local current, low
		for id, d in pairs(dist) do
			if not done[id] and (not low or d < low) then
				current, low = id, d
			end
		end
		if not current then
			break
		end
		done[current] = true
		for toId, edge in pairs(edges[current] or {}) do
			if nodes[toId] and not done[toId] then
				local candidate = low + edge.seconds
				if not dist[toId] or candidate < dist[toId] then
					dist[toId] = candidate
					local fromName = nodes[current] and nodes[current].name
					local toName = nodes[toId] and nodes[toId].name
					hop[toId] = {
						mode = edge.mode,
						fromName = fromName,
						toName = toName,
						seconds = edge.seconds,
					}
				end
			end
		end
	end
	local flew = false
	for id, d in pairs(dist) do
		local tail = Walk(nodes[id], to, speed)
		if tail and (not best or d + tail < best) then
			best = d + tail
			bestHop = hop[id]
			flew = bestHop ~= nil
		end
	end
	if not best then
		return nil
	end
	local info = { flew = flew, seconds = best, mode = "walk" }
	if flew and bestHop then
		info.mode = bestHop.mode or "fly"
		info.fromName = bestHop.fromName
		info.toName = bestHop.toName
		info.label = Travel.Label(info.mode, info.fromName, info.toName, best)
	end
	return best, info
end
