local _, ns = ...
local L = ns.L

local function bothSuites()
	return C_AddOns.IsAddOnLoaded("ElvUI") and C_AddOns.IsAddOnLoaded("EllesmereUI")
end

StaticPopupDialogs.LACQUER_ADDONSKINS = {
	text = L["AddOnSkins is enabled. Lacquer replaces it, and running both can skin the same addons twice.\n\nDisable AddOnSkins for all characters and reload?"],
	button1 = L["Disable and reload"],
	button2 = L["Keep both"],
	OnAccept = function()
		C_AddOns.DisableAddOn("AddOnSkins")
		C_AddOns.SaveAddOns()
		ReloadUI()
	end,
	OnCancel = function(_, _, reason)
		if reason == nil or reason == "clicked" then
			ns.db.global.notices.addonskins = "keep"
			ns.Print(L["Keeping AddOnSkins. Some addons may be skinned twice. Type /lacquer addonskins to change this."])
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	preferredIndex = 3,
}

StaticPopupDialogs.LACQUER_SUITES = {
	text = L["ElvUI and EllesmereUI are both enabled. Both restyle the whole interface, so they can fight over the same frames.\n\nLacquer is matching ElvUI. Consider disabling one of them."],
	button1 = OKAY,
	OnHide = function()
		ns.db.global.notices.suites = true
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function ns.ShowAddOnSkinsNotice()
	if not C_AddOns.IsAddOnLoaded("AddOnSkins") then
		ns.Print(L["AddOnSkins is not enabled."])
		return
	end
	StaticPopup_Show("LACQUER_ADDONSKINS")
end

function ns.PrintStatus()
	ns.Print(format(L["Version %s"], ns.VersionText()))
	ns.Print(ns.ProviderStatus())
	if bothSuites() then
		ns.Print(L["ElvUI and EllesmereUI are both enabled; they can conflict."])
	end
	if C_AddOns.IsAddOnLoaded("Tukui") then
		ns.Print(L["Tukui support is planned. Until then Lacquer uses its own style."])
	end
	if C_AddOns.IsAddOnLoaded("AddOnSkins") then
		ns.Print(L["AddOnSkins is also enabled. Type /lacquer addonskins to disable it."])
	end
end

function ns.CheckNotices()
	local notices = ns.db.global.notices
	if C_AddOns.IsAddOnLoaded("AddOnSkins") and notices.addonskins ~= "keep" then
		StaticPopup_Show("LACQUER_ADDONSKINS")
	end
	if bothSuites() and not notices.suites then
		StaticPopup_Show("LACQUER_SUITES")
	end
end
