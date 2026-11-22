local _, ns = ...

-- Menus and panels GearQuest parents outside its window, some built on first use.
local PANELS = {
	"GearQuestSourceFilterMenu", "GearQuestProfessionFilterBranch", "GearQuestVendorFilterBranch",
	"GearQuestQuestFilterBranch", "GearQuestDungeonFilterBranch", "GearQuestTrashFilterBranch",
	"GearQuestArmorMenu", "GearQuestWeaponMenu", "GearQuestPlayStylePanel", "GearQuestTooltipsPanel",
	"GearQuestUnitGearSourcesMenu", "GearQuestLanguageMenu", "GearQuestSpecPicker", "GearQuestSlotRankPanel",
	"GearQuestCustomSpecPanel", "GearQuestCustomSpecMenu",
}

-- Public methods that build, open or refill one of those panels.
local LOG_OPENERS = {
	"ToggleSourceFilterMenu", "PopulateProfessionBranch", "PopulateVendorBranch", "PopulateQuestBranch",
	"PopulateDungeonBranch", "PopulateTrashBranch", "ShowArmorMenu", "FillArmorMenu", "ShowWeaponMenu",
	"ShowRangedMenu", "FillWeaponMenu", "FillRangedMenu", "TogglePlayStylePanel", "ToggleTooltipsPanel",
	"MountTooltipsPanelSettings", "ToggleSpecPicker", "RefreshSpecPickerRows", "ShowSlotRankTooltip",
}
local CUSTOM_OPENERS = { "ShowEditor", "ToggleBaseMenu" }
local PAGE_BUILDERS = { "SetPageTab", "ShowLookupResults", "ShowLookupDetail" }

local MAX_UPGRADE_ICONS = 3
local PORTRAIT = "Interface\\AddOns\\GearQuestForever\\Art\\GearQuest-Portrait"
local PORTRAIT_CROP = 0.15
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local LIST_TABS = { "tabActive", "tabCompleted", "tabRemoved", "tabTracked" }
local SIDE_TABS = { "tabLog", "tabLookup", "tabSimulator", "tabSettings" }

