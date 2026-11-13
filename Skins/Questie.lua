local _, ns = ...

-- Questie shows, hides, and fades the tracker background and the auto-complete
-- popup by recolouring their own backdrops, so the suite's backdrop follows
-- that colour's alpha. The suite's border comes with it, whatever Questie's
-- border setting says.
local function followBackdrop(P, frame)
	P.Clear(frame)
	local box = CreateFrame("Frame", nil, frame)
	box:SetAllPoints(frame)
	box:SetFrameLevel(frame:GetFrameLevel())
	P.Backdrop(box)
	local function follow()
		local _, _, _, alpha = frame:GetBackdropColor()
		box:SetAlpha(alpha or 0)
	end
	hooksecurefunc(frame, "SetBackdropColor", follow)
	follow()
end

-- Questie's own button control draws three slices from these atlases.
local function hasRedButtonArt(button)
	for _, region in ipairs({ button:GetRegions() }) do
		local atlas = region.GetAtlas and region:GetAtlas()
		if atlas and atlas:find("RedButton", 1, true) then
			return true
		end
	end
	return false
end

-- Each options tab is a canvas named QuestieOptionsTab_<window>_<tab>. Its
-- scroll frames share that prefix, so the canvas is the one carrying its tab.
local function canvasOf(frame)
	while frame and frame ~= UIParent do
		local name = frame:GetName()
		if name and name:find("^QuestieOptionsTab_") and frame.tab then
			return frame
		end
		frame = frame:GetParent()
	end
end

ns.RegisterSkin({
	id = "Questie",
	apply = function(skin, P)
		local loader = _G.QuestieLoader
		assert(loader and loader.ImportModule, "this Questie has no module loader")

		local done = {}
		local function once(key, fn)
			return function()
				if not done[key] then
					done[key] = true
					fn()
				end
			end
		end

		local styleBase = once("base", function()
			followBackdrop(P, _G.Questie_BaseFrame)
		end)
		local styleQuests = once("quests", function()
			local scroll = _G.TrackedQuestsScrollFrame
			P.ScrollBar(scroll and scroll.ScrollBar)
		end)
		local stylePopup = once("popup", function()
			followBackdrop(P, _G.Questie_AutoComplete_Frame)
		end)

		-- QuestieTracker.Initialize yields part way through (its line pool is
		-- built across frames), and a hook around a yielding function breaks
		-- it. The pieces it calls to build these frames don't yield. Some only
		-- load on some clients: the auto-complete popup is Cata-era and later.
		local function hookInitialize(name, fn)
			local module = loader:ImportModule(name)
			if type(module.Initialize) == "function" then
				skin:Hook(module, "Initialize", fn)
			end
		end
		hookInitialize("TrackerBaseFrame", styleBase)
		hookInitialize("TrackerQuestFrame", styleQuests)
		hookInitialize("AutoCompleteFrame", stylePopup)

		if _G.Questie_BaseFrame then
			styleBase()
		end
		if _G.TrackedQuestsScrollFrame then
			styleQuests()
		end
		if _G.Questie_AutoComplete_Frame then
			stylePopup()
		end

		-- /questie opens Questie's own window, with icon tabs down its side.
		local window = loader:ImportModule("QuestieOptionsWindow")
		if type(window.Create) == "function" then
			skin:Hook(window, "Create", function()
				P.Window(_G.QuestieStandaloneSettings)
			end)
		end
		if type(window.CreateSideTab) == "function" then
			skin:Hook(window, "CreateSideTab", function(frame, key)
				local tab = _G[frame:GetName() .. "_Tab_" .. key]
				if not tab then
					return
				end
				-- The selection ring is round; the selected tab shows by its
				-- brighter icon, which Questie keeps doing.
				tab.Background:SetAlpha(0)
				tab.Selected:SetAlpha(0)
				ns.Unmask(tab.Icon)
				P.Icon(tab.Icon, tab)
				-- The hover art is shaped and sized for the round tab, not the
				-- squared icon; it follows the icon when a press nudges it.
				local highlight = tab.Highlight
				if highlight then
					highlight:ClearAllPoints()
					highlight:SetAllPoints(tab.Icon)
					highlight:SetColorTexture(1, 1, 1, 0.2)
				end
			end)
		end

		-- The options pages are built a control at a time, out of sight in a
		-- thread that yields between controls, so each control is styled as
		-- QuestieOptionsControls.Create (which doesn't yield) returns it.
		local controls = loader:ImportModule("QuestieOptionsControls")
		if type(controls.Create) == "function" then
			local function styleControl(child)
				if ns.IsDropdown(child) then
					P.Dropdown(child)
					return false
				elseif child.swatch then
					P.Swatch(child, child.swatch)
					return false
				elseif child:IsObjectType("CheckButton") then
					P.CheckBox(child)
				elseif child:IsObjectType("Slider") then
					P.Slider(child)
				elseif child:IsObjectType("EditBox") then
					if child.Left and child.Middle and child.Right then
						P.EditBox(child)
					end
				elseif child:IsObjectType("Button") then
					if (child.Left and child.Middle and child.Right) or hasRedButtonArt(child) then
						P.Button(child)
					end
				elseif child.TopLeftCorner and not child.backdropInfo then
					-- The NineSlice box around a group of settings. A backdrop keeps
					-- its pieces under the same keys, so the suite's goes on a frame
					-- of its own behind the box rather than on the box itself.
					P.Clear(child)
					local box = CreateFrame("Frame", nil, child)
					box:SetAllPoints(child)
					box:SetFrameLevel(child:GetFrameLevel())
					P.Backdrop(box)
					return false
				end
			end

			skin:Hook(controls, "Create", function(parent)
				local newest = select(parent:GetNumChildren(), parent:GetChildren())
				if newest then
					ns.Walk(newest, styleControl)
				end
				local canvas = canvasOf(parent)
				if canvas then
					P.ScrollBar(_G[canvas:GetName() .. "_ScrollScrollBar"])
				end
			end)
		end
	end,
})
