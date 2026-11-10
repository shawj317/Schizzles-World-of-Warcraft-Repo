local _, ns = ...

-- Skipped steps stay out of the current route until the quest list changes,
-- the route is recalculated, or the player clears them.

function ns.StepKey(step)
	if type(step) ~= "table" then
		return ""
	end
	return table.concat({
		tostring(step.questId or step.questName or ""),
		tostring(step.verb or ""),
		tostring(step.title or ""),
	}, "|")
end

function ns.SkipStep(skipped, step)
	skipped[ns.StepKey(step)] = true
end

function ns.WithoutSkips(steps, skipped)
	local out = {}
	skipped = skipped or {}
	for i = 1, #(steps or {}) do
		if not skipped[ns.StepKey(steps[i])] then
			out[#out + 1] = steps[i]
		end
	end
	return out
end

function ns.ClearSkips(skipped)
	if type(skipped) ~= "table" then
		return
	end
	for key in pairs(skipped) do
		skipped[key] = nil
	end
end

function ns.QuestSetKey(steps)
	local ids = {}
	for i = 1, #(steps or {}) do
		ids[#ids + 1] = tostring(steps[i].questId or steps[i].questName or "")
	end
	table.sort(ids)
	return table.concat(ids, ",")
end
