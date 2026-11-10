local _, ns = ...

ns.RegisterSkin({
	id = "DBM-GUI",
	title = "DBM options",
	apply = function(skin, P)
		local window = _G.DBM_GUI_OptionsFrame
		local name = window:GetName()
		local tabs = {}

		local function styleTab(index)
			local tab = _G[name .. "Tab" .. index]
			if tab then
				tabs[tab] = true
				P.Tab(tab)
			end
		end

		-- DBM tags its own widgets with mytype; everything else is a stock
		-- Blizzard template.
		local function styleWidget(child)
			local kind = child.mytype
			if tabs[child] then
				return
			elseif ns.IsDropdown(child) then
				P.Dropdown(child)
				return false
			elseif kind == "area" or kind == "ability" then
				P.Panel(child)
			elseif kind == "slider" then
				P.Slider(child)
			elseif child:IsObjectType("CheckButton") then
				P.CheckBox(child)
			elseif child:IsObjectType("EditBox") then
				P.EditBox(child)
			elseif child:IsObjectType("ScrollFrame") then
				local childName = child:GetName()
				P.ScrollBar(child.ScrollBar or (childName and _G[childName .. "ScrollBar"]))
			elseif child:IsObjectType("Button") and child.Left and child.Middle and child.Right then
				P.Button(child)
			end
		end

		local function styleTree(root)
			ns.Walk(root, styleWidget)
		end

		P.Window(window)
		P.CloseButton(_G[name .. "ClosePanelButton"])
		for index = 1, #window.tabs do
			styleTab(index)
		end
		-- DBM's single tooltip-style border becomes one backdrop per column, so
		-- the list and the content area stay visible when a tab is empty. The
		-- columns are scroll frames, so the backdrops sit on frames behind them.
		local list = _G[name .. "List"]
		local wrapper = list:GetParent()
		P.Clear(wrapper)
		for _, column in ipairs({ list, _G[name .. "PanelContainer"] }) do
			local box = CreateFrame("Frame", nil, wrapper)
			box:SetFrameLevel(wrapper:GetFrameLevel())
			box:SetAllPoints(column)
			P.Backdrop(box)
		end
		local scrollBar = _G[name .. "PanelContainerFOVScrollBar"]
		for _, child in ipairs({ scrollBar:GetChildren() }) do
			if child.backdropInfo then
				P.Clear(child)
			end
		end
		styleTree(window)

		skin:Hook(window, "CreateTab", function()
			styleTab(#window.tabs)
		end)
		-- Boss mod panels are built the first time they are opened.
		skin:Hook(window, "DisplayFrame", function(_, target)
			styleTree(target)
		end)
	end,
})
