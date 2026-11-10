local _, ns = ...

local CHECKBOXES = { "AutomaticClose", "SimcOffspecLoadouts" }

ns.RegisterSkin({
	id = "Simulationcraft",
	apply = function(skin, P)
		-- The export window is built the first time a profile is printed.
		local function style()
			local window = _G.SimcFrame
			if not window then
				return
			end
			P.Window(window)
			P.Button(_G.SimcFrameButton)
			local scroll = _G.SimcScrollFrame
			P.ScrollBar(scroll and (scroll.ScrollBar or _G.SimcScrollFrameScrollBar))
			for _, name in ipairs(CHECKBOXES) do
				P.CheckBox(_G[name])
			end
		end

		-- The addon object is local to Simulationcraft; AceAddon hands it out.
		local simc = LibStub("AceAddon-3.0"):GetAddon("Simulationcraft")
		skin:Hook(simc, "GetMainFrame", style)
		style()
	end,
})
