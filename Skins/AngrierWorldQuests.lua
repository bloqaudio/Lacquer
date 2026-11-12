local _, ns = ...

local PANE_ATLAS = "questlog-main-background"
local ID = "AngrierWorldQuests"

local boxes = setmetatable({}, { __mode = "k" })

-- The row's track box is a plain frame, not a check button: its square art
-- gives way to a backdrop, and the yellow tick AWQ toggles stays on top.
local function styleTrackBox(P, box)
	if not box or boxes[box] then
		return
	end
	boxes[box] = true
	for _, region in ipairs({ box:GetRegions() }) do
		if region ~= box.CheckMark and region:IsObjectType("Texture") then
			region:SetAlpha(0)
		end
	end
	P.Backdrop(box)
end

ns.RegisterSkin({
	id = ID,
	title = "Angrier World Quests",
	editions = "modern",
	apply = function(skin, P)
		local addon = _G.AngrierWorldQuests
		local module = addon and addon:GetModule("QuestFrameModule", true)

		-- The list pane carries the same art as the quest log's own pane, so
		-- it copies whatever the suite did to that pane each time it shows.
		local function matchQuestPane(background, border)
			local own = _G.QuestScrollFrame
			if background and own and own.Background then
				background:SetAlpha(own.Background:GetAlpha())
				background:SetVertexColor(own.Background:GetVertexColor())
			end
			if border and own and own.BorderFrame then
				border:SetAlpha(own.BorderFrame:GetAlpha())
			end
		end

		local styled
		local function styleList()
			local panel = _G.AngrierWorldQuestsPanel
			local scroll = _G.AngrierWorldQuestsScrollFrame
			if styled or not (panel and scroll) then
				return
			end
			styled = true

			P.ScrollBar(scroll.ScrollBar)
			P.Window(_G.AngrierWorldQuestsWindowPanel)

			local background, border
			for _, region in ipairs({ scroll:GetRegions() }) do
				local atlas = region.GetAtlas and region:GetAtlas()
				if atlas and atlas:lower() == PANE_ATLAS then
					background = region
				end
			end
			for _, child in ipairs({ panel:GetChildren() }) do
				if child.Border and child.TopDetail then
					border = child
				end
			end
			matchQuestPane(background, border)
			panel:HookScript("OnShow", function()
				skin:Call(matchQuestPane, background, border)
			end)

			local header = _G.AngrierWorldQuestsHeader
			if header then
				P.Button(header)
				local rows = header.titleFramePool
				if rows then
					skin:Hook(rows, "Acquire", function(pool)
						for row in pool:EnumerateActive() do
							styleTrackBox(P, row.Checkbox)
						end
					end)
				end
			end

			local questMap = _G.QuestMapFrame
			for _, tab in ipairs(questMap and questMap.TabButtons or {}) do
				if tab.displayMode == panel.displayMode then
					P.SideTab(tab, questMap.QuestsTab)
				end
			end
		end

		if module then
			-- AWQ builds its frames when it enables, which can follow this skin.
			skin:Hook(module, "InitQuestLogFrames", styleList)
			-- Its tooltip is built on first use.
			skin:Hook(module, "Tooltip_Show", function()
				P.Window(_G.AWQTooltip)
			end)
		end
		styleList()
		P.Window(_G.AWQTooltip)

		-- AWQ builds its options page the first time the page is shown.
		local settings = _G.SettingsPanel
		if settings then
			skin:Hook(settings, "DisplayLayout", function(_, layout)
				local category = Settings.GetCategory(ID)
				if not (category and layout and settings:GetLayout(category) == layout) then
					return
				end
				ns.Walk(layout:GetFrame(), function(child)
					if ns.IsDropdown(child) then
						P.Dropdown(child)
						return false
					elseif child:IsObjectType("CheckButton") then
						P.CheckBox(child)
					end
				end)
			end)
		end
	end,
})
