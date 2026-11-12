local _, ns = ...

local TITLE = "TomCat's Tours"

-- The timers window is unnamed and kept private, so it is found among
-- UIParent's children by its title. TomCats builds it on entering the world.
local function findTimers()
	for _, child in ipairs({ UIParent:GetChildren() }) do
		local title = child.title
		if child.headerBar and title and title.GetText and title:GetText() == TITLE then
			return child
		end
	end
end

ns.RegisterSkin({
	id = "TomCats",
	apply = function(skin, P)
		local events = CreateFrame("Frame")

		local function style()
			local window = findTimers()
			if window then
				events:UnregisterAllEvents()
				P.Window(window)
			end
		end

		events:RegisterEvent("PLAYER_ENTERING_WORLD")
		events:SetScript("OnEvent", function()
			C_Timer.After(0, function()
				skin:Call(style)
			end)
		end)
		style()
	end,
})
