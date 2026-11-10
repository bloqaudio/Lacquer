local addonName, ns = ...

-- Paints through EllesmereUI's published Skinning API. EllesmereUI hands over
-- its primitives at login, and only when the user has skinning for Lacquer on.
local Ellesmere = { id = "ellesmereui", name = "EllesmereUI", ops = {} }
ns.EllesmereProvider = Ellesmere
local ops = Ellesmere.ops

local S

function Ellesmere.detect()
	local api = C_AddOns.IsAddOnLoaded("EllesmereUI") and _G.EllesmereUI
	return type(api) == "table" and type(api.RegisterSkin) == "function"
end

function Ellesmere.init(ready)
	Ellesmere.waiting = true
	_G.EllesmereUI.RegisterSkin(addonName, function(primitives)
		S = primitives
		Ellesmere.waiting = false
		ready()
	end)
end

function Ellesmere.theme()
	if not S then
		return nil
	end
	local theme = {}
	if S.GetPanelColor then
		local r, g, b, a = S.GetPanelColor()
		theme.panel = { r = r, g = g, b = b, a = a or 1 }
		theme.backdrop = theme.panel
	end
	if S.GetAccentColor then
		local r, g, b = S.GetAccentColor()
		theme.accent = { r = r, g = g, b = b, a = 1 }
	end
	if S.GetFont then
		theme.font = S.GetFont()
	end
	return theme
end

local function primitive(name)
	return function(object, ...)
		if not (S and S[name]) then
			return false
		end
		S[name](object, ...)
	end
end

ops.Window = primitive("Shell")
ops.Panel = primitive("Panel")
ops.Inset = primitive("Inset")
ops.CloseButton = primitive("CloseButton")
ops.Tab = primitive("Tab")
local checkbox = primitive("Checkbox")

-- The published Checkbox primitive has no way to name a box inside a wider
-- button, so those fall back to the standalone style.
function ops.CheckBox(check, box)
	if box then
		return false
	end
	return checkbox(check)
end
ops.EditBox = primitive("EditBox")
ops.Dropdown = primitive("Dropdown")
ops.ScrollBar = primitive("ScrollBar")
ops.StatusBar = primitive("ApplyBarFill")
ops.Font = primitive("Font")

function ops.Clear(frame)
	if not (S and S.FadeRegions) then
		return false
	end
	S.FadeRegions(frame)
	if frame.NineSlice and S.FadeNineSlice then
		S.FadeNineSlice(frame.NineSlice)
	end
end

function ops.Button(button, opts)
	if not (S and S.Button) then
		return false
	end
	S.Button(button, opts and opts.keep)
end

function ops.Icon(texture, parent)
	if not (S and S.SquareIcon) then
		return false
	end
	S.SquareIcon(texture, parent)
end

function ops.ItemButton(button)
	if S and S.ItemButton then
		S.ItemButton(button)
		return
	end
	local icon = button.icon or button.Icon
	if not (S and S.SquareIcon and icon) then
		return false
	end
	S.SquareIcon(icon, button, true)
end
