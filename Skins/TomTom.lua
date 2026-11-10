local _, ns = ...

local ARROW_TEXT = { "title", "status", "tta" }

ns.RegisterSkin({
	id = "TomTom",
	apply = function(skin, P)
		-- The arrow's art is TomTom's own theme; only its text follows the suite.
		local arrow = _G.TomTomCrazyArrow
		if arrow then
			for _, key in ipairs(ARROW_TEXT) do
				P.Font(arrow[key])
			end
		end

		-- TomTom recolours the block's own backdrop every time it shows it, so
		-- that backdrop is cleared and the suite's is drawn behind it instead.
		local function styleBlock()
			local block = _G.TomTomBlock
			if block then
				P.Clear(block)
				P.Backdrop(block)
				P.Font(block.Text)
			end
		end

		skin:Hook(_G.TomTom, "ShowHideCoordBlock", styleBlock)
		styleBlock()

		-- TomTom keeps its settings pages private. Each is a canvas page with
		-- its own settings list, recognised here by TomTom's page fields.
		local panel = _G.SettingsPanel
		if panel then
			skin:Hook(panel, "DisplayLayout", function(_, layout)
				local page = layout and type(layout.GetFrame) == "function" and layout:GetFrame()
				if page and page.List and page.onPage and page.Redisplay then
					ns.StyleSettingsList(skin, page.List)
				end
			end)
		end
	end,
})
