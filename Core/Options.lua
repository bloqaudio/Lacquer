local addonName, ns = ...
local L = ns.L

local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local function colorOption(order, key, name)
	return {
		order = order,
		type = "color",
		name = name,
		hasAlpha = true,
		get = function()
			local c = ns.db.profile.theme[key]
			return c.r, c.g, c.b, c.a
		end,
		set = function(_, r, g, b, a)
			local c = ns.db.profile.theme[key]
			c.r, c.g, c.b, c.a = r, g, b, a
			ns:OnThemeChanged()
		end,
	}
end

local function mediaOption(order, key, mediaType, name)
	return {
		order = order,
		type = "select",
		name = name,
		values = function()
			local values = {}
			for _, entry in ipairs(LSM:List(mediaType)) do
				values[entry] = entry
			end
			return values
		end,
		get = function()
			return ns.db.profile.theme[key]
		end,
		set = function(_, value)
			ns.db.profile.theme[key] = value
			ns:OnThemeChanged()
		end,
	}
end

local function skinToggles()
	local args = {
		note = {
			order = 0,
			type = "description",
			name = L["Turning a skin on or off takes effect after a reload."],
		},
		reload = {
			order = 1,
			type = "execute",
			name = L["Reload UI"],
			func = ReloadUI,
		},
	}
	for index, skin in ipairs(ns.skinOrder) do
		args[skin.id] = {
			order = 10 + index,
			type = "toggle",
			name = skin.title,
			desc = function()
				return skin:Status()
			end,
			get = function()
				return ns.db.profile.skins[skin.id]
			end,
			set = function(_, value)
				ns.db.profile.skins[skin.id] = value
			end,
		}
	end
	return args
end

function ns.SetupOptions()
	local options = {
		type = "group",
		name = "Lacquer",
		childGroups = "tab",
		args = {
			general = {
				order = 1,
				type = "group",
				name = L["General"],
				args = {
					status = {
						order = 1,
						type = "description",
						fontSize = "medium",
						name = function()
							return ns.ProviderStatus()
						end,
					},
					tukui = {
						order = 2,
						type = "description",
						name = L["Tukui support is planned. Until then Lacquer uses its own style."],
						hidden = function()
							return not C_AddOns.IsAddOnLoaded("Tukui")
						end,
					},
					errors = {
						order = 3,
						type = "execute",
						name = L["Print skin errors"],
						func = ns.PrintErrors,
					},
				},
			},
			skins = {
				order = 2,
				type = "group",
				name = L["Skins"],
				args = skinToggles(),
			},
			theme = {
				order = 3,
				type = "group",
				name = L["Style"],
				hidden = function()
					return ns.active ~= ns.Standalone
				end,
				args = {
					backdrop = colorOption(1, "backdrop", L["Window background"]),
					panel = colorOption(2, "panel", L["Control background"]),
					border = colorOption(3, "border", L["Border"]),
					accent = colorOption(4, "accent", L["Accent"]),
					font = mediaOption(5, "font", "font", L["Font"]),
					texture = mediaOption(6, "texture", "statusbar", L["Bar texture"]),
				},
			},
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ns.db),
		},
	}
	options.args.profiles.order = 4

	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
	ACD:AddToBlizOptions(addonName, "Lacquer")

	ns.addon:RegisterChatCommand("lacquer", function(input)
		local command = strtrim(input or ""):lower()
		if command == "errors" then
			ns.PrintErrors()
		elseif command == "addonskins" then
			ns.ShowAddOnSkinsNotice()
		elseif command == "status" then
			ns.PrintStatus()
		elseif command == "" then
			ACD:Open(addonName)
		else
			ns.Print(L["Commands: /lacquer, /lacquer status, /lacquer errors, /lacquer addonskins"])
		end
	end)
end
