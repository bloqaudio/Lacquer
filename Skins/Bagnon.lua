local _, ns = ...

local SKIN = "Lacquer"

ns.RegisterSkin({
	id = "Bagnon",
	apply = function(skin, P)
		local Bagnon = _G.Bagnon
		assert(Bagnon and Bagnon.Skins and Bagnon.Skins.Register, "this Bagnon has no skin API")

		-- Bagnon builds the background frame from the template and calls load
		-- each time the bag frame refreshes. Its colour options are left out,
		-- so the suite's colours win.
		Bagnon.Skins:Register({
			id = SKIN,
			template = "BackdropTemplate",
			load = function(background)
				skin:Call(function()
					P.Window(background)
					local frame = background:GetParent()
					P.CloseButton(frame and frame.CloseButton)
				end)
			end,
		})

		-- Only the first sighting of each button pays for error isolation.
		-- A slot has already set its quality border by then, so it is redrawn
		-- once for the new style to pick up its colour.
		local styled = setmetatable({}, { __mode = "k" })
		local function style(button)
			if not styled[button] then
				styled[button] = true
				skin:Call(P.ItemButton, button)
				if button.UpdateBorder and button.info then
					skin:Call(button.UpdateBorder, button)
				end
			end
		end

		-- Every item grid lays out through the base class. Slots are styled
		-- after the grid places them: a slot styled before its first anchor
		-- can keep a stale, empty position for its icon and border until it
		-- is anchored again.
		hooksecurefunc(Bagnon.ItemGroup, "Layout", function(group)
			for _, button in ipairs(group.buttons) do
				style(button)
			end
		end)
		-- Bag buttons are anchored as soon as they are made.
		hooksecurefunc(Bagnon.Bag, "Update", style)
	end,
})

-- The options pages are Sushi-3.2 widgets wrapping stock templates. Every Sushi
-- group, rows included, rebuilds its widgets through Layout, and rows can lay
-- out after the page does.
ns.RegisterSkin({
	id = "Bagnon_Config",
	title = "Bagnon options",
	apply = function(skin, P)
		local Bagnon = _G.Bagnon
		assert(Bagnon and Bagnon.sets, "this Bagnon has no settings table")

		local hooked = {}
		local styleGroup

		local function hookGroup(group)
			if not hooked[group] then
				hooked[group] = true
				skin:Hook(group, "Layout", styleGroup)
			end
		end

		-- Sushi lays a slider out from its height plus top and bottom padding,
		-- and hangs its value box into the bottom of the 17px template. A suite
		-- that thins the slider shrinks the row, so the height it took comes back
		-- as padding and the box moves under the bar. Pooled sliders return
		-- already styled, so their own height and padding are kept from the
		-- first time they were seen.
		local sliders = setmetatable({}, { __mode = "k" })
		local relayout = {}

		local function styleSlider(slider)
			local own = sliders[slider]
			if not own then
				own = { height = slider:GetHeight(), top = slider.top or 0, bottom = slider.bottom or 0 }
				sliders[slider] = own
			end
			P.Slider(slider)

			local lost = math.max(0, own.height - slider:GetHeight())
			local top = own.top + math.ceil(lost / 2)
			if slider.top ~= top then
				slider.top = top
				slider.bottom = own.bottom + math.floor(lost / 2)
				relayout[slider:GetParent()] = true
			end

			local edit = slider.Edit
			if edit then
				edit:ClearAllPoints()
				edit:SetPoint("TOP", slider, "BOTTOM", 0, lost > 0 and 0 or 7)
			end
		end

		local function styleWidget(child)
			if type(child.Children) == "table" and type(child.Layout) == "function" then
				hookGroup(child)
			elseif ns.IsDropdown(child) then
				P.Dropdown(child)
				return false
			elseif child.Swatch then
				P.Swatch(child, child.Swatch)
				return false
			elseif child:IsObjectType("CheckButton") then
				-- Icon toggles are pictures, not check boxes. Sushi's check button
				-- spans its label, with the box drawn by the normal texture.
				if not child.Icon then
					P.CheckBox(child, child:GetNormalTexture())
				end
			elseif child:IsObjectType("Slider") then
				styleSlider(child)
			elseif not (child.Left and child.Middle and child.Right) then
				return
			elseif child:IsObjectType("EditBox") then
				P.EditBox(child)
			elseif child:IsObjectType("Button") then
				P.Button(child)
			end
		end

		-- New padding only counts on the next layout, so groups whose sliders
		-- changed lay out once more; that pass finds nothing left to change.
		styleGroup = function(group)
			ns.Walk(group, styleWidget)
			local groups = relayout
			relayout = {}
			for changed in pairs(groups) do
				changed:Layout()
			end
		end

		-- Each page is a module on the Bagnon object carrying its settings table.
		-- Hooking them all now, before any is shown, catches their first build.
		for _, page in pairs(Bagnon) do
			if type(page) == "table" and page.sets == Bagnon.sets and type(page.Layout) == "function"
				and type(page.IsVisible) == "function" then
				hookGroup(page)
				if page:IsVisible() then
					styleGroup(page)
				end
			end
		end
	end,
})
