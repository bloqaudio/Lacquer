local _, ns = ...

-- Paints through ElvUI's public skinning toolkit. An operation returns false
-- when this ElvUI build lacks what it needs, and the standalone style is used.
local ElvUI = { id = "elvui", name = "ElvUI", ops = {} }
ns.ElvUIProvider = ElvUI
local ops = ElvUI.ops

local E, S

local ICON_CROP = { 0.08, 0.92, 0.08, 0.92 }

local function has(object, method)
	return object and type(object[method]) == "function"
end

function ElvUI.detect()
	local engine = C_AddOns.IsAddOnLoaded("ElvUI") and _G.ElvUI
	return type(engine) == "table" and type(engine[1]) == "table"
end

function ElvUI.init(ready)
	E = _G.ElvUI[1]
	S = has(E, "GetModule") and E:GetModule("Skins", true) or nil
	ready()
end

local function color(c, alpha)
	if type(c) ~= "table" then
		return nil
	end
	return { r = c[1] or c.r, g = c[2] or c.g, b = c[3] or c.b, a = alpha or c[4] or c.a or 1 }
end

function ElvUI.theme()
	local media = E and E.media
	if not media then
		return nil
	end
	return {
		backdrop = color(media.backdropfadecolor),
		panel = color(media.backdropcolor),
		border = color(media.bordercolor),
		accent = color(media.rgbvaluecolor),
		font = media.normFont,
		texture = media.normTex,
	}
end

local function template(frame, kind)
	if not (has(frame, "StripTextures") and has(frame, "SetTemplate")) then
		return false
	end
	frame:StripTextures()
	frame:SetTemplate(kind)
end

function ops.Window(frame)
	if (frame.NineSlice or frame.PortraitContainer) and has(S, "HandlePortraitFrame") then
		S:HandlePortraitFrame(frame)
		return
	end
	return template(frame, "Transparent")
end

function ops.Panel(frame)
	return template(frame)
end

function ops.Inset(frame)
	if has(S, "HandleInsetFrame") then
		S:HandleInsetFrame(frame)
		return
	end
	if not has(frame, "StripTextures") then
		return false
	end
	frame:StripTextures()
end

function ops.Backdrop(frame)
	if not has(frame, "CreateBackdrop") then
		return false
	end
	frame:CreateBackdrop("Transparent")
end

function ops.Clear(frame)
	if not has(frame, "StripTextures") then
		return false
	end
	frame:StripTextures()
end

local function handler(method, ...)
	local extra = { ... }
	local count = select("#", ...)
	return function(object)
		if not has(S, method) then
			return false
		end
		S[method](S, object, unpack(extra, 1, count))
	end
end

-- Some templates put their three-piece art back after ElvUI clears it, on
-- hover, click, or selection; zero alpha survives that.
local THREE_PIECE = { "Left", "Middle", "Right" }

local function hideThreePiece(frame)
	for _, key in ipairs(THREE_PIECE) do
		local region = frame[key]
		if region and region.SetAlpha then
			region:SetAlpha(0)
		end
	end
end

-- Blizzard's three-slice buttons redraw their art into Left, Center, and
-- Right on every show, click, and enable, and a backdrop takes an existing
-- Center as its own fill. They get hidden stand-ins to draw into.
local THREE_SLICE = { "Left", "Center", "Right" }

local function detachThreeSlice(button)
	if type(button.GetCenterAtlasName) ~= "function" then
		return
	end
	for _, key in ipairs(THREE_SLICE) do
		local art = button[key]
		if art then
			art:SetAlpha(0)
			local standIn = button:CreateTexture()
			standIn:Hide()
			button[key] = standIn
		end
	end
end

