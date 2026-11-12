local _, ns = ...

-- BetterWardrobe styles most of its wardrobe for ElvUI itself. These are the
-- collection list controls and the Apply On Click box, which that styling
-- leaves out. The list controls are built a moment after the wardrobe, so
-- each opening of the Collections window checks again.
local BUTTONS = { "BW_CollectionListOptionsButton", "BW_CollectionListButton" }

ns.RegisterSkin({
	id = "BetterWardrobe",
	editions = "modern",
	apply = function(skin, P)
		local function style()
			P.Dropdown(_G.BW_CollectionList_Dropdown)
			for _, name in ipairs(BUTTONS) do
				P.Button(_G[name], { keep = { "Icon" } })
			end
			local wardrobe = _G.BetterWardrobeCollectionFrame
			local check = wardrobe and wardrobe.ItemsCollectionFrame and wardrobe.ItemsCollectionFrame.ApplyOnClickCheckbox
			if check then
				-- At 30px it draws a bigger box than the 26px stock check boxes
				-- elsewhere in the journal.
				check:SetSize(26, 26)
				P.CheckBox(check)
			end
		end

		local journal = _G.CollectionsJournal
		if journal then
			journal:HookScript("OnShow", function()
				skin:Call(style)
			end)
		end
		style()
	end,
})
