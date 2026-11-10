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

function ops.ScrollBar(scrollBar)
	local method = scrollBar.Track and "HandleTrimScrollBar" or "HandleScrollBar"
	if not has(S, method) then
		return false
	end
	S[method](S, scrollBar)
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
