local _, ns = ...

local BUTTONS = { "BugSackPrevButton", "BugSackNextButton", "BugSackSendButton", "BugSackWipeButton" }
local TABS = { "BugSackTabAll", "BugSackTabSession", "BugSackTabLast", "BugSackTabOptions" }

ns.RegisterSkin({
	id = "BugSack",
	apply = function(skin, P)
		local BugSack = _G.BugSack
		local styled

		-- BugSack builds its window the first time it opens.
		local function style()
			local window = _G.BugSackFrame
			if styled or not window then
				return
			end
			styled = true

			P.Window(window)
			P.CloseButton(window.CloseButton)
			for _, name in ipairs(BUTTONS) do
				P.Button(_G[name])
			end
			for _, name in ipairs(TABS) do
				P.Tab(_G[name])
			end

			ns.Walk(window, function(child)
				if child:IsObjectType("ScrollFrame") then
					P.ScrollBar(child.ScrollBar)
				elseif child:IsObjectType("CheckButton") then
					P.CheckBox(child)
				elseif child:IsObjectType("EditBox") then
					if child ~= _G.BugSackScrollText then
						P.EditBox(child)
					end
				elseif ns.IsDropdown(child) then
					P.Dropdown(child)
					return false
				elseif child:IsObjectType("Button") and child:GetScript("OnClick") == BugSack.CloseSack then
					-- The Classic window has an unnamed close button.
					P.CloseButton(child)
				end
			end)
		end

		skin:Hook(BugSack, "OpenSack", style)
		skin:Hook(BugSack, "OpenConfig", style)
		style()
	end,
})
