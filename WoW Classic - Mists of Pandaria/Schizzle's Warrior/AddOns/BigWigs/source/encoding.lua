-- A Lua 5.1 stand-in for the game's C_EncodingUtil, used only by build.lua and verify.lua.
-- CBOR (RFC 8949) the way the game writes it: Lua strings as CBOR byte strings, whole numbers
-- as integers, other numbers as 64-bit floats, tables with keys 1..n as arrays, others as maps.
-- Deflate comes from LibDeflate (the copy BetterBlizzPlates and Plater ship), Base64 is RFC 4648.
local M = {}

local LibDeflate
function M.init(libDeflatePath)
	local saved = LibStub
	LibStub = nil -- load LibDeflate as a plain module
	LibDeflate = assert(loadfile(libDeflatePath))()
	LibStub = saved
	assert(type(LibDeflate) == "table" and LibDeflate.CompressDeflate, "LibDeflate did not load")
end

-- CBOR encode --------------------------------------------------------------------------------
local char, byte, floor = string.char, string.byte, math.floor

local function head(major, n)
	local m = major * 32
	if n < 24 then return char(m + n)
	elseif n < 256 then return char(m + 24, n)
	elseif n < 65536 then return char(m + 25, floor(n / 256), n % 256)
	elseif n < 4294967296 then
		return char(m + 26, floor(n / 16777216) % 256, floor(n / 65536) % 256, floor(n / 256) % 256, n % 256)
	end
	local hi, lo = floor(n / 4294967296), n % 4294967296
	return char(m + 27, floor(hi / 16777216) % 256, floor(hi / 65536) % 256, floor(hi / 256) % 256, hi % 256,
		floor(lo / 16777216) % 256, floor(lo / 65536) % 256, floor(lo / 256) % 256, lo % 256)
end

