local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CLOSE = "Interface\\AddOns\\Lacquer\\Media\\Close"
local ICON_CROP = { 0.08, 0.92, 0.08, 0.92 }

local Standalone = { id = "standalone", name = "Lacquer", ops = {} }
ns.Standalone = Standalone
local ops = Standalone.ops

local plates = setmetatable({}, { __mode = "k" })
local glyphs = setmetatable({}, { __mode = "k" })
local bars = setmetatable({}, { __mode = "k" })
local fonts = setmetatable({}, { __mode = "k" })

function Standalone.theme()
	local t = ns.db.profile.theme
	return {
		backdrop = t.backdrop,
		panel = t.panel,
		border = t.border,
		accent = t.accent,
		font = LSM:Fetch("font", t.font, true),
		texture = LSM:Fetch("statusbar", t.texture, true),
	}
end

local function pixel(frame)
	return PixelUtil.GetNearestPixelSize(1, frame:GetEffectiveScale(), 1)
end

local function paint(plate)
	local t = ns.Theme()
	local bg = t[plate.bgKey]
	if bg then
		plate:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 1)
	else
		plate:SetBackdropColor(0, 0, 0, 0)
	end
	local edge = plate.quality or ((plate.hover or plate.selected) and t.accent) or t.border
	plate:SetBackdropBorderColor(edge.r, edge.g, edge.b, edge.a or 1)
end

-- The plate is a child drawn one level below its owner, so it sits behind the
-- owner's own regions without touching the owner's backdrop or scripts.
local function plateFor(frame, bgKey, inset, anchor)
	local plate = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	local level = frame:GetFrameLevel()
	plate:SetFrameLevel(level > 0 and level - 1 or 0)
	anchor = anchor or frame
	if inset then
		plate:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset[1], inset[2])
		plate:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", inset[3], inset[4])
	else
		plate:SetAllPoints(anchor)
	end
	plate:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = pixel(frame) })
	plate.bgKey = bgKey
	plates[plate] = true
	paint(plate)
	return plate
end

local function hover(frame, plate)
	frame:HookScript("OnEnter", function()
		plate.hover = true
		paint(plate)
	end)
	frame:HookScript("OnLeave", function()
		plate.hover = false
		paint(plate)
	end)
end

local function fade(object)
	if object and object.SetAlpha then
		object:SetAlpha(0)
	end
end

local function keepSet(frame, keys, extra)
	local set = extra or {}
	if keys then
		for _, key in ipairs(keys) do
			if frame[key] then
				set[frame[key]] = true
			end
		end
	end
	return set
end

-- Alpha-only art removal: the owner can keep calling SetTexture/SetAtlas or
-- Show/Hide on its regions and they stay invisible.
local function fadeTextures(frame, keep)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") and not keep[region] then
			region:SetAlpha(0)
		end
	end
end

local BUTTON_TEXTURES = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }

local function fadeButtonTextures(button, keep)
	for _, getter in ipairs(BUTTON_TEXTURES) do
		local texture = button[getter] and button[getter](button)
		if texture and not keep[texture] then
			texture:SetAlpha(0)
		end
	end
end

local function clear(frame, keep)
	fadeTextures(frame, keep)
	fade(frame.NineSlice)
	fade(frame.PortraitContainer)
	if frame.Bg and not keep[frame.Bg] then
		fade(frame.Bg)
	end
end

function ops.Clear(frame, opts)
	clear(frame, keepSet(frame, opts and opts.keep))
end

function ops.Window(frame, opts)
	clear(frame, keepSet(frame, opts and opts.keep))
	if frame.Inset then
		ns.Paint.Inset(frame.Inset)
	end
	plateFor(frame, "backdrop")
end

function ops.Panel(frame, opts)
	clear(frame, keepSet(frame, opts and opts.keep))
	plateFor(frame, "panel")
end

function ops.Inset(frame)
	clear(frame, {})
end

-- Leaves the frame's own art alone, for overlays that draw on themselves.
function ops.Backdrop(frame)
	local px = pixel(frame)
	plateFor(frame, "backdrop", { -px, px, px, -px })
end

function ops.Button(button, opts)
	local keep = keepSet(button, opts and opts.keep)
	fadeTextures(button, keep)
	fadeButtonTextures(button, keep)
	hover(button, plateFor(button, "panel"))
end

