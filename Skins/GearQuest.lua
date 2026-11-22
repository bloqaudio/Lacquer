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

local MAX_UPGRADE_ICONS = 3
local PORTRAIT = "Interface\\AddOns\\GearQuestForever\\Art\\GearQuest-Portrait"
local PORTRAIT_CROP = 0.15

ns.RegisterSkin({
	id = "GearQuestForever",
	title = "GearQuest Forever",
	editions = "modern",
	apply = function(skin, P)
		local GQ = _G.GearQuest
		assert(GQ and GQ.Log, "this GearQuest has no log module")

		-- GearQuest sets its backdrops again whenever it lays a panel out, so the
		-- suite's sits on a frame of its own and GearQuest's is cleared each time.
		local covered = setmetatable({}, { __mode = "k" })
		local function cover(frame)
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
			-- Opaque and under the panel's own text: these panels cover the list.
			local box = CreateFrame("Frame", nil, frame)
			box:SetAllPoints(frame)
			box:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
			P.Panel(box)
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
					cover(frame)
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
			ns.Walk(frame, styleControl)
			stylePanels()
		end

		skin:Hook(GQ.Log, "Show", styleWindow)
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
