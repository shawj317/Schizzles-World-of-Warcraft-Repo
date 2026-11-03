-- Minimal JSON encoder/decoder (objects, arrays, strings, numbers, booleans).
local M = {}

local function isArray(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

local function encodeString(s)
  return '"' .. s:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" end
    return string.format("\\u%04x", c:byte())
  end) .. '"'
end

function M.encode(v)
  local t = type(v)
  if t == "table" then
    local parts = {}
    if isArray(v) and #v > 0 then
      for _, x in ipairs(v) do parts[#parts + 1] = M.encode(x) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do assert(type(k) == "string", "object keys must be strings"); keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do parts[#parts + 1] = encodeString(k) .. ":" .. M.encode(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then
    return encodeString(v)
  elseif t == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return string.format("%.14g", v)
  elseif t == "boolean" then
    return tostring(v)
  end
  error("can't encode " .. t)
end

function M.decode(s)
  local i = 1
  local function ws() i = s:find("[^ \t\r\n]", i) or #s + 1 end
  local value
  local function str()
    local out = {}
    i = i + 1
    while true do
      local c = s:sub(i, i)
      if c == "" then error("unterminated string") end
      if c == '"' then i = i + 1; return table.concat(out) end
      if c == "\\" then
        local e = s:sub(i + 1, i + 1)
        if e == "u" then out[#out + 1] = string.char(tonumber(s:sub(i + 2, i + 5), 16)); i = i + 6
        else out[#out + 1] = ({['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", t = "\t"})[e] or error("bad escape"); i = i + 2 end
      else out[#out + 1] = c; i = i + 1 end
    end
  end
  function value()
    ws()
    local c = s:sub(i, i)
    if c == "{" then
      local o = {}; i = i + 1; ws()
      if s:sub(i, i) == "}" then i = i + 1; return o end
      while true do
        ws(); if s:sub(i, i) ~= '"' then error("expected key at " .. i) end
        local k = str(); ws()
        if s:sub(i, i) ~= ":" then error("expected : at " .. i) end
        i = i + 1; o[k] = value(); ws()
        local d = s:sub(i, i); i = i + 1
        if d == "}" then return o elseif d ~= "," then error("expected , at " .. i) end
      end
    elseif c == "[" then
      local a = {}; i = i + 1; ws()
      if s:sub(i, i) == "]" then i = i + 1; return a end
      while true do
        a[#a + 1] = value(); ws()
        local d = s:sub(i, i); i = i + 1
        if d == "]" then return a elseif d ~= "," then error("expected , at " .. i) end
      end
    elseif c == '"' then return str()
    elseif s:sub(i, i + 3) == "true" then i = i + 4; return true
    elseif s:sub(i, i + 4) == "false" then i = i + 5; return false
    else
      local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
      if not num or num == "" then error("bad value at " .. i) end
      i = i + #num; return tonumber(num)
    end
  end
  local v = value(); ws()
  if i <= #s then error("trailing data at " .. i) end
  return v
end

return M
