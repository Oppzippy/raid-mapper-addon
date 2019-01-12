local LibCopyPaste = LibStub:GetLibrary("LibCopyPaste-1.0")

SLASH_RAIDMAPPER1 = "/raidmapper"
SLASH_RAIDMAPPER2 = "/raidmap"

local function IterateGroupMembers()
	local group = IsInRaid() and "raid" or IsInGroup() and "party"
	local i = 0
	local members = math.max(GetNumGroupMembers(), 1)
	return function()
		i = i + 1
		if i > members then return end
		if i == 1 and (group == "party" or not group) then
			return "player"
		end
		
		if group == "party" then
			return group .. (i - 1)
		elseif group == "raid" then
			return group .. i
		end
	end
end

local function ExportUnit(unit)
	local _, _, class = UnitClass(unit)
	local name = UnitName(unit)
	return {
		['name'] = name,
		['sprite'] = class + 3,
	}
end

local function ExportGroupMembers()
	local ret = {}
	for unit in IterateGroupMembers() do
		table.insert(ret, ExportUnit(unit))
	end
	return ret
end

local function ExportJSON(t)
	local isArray = t[1]
	local ret = {}
	table.insert(ret, t[1] and "[" or "{")
	local jsonFormat = "\"%s\":%s"
	local arrayFormat = "%s"
	local quoted = "\"%s\""
	local iter = isArray and ipairs or pairs
	
	for k, v in iter(t) do
		if type(v) == "table" then
			table.insert(ret, ExportJSON(v))
			table.insert(ret, ",")
		else
			local formattedV = type(v) == "number" and v or (quoted:format(v))
			if isArray then
				table.insert(ret, arrayFormat:format(formattedV))
			else
				table.insert(ret, jsonFormat:format(k, formattedV))
			end
			table.insert(ret, ",")
		end
	end
	ret[#ret] = nil -- Delete trailing comma
	table.insert(ret, isArray and "]" or "}")
	return table.concat(ret)
end

local function TrimNames(units, length)
	for i, unit in ipairs(units) do
		unit.name = unit.name:sub(1, length)
	end
end

SlashCmdList["RAIDMAPPER"] = function(msg)
	local export = ExportGroupMembers()
	local trim = tonumber(msg)
	if trim then
		TrimNames(export, trim)
	end
	local str = ExportJSON(export)
	LibCopyPaste:Copy("Raid Mapper Export", str)
end