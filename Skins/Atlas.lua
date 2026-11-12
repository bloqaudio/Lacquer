local _, ns = ...

-- Atlas has a full window and a compact one; each has its own controls.
local WINDOWS = { "AtlasFrame", "AtlasFrameSmall" }
local ARROWS = { PrevMap = "left", NextMap = "right" }

local AQ_CLOSE = { "AQ_SidebarClose", "AQ_QuestClose" }
local AQ_BUTTONS = { "AQ_OptionsButton", "AQ_AtlasToggle" }
local AQ_CHECKS = { "AQ_AllianceCheck", "AQ_HordeCheck", "AQ_FinishedQuestCheck" }
local AQ_REWARDS = 6

ns.RegisterSkin({
	id = "Atlas",
	apply = function(skin, P)
		local function styleControl(child)
			if ns.IsDropdown(child) then
				P.Dropdown(child)
				return false
			elseif child.Track and child.Back and child.Forward then
				P.ScrollBar(child)
				return false
			elseif child.NineSlice and child.Bg then
				-- The map, info, and boss list insets. The map is drawn on its
				-- inset itself, where a backdrop would cover it.
				P.Inset(child)
				if child ~= child:GetParent().MapFrame then
					P.Backdrop(child)
				end
			elseif not (child.Left and child.Middle and child.Right) then
				return
			elseif child:IsObjectType("EditBox") then
				P.EditBox(child)
			elseif child:IsObjectType("Button") then
				P.Button(child)
			end
		end

		-- The dropdowns are added after the windows load, so each opening
		-- looks again.
		local function styleWindow(window)
			P.Window(window)
			ns.Walk(window, styleControl)
			local arrows = _G[window:GetName() .. "PrevNextContainer"]
			for key, direction in pairs(ARROWS) do
				P.ArrowButton(arrows and arrows[key], direction)
			end
		end

		for _, name in ipairs(WINDOWS) do
			local window = _G[name]
			if window then
				window:HookScript("OnShow", function(self)
					skin:Call(styleWindow, self)
				end)
				styleWindow(window)
			end
		end
	end,
})

ns.RegisterSkin({
	id = "AtlasQuest",
	apply = function(skin, P)
		-- Reward icons wear Blizzard's round-cornered quality frame. AtlasQuest
		-- builds the rewards when it enables, which can follow this skin.
		local function styleRewards()
			for i = 1, AQ_REWARDS do
				local item = _G["AQ_QuestItem_" .. i]
				if item and item.icon then
					P.Icon(item.icon)
					ns.FrameIcon(item, item.icon, item.qualityBorder)
				end
			end
		end
		if _G.AQ_QuestItem_1 then
			styleRewards()
		elseif _G.AtlasQuest then
			skin:Hook(_G.AtlasQuest, "OnEnable", styleRewards)
		end

		-- The faction emblems are drawn on the panel itself.
		P.Window(_G.AtlasQuestFrame, { keep = { _G.AQ_AllianceTexture, _G.AQ_HordeTexture } })
		for _, name in ipairs(AQ_CLOSE) do
			P.CloseButton(_G[name])
		end
		for _, name in ipairs(AQ_BUTTONS) do
			P.Button(_G[name])
		end
		for _, name in ipairs(AQ_CHECKS) do
			P.CheckBox(_G[name])
		end
	end,
})
