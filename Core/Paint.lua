local _, ns = ...
local L = ns.L

-- In priority order. Tukui will slot in after ElvUI once its API is confirmed.
ns.providers = { ns.ElvUIProvider, ns.EllesmereProvider }

local OPERATIONS = {
	"Window", "Panel", "Inset", "Clear", "Backdrop",
	"Button", "CloseButton", "Tab", "SideTab", "CheckBox", "Radio", "Swatch", "EditBox", "Dropdown", "ScrollBar", "Slider", "StepSlider", "ArrowButton",
	"Icon", "IconFrame", "ItemButton", "Row", "StatusBar", "Font",
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

-- Modern item and action button icons carry a mask that rounds their corners.
function ns.Unmask(texture)
	if not texture.GetNumMaskTextures then
		return
	end
	for index = texture:GetNumMaskTextures(), 1, -1 do
		texture:RemoveMaskTexture(texture:GetMaskTexture(index))
	end
end

local crops = setmetatable({}, { __mode = "k" })

local function reapplyCrop(texture)
	local crop = crops[texture]
	texture:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
end

-- A new texture resets the crop on modern clients, and item buttons swap
-- their icon on every update. crop is a live table, so a suite setting that
-- changes it in place carries through.
function ns.KeepCrop(texture, crop)
	local first = not crops[texture]
	crops[texture] = crop
	reapplyCrop(texture)
	if first then
		hooksecurefunc(texture, "SetTexture", reapplyCrop)
	end
end

local function styleSettingsControl(child)
	local parent = child:GetParent()
	if ns.IsDropdown(child) then
		ns.Paint.Dropdown(child)
		return false
	elseif child.Slider and child.Back and child.Forward then
		-- ElvUI's stepper slider style leaves the arrows as Blizzard drew them.
		ns.Paint.StepSlider(child)
		ns.Paint.ArrowButton(child.Back, "left")
		ns.Paint.ArrowButton(child.Forward, "right")
		return false
	elseif child:IsObjectType("CheckButton") then
		ns.Paint.CheckBox(child)
	elseif child:IsObjectType("Slider") then
		ns.Paint.Slider(child)
	elseif not child:IsObjectType("Button") then
		return
	elseif child.Left and child.Middle and child.Right then
		ns.Paint.Button(child)
	elseif parent.DecrementButton == child then
		ns.Paint.ArrowButton(child, "left")
	elseif parent.IncrementButton == child then
		ns.Paint.ArrowButton(child, "right")
	end
end

local settingsLists = setmetatable({}, { __mode = "k" })

-- For an addon's own copy of Blizzard's SettingsListTemplate on a canvas
-- page, which the suites don't reach. Rows are pooled, so each is styled
-- when it is initialized, under the calling skin's error isolation.
function ns.StyleSettingsList(skin, list)
	if settingsLists[list] then
		return
	end
	settingsLists[list] = true
	ns.Paint.ScrollBar(list.ScrollBar)
	ns.Paint.Button(list.Header and list.Header.DefaultsButton)
	local function styleRow(row)
		skin:Call(ns.Walk, row, styleSettingsControl)
	end
	list.ScrollBox:ForEachFrame(styleRow)
	list.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnInitializedFrame, function(_, row)
		styleRow(row)
	end, list)
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
