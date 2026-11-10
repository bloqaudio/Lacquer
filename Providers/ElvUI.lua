local _, ns = ...

-- Paints through ElvUI's public skinning toolkit. An operation returns false
-- when this ElvUI build lacks what it needs, and the standalone style is used.
local ElvUI = { id = "elvui", name = "ElvUI", ops = {} }
ns.ElvUIProvider = ElvUI
local ops = ElvUI.ops

local E, S

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

ops.Button = handler("HandleButton", true)
ops.CloseButton = handler("HandleCloseButton")
-- Atlas-driven tabs such as MinimalTabTemplate put their art back on hover
-- and selection after ElvUI clears it; zero alpha survives that.
local TAB_ART = { "Left", "Middle", "Right" }

function ops.Tab(tab)
	if not has(S, "HandleTab") then
		return false
	end
	S:HandleTab(tab)
	if type(tab.UpdateAtlas) == "function" then
		for _, key in ipairs(TAB_ART) do
			if tab[key] then
				tab[key]:SetAlpha(0)
			end
		end
	end
end
ops.CheckBox = handler("HandleCheckBox")
ops.EditBox = handler("HandleEditBox")
ops.Slider = handler("HandleSliderFrame")
ops.ItemButton = handler("HandleItemButton", true)
ops.StatusBar = handler("HandleStatusBar")

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
end

function ops.Font(fontString)
	if not has(fontString, "FontTemplate") then
		return false
	end
	local _, size = fontString:GetFont()
	fontString:FontTemplate(nil, size)
end
