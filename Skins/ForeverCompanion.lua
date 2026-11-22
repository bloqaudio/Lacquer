local _, ns = ...

local function lighter(color, amount)
	return {
		r = math.min(color.r + amount, 1),
		g = math.min(color.g + amount, 1),
		b = math.min(color.b + amount, 1),
		a = 1,
	}
end

ns.RegisterSkin({
	id = "ForeverCompanion",
	title = "Forever Companion",
	editions = "modern",
	apply = function(skin, P)
		local APP = _G.ForeverCompanion
		assert(APP and APP.C and APP.BuildWindow, "this Forever Companion has no window")
		local C, theme = APP.C, ns.Theme()

		-- Every panel, row and edge is a flat texture tinted from this palette,
		-- and hover and selection retint from it too, so the suite's colours go
		-- in before the window is built. Text colours stay.
		local function set(key, color, alpha)
			local entry = C[key]
			if type(entry) == "table" then
				entry[1], entry[2], entry[3] = color.r, color.g, color.b
				entry[4] = alpha or color.a or 1
			end
		end
		set("backdrop", theme.backdrop)
		set("frame", theme.panel, 1)
		set("panel", theme.panel, 1)
		set("inset", theme.backdrop, 1)
		set("row", theme.panel, 1)
		set("rowOver", lighter(theme.panel, 0.08))
		set("selected", lighter(theme.panel, 0.05))
		set("line", theme.border, 1)
		-- Hover borders, scroll thumbs and the dashboard accent bars.
		set("trim", theme.accent, 1)

		-- Icons and crests drawn on the button itself, which button styling
		-- would otherwise clear with the template's art.
		local function content(button)
			local kept = {}
			for _, region in ipairs({ button:GetRegions() }) do
				if region:IsObjectType("Texture") and region:GetDrawLayer() == "ARTWORK"
					and region ~= button.Left and region ~= button.Middle and region ~= button.Right then
					kept[#kept + 1] = region
				end
			end
			return kept
		end

		local function styleControl(child)
			if child:IsObjectType("Button") and child.Left and child.Middle and child.Right then
				P.Button(child, { keep = content(child) })
			end
		end

		local framed
		local function styleWindow()
			local window = APP.window
			if not window then
				return
			end
			if not framed then
				framed = true
				-- The window's own border is drawn in the trim colour, now the accent.
				local border = theme.border
				window:SetBorder({ border.r, border.g, border.b, 1 })
				local header = window:GetChildren()
				local close = header and header:GetChildren()
				if close and not close.Left then
					P.CloseButton(close)
				end
			end
			ns.Walk(window, styleControl)
		end

		-- Each page is built the first time its tab opens, before this runs.
		skin:Hook(APP, "OpenTab", styleWindow)
		styleWindow()
	end,
})