function ops.CloseButton(button)
	local keep = {}
	fadeTextures(button, keep)
	fadeButtonTextures(button, keep)
	local size = math.floor(math.min(button:GetWidth(), button:GetHeight()) * 0.5 + 0.5)
	local glyph = button:CreateTexture(nil, "OVERLAY")
	glyph:SetTexture(CLOSE)
	glyph:SetSize(size, size)
	glyph:SetPoint("CENTER")
	glyph:SetVertexColor(1, 1, 1)
	glyphs[glyph] = button
	button:HookScript("OnEnter", function()
		local accent = ns.Theme().accent
		glyph:SetVertexColor(accent.r, accent.g, accent.b)
	end)
	button:HookScript("OnLeave", function()
		glyph:SetVertexColor(1, 1, 1)
	end)
end

local tabPlates = setmetatable({}, { __mode = "k" })

local function tabSelected(tab)
	if tab.LeftActive then
		return tab.LeftActive:IsShown()
	end
	if tab.IsSelected then
		return tab:IsSelected()
	end
	return not tab:IsEnabled()
end

local function updateTab(tab)
	local plate = tabPlates[tab]
	if plate then
		plate.selected = tabSelected(tab)
		paint(plate)
	end
end

local tabHooks
function ops.Tab(tab)
	local keep = {}
	fadeTextures(tab, keep)
	fadeButtonTextures(tab, keep)
	local plate = plateFor(tab, "panel", { 5, -4, -5, 4 })
	tabPlates[tab] = plate
	hover(tab, plate)
	if not tabHooks then
		tabHooks = true
		hooksecurefunc("PanelTemplates_SelectTab", updateTab)
		hooksecurefunc("PanelTemplates_DeselectTab", updateTab)
		if PanelTemplates_SetDisabledTabState then
			hooksecurefunc("PanelTemplates_SetDisabledTabState", updateTab)
		end
	end
	-- MinimalTabTemplate selects through its own mixin, not PanelTemplates.
	if type(tab.UpdateAtlas) == "function" then
		hooksecurefunc(tab, "UpdateAtlas", updateTab)
	end
	updateTab(tab)
end

-- The standalone style leaves Blizzard's own side tabs alone, so an addon's
-- side tab keeps the same art to match them.
function ops.SideTab() end

function ops.CheckBox(check, box)
	local keep = {}
	local checked = check.GetCheckedTexture and check:GetCheckedTexture()
	local disabledChecked = check.GetDisabledCheckedTexture and check:GetDisabledCheckedTexture()
	if checked then
		keep[checked] = true
	end
	if disabledChecked then
		keep[disabledChecked] = true
	end
	fadeTextures(check, keep)
	fadeButtonTextures(check, keep)
	local area = box or check
	local inset = math.floor(math.min(area:GetWidth(), area:GetHeight()) * 0.2 + 0.5)
	hover(check, plateFor(check, "panel", { inset, -inset, -inset, inset }, box))
end

-- A colour swatch button: its own frame art and any rounding mask go, the
-- colour stays, and a thin border goes around the swatch.
function ops.Swatch(button, swatch)
	ns.Unmask(swatch)
	local keep = { [swatch] = true }
	fadeTextures(button, keep)
	fadeButtonTextures(button, keep)
	local px = pixel(button)
	hover(button, plateFor(button, "none", { -px, px, px, -px }, swatch))
end

function ops.EditBox(editBox, opts)
	fadeTextures(editBox, keepSet(editBox, opts and opts.keep or { "searchIcon", "Instructions" }))
	plateFor(editBox, "panel", opts and opts.inset or { -3, 0, 0, 0 })
end

function ops.Dropdown(dropdown)
	if dropdown.Arrow then
		fadeTextures(dropdown, keepSet(dropdown, { "Arrow" }))
		hover(dropdown, plateFor(dropdown, "panel"))
		return
	end
	-- UIDropDownMenuTemplate: the art is far wider than the visible box.
	fade(dropdown.Left)
	fade(dropdown.Middle)
	fade(dropdown.Right)
	plateFor(dropdown, "panel", { 17, -4, -17, 6 })
end

