local _, ns = ...

local ARROWS = { prev = "left", next = "right" }

-- Blizzard's radio templates label themselves .text, check boxes .Text.
local function isRadio(check)
	return check.text ~= nil and check.Text == nil
end

ns.RegisterSkin({
	id = "Clique",
	apply = function(skin, P)
		local Clique = _G.Clique
		assert(Clique and Clique.ShowBindingConfig, "this Clique has no binding window")

		local lists = setmetatable({}, { __mode = "k" })
		local styleTree

		-- Option pages are scrolling lists that build rows as they scroll.
		local function watchList(scrollBox)
			if lists[scrollBox] then
				return
			end
			lists[scrollBox] = true
			scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnInitializedFrame, function(_, row)
				skin:Call(styleTree, row)
			end, scrollBox)
		end

		local catalog

		local function styleControl(child)
			if child == catalog or child:IsObjectType("GameTooltip") then
				return false
			elseif child.ScrollTarget and child.RegisterCallback and ScrollBoxListMixin then
				watchList(child)
			elseif ns.IsDropdown(child) then
				P.Dropdown(child)
				return false
			elseif child.Track and child.Back and child.Forward then
				P.ScrollBar(child)
				return false
			elseif child:IsObjectType("CheckButton") then
				if isRadio(child) then
					P.Radio(child)
				else
					P.CheckBox(child)
				end
			elseif not (child.Left and child.Middle and child.Right) then
				-- Tooltip-bordered boxes: the list backgrounds and the warning.
				if child.NineSlice then
					P.Clear(child)
					P.Backdrop(child)
				end
				return
			elseif child:IsObjectType("EditBox") then
				P.EditBox(child)
			elseif child:IsObjectType("Button") then
				P.Button(child)
			end
		end

		styleTree = function(frame)
			ns.Walk(frame, styleControl)
		end

		-- The catalog's page arrows draw their art on a plain texture; as the
		-- normal texture it reaches the suite's arrow style.
		local function styleCatalog()
			P.Window(catalog)
			for key, direction in pairs(ARROWS) do
				local arrow = catalog[key]
				if arrow and arrow.bg then
					arrow:SetNormalTexture(arrow.bg:GetTexture())
					arrow.bg:SetAlpha(0)
					P.ArrowButton(arrow, direction)
				end
			end
			for _, tab in ipairs(catalog.tabSystem and catalog.tabSystem.tabs or {}) do
				P.Tab(tab)
			end
		end

		-- Every page and the catalog are built the first time the window opens.
		skin:Hook(Clique, "ShowBindingConfig", function()
			local window = _G.CliqueUIBindingFrame
			if not window then
				return
			end
			P.Window(window)
			catalog = _G.CliqueConfigUIActionCatalogFrame
			if catalog then
				styleCatalog()
				styleTree(catalog)
			end
			styleTree(window)
		end)
	end,
})
