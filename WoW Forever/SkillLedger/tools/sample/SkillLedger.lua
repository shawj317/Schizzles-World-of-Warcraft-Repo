-- Sample SavedVariables for the converter test. Not a real character.
-- Written in the shape WoW uses, including the "-- [n]" comments it appends.
SkillLedgerDB = {
	["version"] = 1,
	["prices"] = {
		["updated"] = 1762800000,
		["full"] = false,
		["items"] = {
			{
				["id"] = 2770,
				["name"] = "Copper Ore",
				["unit"] = 30,
				["qty"] = 80,
				["total"] = 200,
				["at"] = 1762800000,
				["source"] = "scan",
			}, -- [1]
			{
				["id"] = 2840,
				["name"] = "Copper Bar",
				["unit"] = 400,
				["qty"] = 10,
				["total"] = 10,
				["at"] = 1762800000,
				["source"] = "scan",
			}, -- [2]
			{
				["id"] = 2835,
				["name"] = "Rough Stone",
				["unit"] = 20,
				["qty"] = 40,
				["total"] = 40,
				["at"] = 1762800000,
				["source"] = "scan",
			}, -- [3]
			{
				["id"] = 2589,
				["name"] = "Linen Cloth",
				["unit"] = 80,
				["qty"] = 60,
				["total"] = 60,
				["at"] = 1762800000,
				["source"] = "scan",
			}, -- [4]
		},
	},
	["chars"] = {
		["Grimjaw-Forever"] = {
			["key"] = "Grimjaw-Forever",
			["name"] = "Grimjaw",
			["realm"] = "Forever",
			["faction"] = "Horde",
			["class"] = "Warrior",
			["classFile"] = "WARRIOR",
			["race"] = "Orc",
			["level"] = 20,
			["updated"] = 1762800000,
			["professions"] = {
				{
					["name"] = "Mining",
					["skillLine"] = 186,
					["rank"] = 10,
					["maxRank"] = 75,
					["secondary"] = false,
				}, -- [1]
				{
					["name"] = "Blacksmithing",
					["skillLine"] = 164,
					["rank"] = 1,
					["maxRank"] = 75,
					["secondary"] = false,
				}, -- [2]
				{
					["name"] = "First Aid",
					["skillLine"] = 129,
					["rank"] = 1,
					["maxRank"] = 75,
					["secondary"] = true,
				}, -- [3]
			},
			["bags"] = {
				["updated"] = 1762800000,
				["items"] = {
					{ ["id"] = 2770, ["name"] = "Copper Ore", ["count"] = 20, ["bag"] = 0, ["slot"] = 1, ["where"] = "bag" }, -- [1]
					{ ["id"] = 2835, ["name"] = "Rough Stone", ["count"] = 10, ["bag"] = 0, ["slot"] = 2, ["where"] = "bag" }, -- [2]
					{ ["id"] = 2589, ["name"] = "Linen Cloth", ["count"] = 8, ["bag"] = 0, ["slot"] = 3, ["where"] = "bag" }, -- [3]
				},
			},
			["bank"] = {
				["updated"] = 1762790000,
				["items"] = {
					{ ["id"] = 2589, ["name"] = "Linen Cloth", ["count"] = 5, ["bag"] = -1, ["slot"] = 1, ["where"] = "bank" }, -- [1]
				},
			},
			["standings"] = {
				["updated"] = 1762800000,
				["factions"] = {
					{ ["id"] = 76, ["name"] = "Orgrimmar", ["standing"] = 5, ["earned"] = 4000 }, -- [1]
					{ ["id"] = 81, ["name"] = "Thunder Bluff", ["standing"] = 4, ["earned"] = 500 }, -- [2]
					{ ["id"] = 68, ["name"] = "Undercity", ["standing"] = 4, ["earned"] = 200 }, -- [3]
					{ ["id"] = 530, ["name"] = "Darkspear Trolls", ["standing"] = 4, ["earned"] = 0 }, -- [4]
					{ ["id"] = 470, ["name"] = "Ratchet", ["standing"] = 4, ["earned"] = 0 }, -- [5]
				},
			},
			["merchant"] = {
				["updated"] = 1762800500,
				["rows"] = {
					{
						["id"] = 3371,
						["name"] = "Empty Vial",
						["unit"] = 19,
						["stackPrice"] = 19,
						["stack"] = 1,
						["npc"] = "Sovik",
						["npcId"] = 3413,
						["factionId"] = 76,
						["faction"] = "Orgrimmar",
						["side"] = "Horde",
						["standing"] = 5,
						["at"] = 1762800500,
					}, -- [1]
				},
			},
		},
	},
	["ui"] = {
		["x"] = -480,
		["y"] = 40,
	},
}
