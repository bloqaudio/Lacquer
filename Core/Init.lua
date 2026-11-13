local addonName, ns = ...

local Lacquer = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceConsole-3.0")
ns.addon = Lacquer
_G.Lacquer = ns

ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

ns.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
-- WOW_PROJECT_CAMELOT only exists on the Forever client.
ns.Forever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
ns.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ns.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
ns.Wrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
ns.Mists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
-- Retail is false on Forever; Modern covers both Mainline-UI clients.
ns.Modern = ns.Retail or ns.Forever

ns.defaults = {
	profile = {
		skins = { ["*"] = true },
		theme = {
			backdrop = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
			panel = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
			border = { r = 0, g = 0, b = 0, a = 1 },
			accent = { r = 0.09, g = 0.52, b = 0.82, a = 1 },
			font = "Friz Quadrata TT",
			texture = "Blizzard",
		},
	},
	global = {
		notices = {},
	},
}

-- The packager fills in Version; a copy run straight from the repo keeps the token.
function ns.VersionText()
	local version = ns.version
	if not version or version:find("@", 1, true) then
		return ns.L["development build"]
	end
	return version
end

function ns.Print(...)
	print("|cff1784d1Lacquer|r:", ...)
end

function Lacquer:OnInitialize()
	ns.db = LibStub("AceDB-3.0"):New("LacquerDB", ns.defaults, true)
	ns.db.RegisterCallback(ns, "OnProfileChanged", "OnThemeChanged")
	ns.db.RegisterCallback(ns, "OnProfileCopied", "OnThemeChanged")
	ns.db.RegisterCallback(ns, "OnProfileReset", "OnThemeChanged")
	ns.SetupOptions()
	ns.PrepareSkins()
end

function Lacquer:OnEnable()
	ns.SelectProvider()
	ns.CheckNotices()
end

function ns:OnThemeChanged()
	ns.RefreshTheme()
	ns.Standalone.Refresh()
end