function ops.ScrollBar(scrollBar)
	if scrollBar.Track then
		fadeTextures(scrollBar, {})
		fadeTextures(scrollBar.Track, {})
		plateFor(scrollBar.Track, "panel")
		local thumb = scrollBar.Track.Thumb
		if thumb then
			fadeTextures(thumb, {})
			plateFor(thumb, "accent")
		end
		return
	end
	local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
	local keep = {}
	if thumb then
		keep[thumb] = true
	end
	fadeTextures(scrollBar, keep)
	plateFor(scrollBar, "panel", { 2, 0, -2, 0 })
	if thumb then
		local accent = ns.Theme().accent
		thumb:SetTexture(WHITE)
		thumb:SetVertexColor(accent.r, accent.g, accent.b, accent.a or 1)
		thumb:SetWidth(math.max(4, scrollBar:GetWidth() - 6))
		glyphs[thumb] = scrollBar
	end
end

-- A thin track through the middle of the slider, with an accent thumb.
function ops.Slider(slider)
	local thumb = slider:GetThumbTexture()
	fadeTextures(slider, thumb and { [thumb] = true } or {})
	local vertical = slider:GetOrientation() == "VERTICAL"
	local span = vertical and slider:GetWidth() or slider:GetHeight()
	local inset = math.max(0, math.floor(span / 2) - 3)
	if vertical then
		plateFor(slider, "panel", { inset, 0, -inset, 0 })
	else
		plateFor(slider, "panel", { 0, -inset, 0, inset })
	end
	if thumb then
		local accent = ns.Theme().accent
		local length = math.max(8, span - 2 * inset + 4)
		thumb:SetTexture(WHITE)
		thumb:SetVertexColor(accent.r, accent.g, accent.b, accent.a or 1)
		if vertical then
			thumb:SetSize(length, 8)
		else
			thumb:SetSize(8, length)
		end
		glyphs[thumb] = slider
	end
end

-- MinimalSliderWithSteppers: the slider inside, with Blizzard's arrows kept.
function ops.StepSlider(frame)
	ns.Paint.Slider(frame.Slider)
end

-- No arrow art of Lacquer's own yet, so arrow buttons keep Blizzard's.
function ops.ArrowButton() end

function ops.Icon(texture, parent)
	ns.KeepCrop(texture, ICON_CROP)
	if parent then
		local px = pixel(parent)
		plateFor(parent, "none", { -px, px, px, -px }, texture)
	end
end

local itemPlates = setmetatable({}, { __mode = "k" })
local qualityHook

local function onQuality(button, quality)
	local plate = itemPlates[button]
	if not plate then
		return
	end
	local color = quality and quality > 1 and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	plate.quality = color and { r = color.r, g = color.g, b = color.b } or nil
	paint(plate)
end

function ops.ItemButton(button)
	local name = button:GetName()
	local icon = button.icon or button.Icon or (name and _G[name .. "IconTexture"])
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	fade(normal)
	fade(button.IconBorder)
	if icon then
		ns.Unmask(icon)
		ns.KeepCrop(icon, ICON_CROP)
	end
	itemPlates[button] = plateFor(button, "panel")
	if not qualityHook and SetItemButtonQuality then
		qualityHook = true
		hooksecurefunc("SetItemButtonQuality", onQuality)
	end
end

function ops.StatusBar(bar)
	local fill = bar:GetStatusBarTexture()
	fadeTextures(bar, fill and { [fill] = true } or {})
	bar:SetStatusBarTexture(ns.Theme().texture or WHITE)
	bars[bar] = true
	local px = pixel(bar)
	plateFor(bar, "panel", { -px, px, px, -px })
end

function ops.Font(fontString)
	local _, size, flags = fontString:GetFont()
	local font = ns.Theme().font
	if font then
		fontString:SetFont(font, size or 12, flags or "")
		fonts[fontString] = true
	end
end

function Standalone.Refresh()
	for plate in pairs(plates) do
		paint(plate)
	end
	local t = ns.Theme()
	for texture, owner in pairs(glyphs) do
		if owner.GetThumbTexture and owner:GetThumbTexture() == texture then
			texture:SetVertexColor(t.accent.r, t.accent.g, t.accent.b, t.accent.a or 1)
		end
	end
	if t.texture then
		for bar in pairs(bars) do
			bar:SetStatusBarTexture(t.texture)
		end
	end
	if t.font then
		for fontString in pairs(fonts) do
			local _, size, flags = fontString:GetFont()
			fontString:SetFont(t.font, size or 12, flags or "")
		end
	end
end
