local _, ns = ...
local L = ns.L

-- In priority order. Tukui will slot in after ElvUI once its API is confirmed.
ns.providers = { ns.ElvUIProvider, ns.EllesmereProvider }

local OPERATIONS = {
	"Window", "Panel", "Inset", "Clear", "Backdrop",
	"Button", "CloseButton", "Tab", "CheckBox", "EditBox", "Dropdown", "ScrollBar", "Slider",
	"Icon", "ItemButton", "StatusBar", "Font",
}

local Paint = {}
ns.Paint = Paint

for _, operation in ipairs(OPERATIONS) do
	local done = setmetatable({}, { __mode = "k" })
	local fallback = ns.Standalone.ops[operation]
	Paint[operation] = function(target, ...)
		if not target or done[target] then
			return
		end
		done[target] = true
		local fn = ns.active and ns.active.ops[operation]
		if not fn or fn(target, ...) == false then
			fallback(target, ...)
		end
	end
end

function ns.Walk(frame, fn)
	for _, child in ipairs({ frame:GetChildren() }) do
		if fn(child) ~= false then
			ns.Walk(child, fn)
		end
	end
end

-- DropdownButton is an XML intrinsic, so IsObjectType reports it as a plain
-- Button. Recognise it by its mixin instead.
function ns.IsDropdown(frame)
	return type(frame.SetupMenu) == "function" and type(frame.OpenMenu) == "function"
end

local theme
function ns.Theme()
	return theme
end

-- The active suite's colours and media, with Lacquer's own settings filling
-- any gaps, so standalone fallbacks still match the suite.
function ns.RefreshTheme()
	local merged = ns.Standalone.theme()
	local suite = ns.active and ns.active ~= ns.Standalone and ns.active.theme and ns.active.theme()
	if suite then
		for key, value in pairs(suite) do
			merged[key] = value
		end
	end
	theme = merged
end

function ns.SelectProvider()
	for _, provider in ipairs(ns.providers) do
		if provider.detect() then
			ns.active = provider
			break
		end
	end
	ns.active = ns.active or ns.Standalone
	ns.RefreshTheme()
	if ns.active.init then
		ns.active.init(function()
			ns.RefreshTheme()
			ns.StartSkins()
		end)
	else
		ns.StartSkins()
	end
end

function ns.ProviderStatus()
	local active = ns.active
	if not active then
		return L["Lacquer has not started yet."]
	end
	if active.waiting then
		return L["Matching EllesmereUI: waiting for EllesmereUI to hand over its skinning tools. If skins never appear, check that skinning for Lacquer is on in EllesmereUI's options."]
	end
	if active == ns.Standalone then
		return L["Using Lacquer's own style: no supported UI suite is loaded."]
	end
	return format(L["Matching %s."], active.name)
end