-- keep names textures that are content rather than button art, such as an
-- arrow glyph; HandleButton clears every texture, so they are put back.
function ops.Button(button, opts)
	if not has(S, "HandleButton") then
		return false
	end
	local kept = {}
	for _, key in ipairs(opts and opts.keep or {}) do
		local region = button[key]
		if region and region.GetAtlas then
			kept[region] = { atlas = region:GetAtlas(), file = region:GetTexture() }
		end
	end
	detachThreeSlice(button)
	S:HandleButton(button, true)
	hideThreePiece(button)
	for region, art in pairs(kept) do
		if art.atlas then
			region:SetAtlas(art.atlas)
		elseif art.file then
			region:SetTexture(art.file)
		end
	end
end

ops.CloseButton = handler("HandleCloseButton")

function ops.Tab(tab)
	if not has(S, "HandleTab") then
		return false
	end
	S:HandleTab(tab)
	if type(tab.UpdateAtlas) == "function" then
		hideThreePiece(tab)
	end
end
-- A tall LargeSideTabButtonTemplate tab, as on the quest log. like is one of
-- Blizzard's own side tabs, whose size this tab takes so the column lines up.
local SIDE_TAB_ART = { "Background", "SelectedTexture" }

function ops.SideTab(tab, like)
	if not has(tab, "CreateBackdrop") then
		return false
	end
	for _, key in ipairs(SIDE_TAB_ART) do
		if tab[key] then
			tab[key]:SetAlpha(0)
		end
	end
	if like then
		tab:SetSize(like:GetSize())
	end
	tab:CreateBackdrop()
	local highlight = tab.HighlightTexture
	if highlight and tab.backdrop then
		highlight:SetColorTexture(1, 1, 1, 0.25)
		highlight:ClearAllPoints()
		highlight:SetInside(tab.backdrop)
	end
end

-- box is the visible box of a check button wider than it, such as one that
-- carries its own label; ElvUI would otherwise fill the whole button.
local CHECK_TEXTURES = { "GetCheckedTexture", "GetDisabledTexture" }

function ops.CheckBox(check, box)
	if not has(S, "HandleCheckBox") then
		return false
	end
	S:HandleCheckBox(check)
	local backdrop = check.backdrop
	if not (box and backdrop) then
		return
	end
	backdrop:ClearAllPoints()
	backdrop:SetInside(box, 4, 4)
	for _, getter in ipairs(CHECK_TEXTURES) do
		local texture = check[getter] and check[getter](check)
		if texture then
			texture:ClearAllPoints()
			texture:SetInside(backdrop)
		end
	end
end
ops.Radio = handler("HandleRadioButton")
ops.EditBox = handler("HandleEditBox")
ops.Slider = handler("HandleSliderFrame")
ops.StepSlider = handler("HandleStepSlider")
function ops.ArrowButton(button, direction)
	if not has(S, "HandleNextPrevButton") then
		return false
	end
	S:HandleNextPrevButton(button, direction)
end
ops.StatusBar = handler("HandleStatusBar")

-- Not HandleItemButton: that clears every texture on the button, and item
-- slots carry overlays their addon keeps using (quest, junk, upgrade, glow).
-- Only the slot art, the icon's edges, and the quality border change; the
-- border colour follows the button's IconBorder.
function ops.ItemButton(button)
	if not (has(button, "CreateBackdrop") and has(S, "HandleIconBorder")) then
		return false
	end
	local name = button:GetName()
	local icon = button.icon or button.Icon or (name and _G[name .. "IconTexture"])
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		normal:SetAlpha(0)
	end
	button:CreateBackdrop()
	if has(button, "StyleButton") then
		button:StyleButton()
	end
	if icon then
		ns.Unmask(icon)
		ns.KeepCrop(icon, type(E.TexCoords) == "table" and E.TexCoords or ICON_CROP)
	end
	if button.IconBorder then
		S:HandleIconBorder(button.IconBorder, button.backdrop)
	end
end

-- frame covers an icon or portrait drawn by its parent; border is the
-- parent's quality border texture, whose colour moves to the backdrop.
function ops.IconFrame(frame, border)
	if not (has(frame, "CreateBackdrop") and has(S, "HandleIconBorder")) then
		return false
	end
	frame:CreateBackdrop()
	if border and frame.backdrop then
		S:HandleIconBorder(border, frame.backdrop)
	end
