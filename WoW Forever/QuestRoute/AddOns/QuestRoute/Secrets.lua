local _, ns = ...

-- Secret values and addon restrictions on the Forever client. A secret may be stored,
-- passed on, or given to a widget that accepts it. It must not be used in arithmetic,
-- comparisons, the length operator, a table key, or a boolean test.
-- The approach follows RutaMisiones (Fastest Quest Route) by Nico, MIT.

local issecretvalue = issecretvalue or function()
	return false
end

ns.IsSecret = issecretvalue

function ns.Readable(value, fallback)
	if issecretvalue(value) then
		return fallback
	end
	return value
end

function ns.Num(value, fallback)
	if value == nil or issecretvalue(value) then
		return fallback
	end
	local number = tonumber(value)
	if number == nil then
		return fallback
	end
	return number
end

function ns.Text(value, fallback)
	if value == nil or issecretvalue(value) then
		return fallback
	end
	if type(value) ~= "string" or value == "" then
		return fallback
	end
	return value
end

-- A secret boolean is not a yes. Callers can branch on the result.
function ns.Flag(value)
	if value == nil or issecretvalue(value) then
		return false
	end
	return value and true or false
end

function ns.IsRestrictionActive(restriction)
	if not (C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive) or restriction == nil then
		return false
	end
	local ok, active = pcall(C_RestrictedActions.IsAddOnRestrictionActive, restriction)
	if not ok or issecretvalue(active) then
		return false
	end
	return active and true or false
end

function ns.InCombat()
	if not InCombatLockdown then
		return false
	end
	local ok, locked = pcall(InCombatLockdown)
	if not ok or issecretvalue(locked) then
		return false
	end
	return locked and true or false
end

function ns.Restriction(name)
	local types = Enum and Enum.AddOnRestrictionType
	local value = types and types[name]
	return ns.IsRestrictionActive(value)
end
