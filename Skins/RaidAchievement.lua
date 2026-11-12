local _, ns = ...

local MODULE_PREFIX = "RaidAchievement_"

-- A legacy UIDropDownMenuTemplate frame.
local function isLegacyDropdown(frame)
	return frame.Button and frame.Text and frame.Left and frame.Middle and frame.Right and not frame:IsObjectType("Button")
end

-- UIPanelButtonGrayTemplate draws whole-button textures, not three pieces;
-- RaidAchievement names those buttons with a G before any number.
local function isPanelButton(button)
	if button.Left and button.Middle and button.Right then
		return true
	end
	local name = button:GetName()
	return name ~= nil and name:find("_Button%a*G%d*$") ~= nil
end

ns.RegisterSkin({
	id = "RaidAchievement",
	apply = function(skin, P)
		local window = _G.PSFeamain1
		assert(window, "this RaidAchievement has no main window")

		-- Some panels set their text MONOCHROME, which renders it unsmoothed.
		local function styleText(frame)
			for _, region in ipairs({ frame:GetRegions() }) do
				if region:IsObjectType("FontString") then
					local _, _, flags = region:GetFont()
					if flags and flags:find("MONOCHROME") then
						P.Font(region)
					end
				end
			end
		end

		local function styleControl(child)
			styleText(child)
			local parent = child:GetParent()
			if parent and parent.background == child then
				-- Every panel draws its tooltip border on a child frame; the
				-- suite's backdrop goes on the panel instead.
				P.Clear(child)
				P.Backdrop(parent)
			elseif ns.IsDropdown(child) or isLegacyDropdown(child) then
				P.Dropdown(child)
				return false
			elseif child:IsObjectType("ScrollFrame") then
				P.ScrollBar(child.ScrollBar)
			elseif child:IsObjectType("Slider") then
				if not (parent and parent.ScrollBar == child) then
					P.Slider(child)
				end
			elseif child:IsObjectType("CheckButton") then
				P.CheckBox(child)
			elseif child:IsObjectType("Button") and isPanelButton(child) then
				P.Button(child)
			end
		end

		-- Panels, the module ones included, are children of the main window
		-- and fill in their controls as they show.
		local watched = setmetatable({}, { __mode = "k" })
		local styleAll

		local function watchPanels()
			for _, panel in ipairs({ window:GetChildren() }) do
				if not watched[panel] then
					watched[panel] = true
					panel:HookScript("OnShow", function()
						skin:Call(styleAll)
						C_Timer.After(0, function()
							skin:Call(styleAll)
						end)
					end)
				end
			end
		end

		styleAll = function()
			watchPanels()
			ns.Walk(window, styleControl)
		end

		-- Each module loads on demand the first time its button is clicked.
		local events = CreateFrame("Frame")
		events:RegisterEvent("ADDON_LOADED")
		events:SetScript("OnEvent", function(_, _, name)
			if name:sub(1, #MODULE_PREFIX) == MODULE_PREFIX then
				skin:Call(styleAll)
			end
		end)

		window:HookScript("OnShow", function()
			skin:Call(styleAll)
		end)
		styleAll()
	end,
})