ns.RegisterSkin({
	id = "GearQuestForever",
	title = "GearQuest Forever",
	editions = "modern",
	apply = function(skin, P)
		local GQ = _G.GearQuest
		assert(GQ and GQ.Log, "this GearQuest has no log module")

		-- GearQuest sets its backdrops again whenever it lays a panel out, so the
		-- suite's sits on a frame of its own and GearQuest's is cleared each time.
		-- kind "panel" is opaque, for panels that cover the list; "edge" is a
		-- border around a pane whose own art fills it, so it sits just outside.
		local covered = setmetatable({}, { __mode = "k" })
		local function cover(frame, kind)
			if covered[frame] or not frame.ClearBackdrop then
				return
			end
			covered[frame] = true
			frame:ClearBackdrop()
			hooksecurefunc(frame, "SetBackdrop", function(self, info)
				if info then
					self:ClearBackdrop()
				end
			end)
			local box = CreateFrame("Frame", nil, frame)
			if kind == "edge" then
				box:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
				box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
			else
				box:SetAllPoints(frame)
			end
			-- Under the frame's own text and art.
			box:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
			if kind == "panel" then
				P.Panel(box)
			else
				P.Backdrop(box)
			end
		end

		local function isMetalEdge(frame)
			local info = frame.backdropInfo
			return info and info.edgeFile == METAL_EDGE and not info.bgFile
		end

		-- Some sliders get GearQuest's thumb art back each time their panel
		-- opens, so the suite's thumb is put back after it.
		local thumbs = setmetatable({}, { __mode = "k" })
		local function keepThumb(slider)
			local thumb = slider:GetThumbTexture()
			if thumb and not thumbs[slider] then
				local r, g, b, a = thumb:GetVertexColor()
				local width, height = thumb:GetSize()
				thumbs[slider] = { thumb, thumb:GetTexture(), r, g, b, a, width, height }
			end
		end
		local function restoreThumb(slider)
			local saved = slider and thumbs[slider]
			if not saved then
				return
			end
			local thumb, texture, r, g, b, a, width, height = unpack(saved)
			if texture then
				thumb:SetTexture(texture)
			end
			thumb:SetVertexColor(r, g, b, a)
			thumb:SetSize(width, height)
		end

		local function styleControl(child)
			if isMetalEdge(child) then
				cover(child, "edge")
			end
			if child:IsObjectType("ScrollFrame") then
				P.ScrollBar(child.ScrollBar)
			elseif child:IsObjectType("Slider") then
				-- A scroll frame's own bar is a slider too.
				if not child:GetParent():IsObjectType("ScrollFrame") then
					P.Slider(child)
					keepThumb(child)
				end
				return false
			elseif child:IsObjectType("CheckButton") then
				P.CheckBox(child)
			elseif child:IsObjectType("EditBox") then
				if child.Left and child.Middle and child.Right then
					P.EditBox(child)
				end
			elseif child:IsObjectType("Button") then
				if child.Left and child.Middle and child.Right then
					P.Button(child)
				end
			end
		end

		local function stylePanels()
			for _, name in ipairs(PANELS) do
				local frame = _G[name]
				if frame then
					cover(frame, "panel")
					ns.Walk(frame, styleControl)
				end
			end
		end

		-- The window style drops the round portrait, but clicking it replays the
		-- guide, so the face goes back square on GearQuest's click area.
		local portrait
		local function stylePortrait()
			local hit = GQ.PortraitGuide and GQ.PortraitGuide.hit
			if portrait or not hit then
				return
			end
			portrait = hit:CreateTexture(nil, "ARTWORK")
			portrait:SetAllPoints(hit)
			portrait:SetTexture(PORTRAIT)
			-- The art is stored upside down; this is the square inside its circle.
			portrait:SetTexCoord(PORTRAIT_CROP, 1 - PORTRAIT_CROP, 1 - PORTRAIT_CROP, PORTRAIT_CROP)
			ns.FrameIcon(hit, portrait)
		end

		local function styleTabs()
			local frame = GQ.Log.frame
			if not frame then
				return
			end
			for _, list in ipairs({ LIST_TABS, SIDE_TABS }) do
				for _, key in ipairs(list) do
					local tab = frame[key]
					if tab then
						cover(tab, "tab")
						-- A strip in the tab's fill colour that opens one side into the pane.
						if tab.gqOpenCover then
							tab.gqOpenCover:SetAlpha(0)
						end
					end
				end
			end
		end

		local function styleWindow()
			local frame = GQ.Log.frame
			if not frame then
				return
			end
			stylePortrait()
			P.Window(frame, { keep = { "gqLogScene", "gqLogSceneShade" } })
			P.CloseButton(frame.CloseButton)
			-- Each opening puts the metal border back.
			if frame.NineSlice then
				frame.NineSlice:Hide()
			end
			-- Panels first: some carry the same edge the walk turns into a border.
			stylePanels()
			ns.Walk(frame, styleControl)
			styleTabs()
		end

		skin:Hook(GQ.Log, "Show", styleWindow)
		-- Pages and lookup panes are built the first time they are shown.
		for _, method in ipairs(PAGE_BUILDERS) do
			if type(GQ.Log[method]) == "function" then
				skin:Hook(GQ.Log, method, styleWindow)
			end
		end
		for _, method in ipairs({ "UpdateTabVisuals", "LayoutSideTabs" }) do
			if type(GQ.Log[method]) == "function" then
				skin:Hook(GQ.Log, method, styleTabs)
			end
		end
		-- Copies of the list's top edge, split around the selected tab.
		if type(GQ.Log.LayoutListTopOpening) == "function" then
			skin:Hook(GQ.Log, "LayoutListTopOpening", function()
				local list = GQ.Log.frame and GQ.Log.frame.listInset
				if list and list.gqTopLeft then
					list.gqTopLeft:SetAlpha(0)
					list.gqTopRight:SetAlpha(0)
				end
			end)
		end
		-- The tooltips panel's thin scroll thumbs.
		local slimThumbs = setmetatable({}, { __mode = "k" })
		if type(GQ.Log.UpdateTooltipsSlimScrollBar) == "function" then
			skin:Hook(GQ.Log, "UpdateTooltipsSlimScrollBar", function(_, scroll)
				local thumb = scroll and scroll.gqSlimThumb
				local theme = ns.Theme()
				if thumb and theme and not slimThumbs[thumb] then
					slimThumbs[thumb] = true
					thumb:SetColorTexture(theme.accent.r, theme.accent.g, theme.accent.b, 1)
				end
			end)
		end
		-- List rows, each with a track checkbox, are added as the list refills.
		skin:Hook(GQ.Log, "Refresh", function()
			local list = GQ.Log.frame and GQ.Log.frame.scrollChild
			if list then
				ns.Walk(list, styleControl)
			end
		end)
		for _, method in ipairs(LOG_OPENERS) do
			if type(GQ.Log[method]) == "function" then
				skin:Hook(GQ.Log, method, stylePanels)
			end
		end
		if type(GQ.Log.StyleTooltipsPanelMinDropSlider) == "function" then
			skin:Hook(GQ.Log, "StyleTooltipsPanelMinDropSlider", function(_, slider)
				restoreThumb(slider)
			end)
		end
		if GQ.Custom then
			for _, method in ipairs(CUSTOM_OPENERS) do
				if type(GQ.Custom[method]) == "function" then
					skin:Hook(GQ.Custom, method, stylePanels)
				end
			end
		end
		if GQ.Log.frame and GQ.Log.frame:IsShown() then
			styleWindow()
		end

		-- The upgrade choices a right-click on a character slot shows.
		local framed = {}
		local function styleUpgradeIcons()
			for i = 1, MAX_UPGRADE_ICONS do
				local button = _G["GearQuestUpgradeIcon" .. i]
				if button and button.icon and button.border and not framed[button] then
					framed[button] = true
					-- The border frame sits under the icon, so lift the icon
					-- clear of the bar's background.
					button:SetFrameLevel(button:GetParent():GetFrameLevel() + 3)
					button.bg:SetAlpha(0)
					P.Icon(button.icon)
					ns.FrameIcon(button, button.icon, button.border)
				end
			end
		end
		if GQ.Popup and type(GQ.Popup.ShowForSlot) == "function" then
			skin:Hook(GQ.Popup, "ShowForSlot", styleUpgradeIcons)
		end
	end,
})