local function float64(x)
	local sign = 0
	if x < 0 or (x == 0 and 1 / x < 0) then sign = 1; x = -x end
	local m, e = math.frexp(x) -- x = m * 2^e, 0.5 <= m < 1
	m = m * 2 - 1; e = e - 1 + 1023
	local mant = m * 2 ^ 52
	local hi = sign * 2147483648 + e * 1048576 + floor(mant / 4294967296)
	local lo = mant % 4294967296
	local b = {}
	for i = 3, 0, -1 do b[#b + 1] = floor(hi / 256 ^ i) % 256 end
	for i = 3, 0, -1 do b[#b + 1] = floor(lo / 256 ^ i) % 256 end
	return char(0xfb, unpack(b))
end

local function isArray(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	for i = 1, n do if t[i] == nil then return false end end
	return n > 0, n
end

local function encode(v, out)
	local tv = type(v)
	if tv == "string" then
		out[#out + 1] = head(2, #v) .. v
	elseif tv == "number" then
		if v == floor(v) and v >= -2 ^ 53 and v <= 2 ^ 53 then
			out[#out + 1] = v >= 0 and head(0, v) or head(1, -1 - v)
		else
			out[#out + 1] = float64(v)
		end
	elseif tv == "boolean" then
		out[#out + 1] = char(v and 0xf5 or 0xf4)
	elseif tv == "table" then
		local arr, n = isArray(v)
		if arr then
			out[#out + 1] = head(4, n)
			for i = 1, n do encode(v[i], out) end
		else
			local keys = {}
			for k in pairs(v) do keys[#keys + 1] = k end
			table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
			out[#out + 1] = head(5, #keys)
			for _, k in ipairs(keys) do encode(k, out); encode(v[k], out) end
		end
	else
		error("can't encode " .. tv)
	end
end

-- CBOR decode --------------------------------------------------------------------------------
local function decode(s, pos)
	local ib = byte(s, pos); pos = pos + 1
	local major, info = floor(ib / 32), ib % 32
	local n
	if info < 24 then n = info
	elseif info <= 27 then
		local len = 2 ^ (info - 24)
		n = 0
		for i = 0, len - 1 do n = n * 256 + byte(s, pos + i) end
		if major == 7 then
			if info == 27 then
				local b1, b2 = byte(s, pos), byte(s, pos + 1)
				local sign = b1 >= 128 and -1 or 1
				local e = (b1 % 128) * 16 + floor(b2 / 16)
				local mant = 0
				mant = (b2 % 16)
				for i = 2, 7 do mant = mant * 256 + byte(s, pos + i) end
				pos = pos + 8
				if e == 0 then return sign * mant * 2 ^ -1074, pos end
				return sign * (1 + mant / 2 ^ 52) * 2 ^ (e - 1023), pos
			elseif info == 26 then
				local b1, b2 = byte(s, pos), byte(s, pos + 1)
				local sign = b1 >= 128 and -1 or 1
				local e = (b1 % 128) * 2 + floor(b2 / 128)
				local mant = ((b2 % 128) * 256 + byte(s, pos + 2)) * 256 + byte(s, pos + 3)
				pos = pos + 4
				return sign * (1 + mant / 2 ^ 23) * 2 ^ (e - 127), pos
			end
			error("unsupported float width")
		end
		pos = pos + len
	else
		error("indefinite lengths are not used by the game")
	end
	if major == 0 then return n, pos
	elseif major == 1 then return -1 - n, pos
	elseif major == 2 or major == 3 then return s:sub(pos, pos + n - 1), pos + n
	elseif major == 4 then
		local t = {}
		for i = 1, n do t[i], pos = decode(s, pos) end
		return t, pos
	elseif major == 5 then
		local t = {}
		for _ = 1, n do
			local k
			k, pos = decode(s, pos)
			t[k], pos = decode(s, pos)
		end
		return t, pos
	elseif major == 7 then
		if n == 20 then return false, pos elseif n == 21 then return true, pos elseif n == 22 then return nil, pos end
	end
	error("unsupported CBOR item " .. ib)
end

-- Base64 -------------------------------------------------------------------------------------
local B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(s)
	local out = {}
	for i = 1, #s, 3 do
		local a, b, c = byte(s, i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local q = { floor(n / 262144) % 64, floor(n / 4096) % 64, floor(n / 64) % 64, n % 64 }
		out[#out + 1] = B:sub(q[1] + 1, q[1] + 1) .. B:sub(q[2] + 1, q[2] + 1)
			.. (b and B:sub(q[3] + 1, q[3] + 1) or "=") .. (c and B:sub(q[4] + 1, q[4] + 1) or "=")
	end
	return table.concat(out)
end
local rev = {}
for i = 1, 64 do rev[B:sub(i, i)] = i - 1 end
local function b64dec(s)
	if s:find("[^%w%+/=]") then return nil end
	local out = {}
	for i = 1, #s, 4 do
		local c = { s:byte(i, i + 3) }
		local v = {}
		for j = 1, 4 do v[j] = c[j] and rev[string.char(c[j])] end
		local n = (v[1] or 0) * 262144 + (v[2] or 0) * 4096 + (v[3] or 0) * 64 + (v[4] or 0)
		out[#out + 1] = char(floor(n / 65536) % 256)
		if v[3] then out[#out + 1] = char(floor(n / 256) % 256) end
		if v[4] then out[#out + 1] = char(n % 256) end
	end
	return table.concat(out)
end

M.C_EncodingUtil = {
	SerializeCBOR = function(v) local out = {}; encode(v, out); return table.concat(out) end,
	DeserializeCBOR = function(s) local ok, v = pcall(decode, s, 1); return ok and v or nil end,
	CompressString = function(s, method) assert(method == 0); return LibDeflate:CompressDeflate(s, { level = 9 }) end,
	DecompressString = function(s, method) assert(method == 0); return LibDeflate:DecompressDeflate(s) end,
	EncodeBase64 = b64enc,
	DecodeBase64 = b64dec,
}
return M
