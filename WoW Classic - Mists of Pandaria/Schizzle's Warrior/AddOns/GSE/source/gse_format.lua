-- Our own reader/writer for GSE's "!GSE3!" import strings (no GSE code is copied; GSE is All Rights Reserved).
-- Format, read from GSE's Serialisation.lua and checked by decoding real exports:
--   "!GSE3!" .. base64(deflate(cbor(table)))
-- matching the WoW client's C_EncodingUtil defaults: standard Base64 with padding, raw Deflate, and CBOR where every
-- Lua string is a byte string (major type 2), a table 1..n is an array, an empty table is an empty array and any
-- other table is a map (integer keys stay integers).
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local M = {}

local function head(major, n)
  local m = major * 32
  if n < 24 then return string.char(m + n)
  elseif n < 256 then return string.char(m + 24, n)
  elseif n < 65536 then return string.char(m + 25, math.floor(n / 256), n % 256)
  else
    return string.char(m + 26, math.floor(n / 16777216) % 256, math.floor(n / 65536) % 256,
      math.floor(n / 256) % 256, n % 256)
  end
end

local function isArray(t)
  local n = #t
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count == n
end

local function keyOrder(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return ta == "number" end
  return a < b
end

local function enc(v, out)
  local t = type(v)
  if t == "string" then
    out[#out + 1] = head(2, #v); out[#out + 1] = v
  elseif t == "boolean" then
    out[#out + 1] = v and "\245" or "\244"
  elseif t == "number" then
    assert(v == math.floor(v), "only integers are used in GSE sequences")
    if v >= 0 then out[#out + 1] = head(0, v) else out[#out + 1] = head(1, -1 - v) end
  elseif t == "table" then
    if isArray(v) then
      out[#out + 1] = head(4, #v)
      for i = 1, #v do enc(v[i], out) end
    else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, keyOrder)
      out[#out + 1] = head(5, #keys)
      for _, k in ipairs(keys) do enc(k, out); enc(v[k], out) end
    end
  else
    error("can't encode " .. t)
  end
end

function M.cbor(v) local out = {}; enc(v, out); return table.concat(out) end

-- Decoder (used by verify.lua), covering what the client writes for GSE data.
function M.uncbor(s)
  local pos = 1
  local function byte() local b = s:byte(pos); pos = pos + 1; return b end
  local function arg(info)
    if info < 24 then return info end
    local len = ({[24] = 1, [25] = 2, [26] = 4, [27] = 8})[info]
    assert(len, "bad CBOR length")
    local n = 0
    for _ = 1, len do n = n * 256 + byte() end
    return n
  end
  local dec
  function dec()
    local b = byte()
    local major, info = math.floor(b / 32), b % 32
    if major == 0 then return arg(info)
    elseif major == 1 then return -1 - arg(info)
    elseif major == 2 or major == 3 then
      local n = arg(info); local v = s:sub(pos, pos + n - 1); pos = pos + n; return v
    elseif major == 4 then
      local t = {}; for i = 1, arg(info) do t[i] = dec() end; return t
    elseif major == 5 then
      local t = {}
      for _ = 1, arg(info) do local k = dec(); t[k] = dec() end
      return t
    elseif major == 7 then
      if info == 20 then return false elseif info == 21 then return true elseif info == 22 then return nil end
    end
    error(("unsupported CBOR byte 0x%02x at %d"):format(b, pos - 1))
  end
  local v = dec()
  assert(pos == #s + 1, "trailing CBOR bytes")
  return v
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function M.b64(s)
  local out = {}
  for i = 1, #s, 3 do
    local a, b, c = s:byte(i, i + 2)
    local n = a * 65536 + (b or 0) * 256 + (c or 0)
    local q = {math.floor(n / 262144) % 64, math.floor(n / 4096) % 64, math.floor(n / 64) % 64, n % 64}
    out[#out + 1] = B64:sub(q[1] + 1, q[1] + 1) .. B64:sub(q[2] + 1, q[2] + 1)
      .. (b and B64:sub(q[3] + 1, q[3] + 1) or "=") .. (c and B64:sub(q[4] + 1, q[4] + 1) or "=")
  end
  return table.concat(out)
end

function M.unb64(s)
  local lut = {}
  for i = 1, 64 do lut[B64:byte(i)] = i - 1 end
  s = s:gsub("[^%w%+/]", "")
  local out = {}
  for i = 1, #s, 4 do
    local c = {s:byte(i, i + 3)}
    local n, k = 0, 0
    for j = 1, 4 do n = n * 64 + (c[j] and lut[c[j]] or 0); if c[j] then k = k + 1 end end
    local bytes = string.char(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
    out[#out + 1] = bytes:sub(1, k - 1)
  end
  return table.concat(out)
end

M.PREFIX = "!GSE3!"
function M.encode(t)
  return M.PREFIX .. M.b64(LibDeflate:CompressDeflate(M.cbor(t), {level = 9}))
end

function M.decode(str)
  assert(str:sub(1, 6) == M.PREFIX and str:sub(7, 7) ~= "+", "not a plain !GSE3! string")
  local raw = LibDeflate:DecompressDeflate(M.unb64(str:sub(7)))
  assert(raw, "deflate stream did not decompress")
  return M.uncbor(raw), raw
end

-- What a block's macro text becomes once its variable lines are filled in, the way GSE describes it: a line that
-- starts with "=" and calls GSE.V["NAME"]() is replaced by what that variable returns. Our own code, for checking.
function M.expand(macro, variables)
  local byName = {}
  for _, var in ipairs(variables or {}) do byName[var.name] = var.returns end
  local out = {}
  for line in (macro .. "\n"):gmatch("([^\n]*)\n") do
    local name = line:match('^=GSE%.V%["([%w_]+)"%]%(%)$')
    out[#out + 1] = name and assert(byName[name], "unknown variable " .. name) or line
  end
  return table.concat(out, "\n")
end

return M
