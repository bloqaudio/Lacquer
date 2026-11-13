local _, ns = ...

-- Art drawn by BasicFrameTemplateWithInset and Angleur's dialog-border popups.
-- Any other texture on such a frame is Angleur's own and stays.
local FRAME_ART = {
	"TopLeftCorner", "TopRightCorner", "TopBorder", "BotLeftCorner", "BotRightCorner", "BottomBorder",
	"LeftBorder", "RightBorder", "Bg", "TitleBg", "TopTileStreaks", "InsetBg",
	"InsetBorderTopLeft", "InsetBorderTopRight", "InsetBorderBottomLeft", "InsetBorderBottomRight",
	"InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
	"BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

-- Created outside the config panel, some only on first use.
local WINDOWS = {
	"Angleur_PlaterFrame", "Angleur_AdvancedAnglingPanel", "Angleur_BobberScanner_Disclaimer",
	"Angleur_HelpTip_CloseWarning",
}

local function ownArt(frame)
	local template = {}
	for _, key in ipairs(FRAME_ART) do
		if frame[key] then
			template[frame[key]] = true
		end
	end
	local keep = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") and not template[region] then
			keep[#keep + 1] = region
		end
	end
	return keep
end

local function isWindow(frame)
	return (frame.TitleBg and frame.CloseButton) or (frame.TopEdge and frame.BottomEdge and frame.Bg)
end

local function isCloseButton(button)
	local parent = button:GetParent()
	if parent and (parent.CloseButton == button or parent.closeButton == button) then
		return true
	end
	local normal = button:GetNormalTexture()
	local atlas = normal and normal:GetAtlas()
	return atlas ~= nil and atlas:lower():find("redbutton%-exit") ~= nil
end

-- Art drawn on an edit box moves to a child frame, out of reach of stripping.
local function lift(region)
	local holder = CreateFrame("Frame", nil, region:GetParent())
	holder:SetAllPoints()
	region:SetParent(holder)
end

ns.RegisterSkin({
	id = "Angleur",
	editions = "modern",
	apply = function(skin, P)
		local panel = _G.Angleur and _G.Angleur.configPanel
		assert(panel, "this Angleur has no config panel")

		-- Action-button slots: the fishing methods and the extra item slots.
		local function styleSlot(button)
			P.ItemButton(button)
			for _, key in ipairs({ "SlotBackground", "SlotArt" }) do
				if button[key] then
					button[key]:SetAlpha(0)
				end
			end
		end

		local function styleButton(button)
			if isCloseButton(button) then
				P.CloseButton(button)
			elseif button.IconMask or button.SlotBackground then
				styleSlot(button)
			elseif button.tabText or button.LeftActive then
				P.Tab(button)
			elseif (button.Left and button.Middle and button.Right) or (button.TopLeft and button.MiddleLeft) then
				P.Button(button)
			-- IconButtonTemplate keeps a file path in .icon; square buttons keep a texture.
			elseif type(button.icon) == "table" and button:GetNormalTexture() then
				P.Button(button, { keep = { "icon" } })
			end
		end

		local function styleControl(child)
			if child:IsObjectType("GameTooltip") or (child.Arrow and child.OkayButton) then
				-- The tutorial's glow box keeps Blizzard's tutorial look.
				return false
			elseif isWindow(child) then
				P.Window(child, { keep = ownArt(child) })
			elseif child.Track and child.Back and child.Forward then
				P.ScrollBar(child)
				return false
			elseif child.Slider and child.ValueBox then
				P.Slider(child.Slider)
				P.EditBox(child.ValueBox)
				return false
			elseif ns.IsDropdown(child) then
				P.Dropdown(child)
				return false
			elseif child:GetObjectType() == "Frame" and child.Left and child.Middle and child.Right and child.Button then
				P.Dropdown(child)
				return false
			elseif child:IsObjectType("CheckButton") then
				if child:GetParent().checkbox == child then
					P.CheckBox(child)
				end
			elseif child:IsObjectType("EditBox") then
				if child.Left and child.Middle and child.Right then
					if child.logo then
						lift(child.logo)
					end
					P.EditBox(child)
				end
			elseif child:IsObjectType("Button") then
				styleButton(child)
			end
		end

		local function styleTree(frame)
			ns.Walk(frame, styleControl)
		end

		local function styleWindow(frame)
			P.Window(frame, { keep = ownArt(frame) })
			styleTree(frame)
		end

		local watched = setmetatable({}, { __mode = "k" })
		local function watchWindows()
			for _, name in ipairs(WINDOWS) do
				local frame = _G[name]
				if frame and not watched[frame] then
					watched[frame] = true
					frame:HookScript("OnShow", function(self)
						skin:Call(styleWindow, self)
					end)
					if frame:IsShown() then
						styleWindow(frame)
					end
				end
			end
		end

		-- Buttons whose own picture is the button; only the frame art goes.
		local function stylePictureButtons()
			if panel.wakeUpButton then
				P.Button(panel.wakeUpButton, { keep = { "lego" } })
			end
			local thanks = _G.Angleur_ThanksButton
			if thanks then
				P.Button(thanks, { keep = { "texture" } })
			end
			local set = _G.Angleur_CreateSetAndAdd
			if set then
				P.Button(set, { keep = { "defaultTexture", "checkedTexture" } })
				-- Its press handler sets these textures again by name.
				local name = set:GetName()
				for _, part in ipairs({ "Left", "Middle", "Right" }) do
					local texture = _G[name .. part]
					if texture then
						texture:SetAlpha(0)
					end
				end
			end
		end

		-- The tabs fill in their controls at login and on first use, so every
		-- opening walks the panel again; each paint runs once per control.
		local function styleConfig()
			P.Window(panel, { keep = ownArt(panel) })
			stylePictureButtons()
			styleTree(panel)
			watchWindows()
		end

		panel:HookScript("OnShow", function()
			skin:Call(styleConfig)
		end)
		if panel:IsShown() then
			styleConfig()
		end
		watchWindows()
	end,
})