end

-- Without a width ElvUI resizes the box to its own default, so modern
-- dropdowns keep the width their addon gave them. Legacy UIDropDownMenu
-- frames take ElvUI's separate legacy path.
function ops.Dropdown(dropdown)
	if not has(S, "HandleDropDownBox") then
		return false
	end
	if ns.IsDropdown(dropdown) then
		S:HandleDropDownBox(dropdown, dropdown:GetWidth())
	else
		S:HandleDropDownBox(dropdown, nil, nil, true)
	end
end

-- ElvUI draws a legacy bar's thumb full width at full colour. These match
-- its modern bars instead: a narrower thumb, dim until the bar is hovered.
local LEGACY_THUMB_INSET = 5
local THUMB_EVENTS = { "Enable", "Disable", "SetEnabled", "SetMinMaxValues" }

local function matchModernThumb(scrollBar)
	local backdrop = scrollBar.Thumb and scrollBar.Thumb.backdrop
	if not (backdrop and type(E.media.rgbvaluecolor) == "table") then
		return
	end
	local function paint()
		local low, high = scrollBar:GetMinMaxValues()
		-- ElvUI greys out a bar with nothing to scroll; that stays.
		if not (scrollBar:IsEnabled() and high > low) then
			return
		end
		local r, g, b = unpack(E.media.rgbvaluecolor)
		backdrop:SetBackdropColor(r, g, b, scrollBar:IsMouseOver() and 1 or 0.25)
	end
	for _, method in ipairs(THUMB_EVENTS) do
		hooksecurefunc(scrollBar, method, paint)
	end
	scrollBar:HookScript("OnEnter", paint)
	scrollBar:HookScript("OnLeave", paint)
	paint()
end

function ops.ScrollBar(scrollBar)
	if scrollBar.Track then
		if not has(S, "HandleTrimScrollBar") then
			return false
		end
		S:HandleTrimScrollBar(scrollBar)
		return
	end
	if not has(S, "HandleScrollBar") then
		return false
	end
	S:HandleScrollBar(scrollBar, nil, LEGACY_THUMB_INSET)
	-- Modern bars have no track behind the thumb.
	if scrollBar.backdrop then
		scrollBar.backdrop:SetAlpha(0)
	end
	matchModernThumb(scrollBar)
end

-- A list row. marker is the row's own selection art; it gives way to a gold
-- border that follows whether the marker is shown. The border sits inside
-- the row, since a scrolling list clips the edges of its outer rows.
local SELECTED = { r = 1, g = 0.8, b = 0.1 }
local MARKER_EVENTS = { "Show", "Hide", "SetShown" }

function ops.Row(row, marker)
	if not has(row, "CreateBackdrop") then
		return false
	end
	row:CreateBackdrop("Transparent")
	local backdrop = row.backdrop
	if not backdrop then
		return
	end
	backdrop:ClearAllPoints()
	if has(backdrop, "SetInside") then
		backdrop:SetInside(row)
	else
		backdrop:SetAllPoints(row)
	end
	if not marker then
		return
	end
	marker:SetAlpha(0)
	local function update()
		local edge = marker:IsShown() and SELECTED or color(E.media.bordercolor)
		if edge then
			backdrop:SetBackdropBorderColor(edge.r, edge.g, edge.b)
		end
	end
	for _, method in ipairs(MARKER_EVENTS) do
		hooksecurefunc(marker, method, update)
	end
	update()
end

function ops.Icon(texture, parent)
	if not has(S, "HandleIcon") then
		return false
	end
	S:HandleIcon(texture, parent ~= nil)
	ns.KeepCrop(texture, type(E.TexCoords) == "table" and E.TexCoords or ICON_CROP)
end

function ops.Font(fontString)
	if not has(fontString, "FontTemplate") then
		return false
	end
	local _, size = fontString:GetFont()
	fontString:FontTemplate(nil, size)
end
