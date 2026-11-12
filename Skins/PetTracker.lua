local _, ns = ...

local SLOT_ART = { "Bg", "Shadows", "IconBorder", "LevelBG" }
-- Everything a filled slot shows, hidden while the slot is empty.
local SLOT_CONTENT = {
	"Icon", "Quality", "Level", "Name", "SubName", "Model", "Type",
	"PowerIcon", "Power", "SpeedIcon", "Speed", "HealthIcon", "Health",
}
local LOCK_ICON = "Interface\\PetBattles\\PetBattle-LockIcon"
-- The Collections pages a page added through SecureTabs is laid over.
local COLLECTION_PAGES = {
	"MountJournal", "PetJournal", "ToyBox", "HeirloomsJournal", "WardrobeCollectionFrame", "WarbandSceneJournal",
}

-- SecureTabs spaces its tabs for Blizzard's art; the suite may space the
-- journal's own tabs differently, so added tabs take the gap measured
-- between the first two.
local function alignTabs()
	local journal = _G.CollectionsJournal
	local first, second = _G.CollectionsJournalTab1, _G.CollectionsJournalTab2
	local right, left = first and first:GetRight(), second and second:GetLeft()
	if not (right and left and journal.numTabs) then
		return
	end
	local previous = _G["CollectionsJournalTab" .. journal.numTabs]
	local index = 0
	while _G["CollectionsJournalSecureTab" .. index] do
		local tab = _G["CollectionsJournalSecureTab" .. index]
		tab:SetPoint("LEFT", previous, "RIGHT", left - right, 0)
		previous = tab
		index = index + 1
	end
end

-- Rivals has no background of its own, so the Collections window's shows, as
-- on every other tab. The page and title it covers are hidden meanwhile.
local function coverCollections(covered)
	local alpha = covered and 0 or 1
	for _, name in ipairs(COLLECTION_PAGES) do
		local page = _G[name]
		if page then
			page:SetAlpha(alpha)
		end
	end
	local title = _G.CollectionsJournal.TitleContainer
	if title then
		title:SetAlpha(alpha)
	end
end

local iconFrames = setmetatable({}, { __mode = "k" })

-- A square, suite-styled frame around an icon or portrait drawn by owner,
-- taking its colour from PetTracker's rounded quality border. It sits a
-- level below owner so the icon or model still draws on top.
local function frameIcon(P, owner, icon, quality)
	local frame = CreateFrame("Frame", nil, owner)
	frame:SetFrameLevel(math.max(owner:GetFrameLevel() - 1, 0))
	frame:SetAllPoints(icon)
	P.IconFrame(frame, quality)
	return frame
end

local function showContent(slot, pet)
	local alpha = pet and 1 or 0
	if iconFrames[slot] then
		iconFrames[slot]:SetAlpha(alpha)
	end
	for _, key in ipairs(SLOT_CONTENT) do
		if slot[key] then
			slot[key]:SetAlpha(alpha)
		end
	end
	-- PetTracker leaves the last pet's abilities on an emptied slot.
	for _, ability in pairs(slot.Abilities or {}) do
		ability:SetAlpha(alpha)
	end
end

-- An Enemy Team slot, laid out like the Pet Journal's battle slots: no panel,
-- a plain level number, and a square quality border on the icon.
local function styleSlot(skin, P, slot)
	for _, key in ipairs(SLOT_ART) do
		if slot[key] then
			slot[key]:SetAlpha(0)
		end
	end
	P.Icon(slot.Icon)
	iconFrames[slot] = frameIcon(P, slot, slot.Icon, slot.Quality)
	-- PetTracker marks an empty slot with one baked image of Blizzard's
	-- locked-slot art. A padlock alone takes its place.
	local empty = slot.IsEmpty
	if empty then
		P.Clear(empty)
		local lock = empty:CreateTexture(nil, "OVERLAY")
		lock:SetTexture(LOCK_ICON)
		lock:SetSize(32, 32)
		lock:SetPoint("CENTER", slot.Icon)
		skin:Hook(slot, "Display", showContent)
		showContent(slot, slot.pet)
	end
end

ns.RegisterSkin({
	id = "PetTracker_Journal",
	title = "PetTracker Journal",
	apply = function(skin, P)
		P.CheckBox(_G.PetTrackerTrackToggle)

		-- PetTracker's SecureTabs adds journal tabs, plus a cover tab laid over
		-- Blizzard's selected one while an added tab is open. Other addons
		-- can add theirs through the same library later.
		local function styleTabs()
			local index = 0
			while _G["CollectionsJournalSecureTab" .. index] do
				P.Tab(_G["CollectionsJournalSecureTab" .. index])
				index = index + 1
			end
			P.Tab(_G.CollectionsJournalCoverTab)
		end
		local tabs = LibStub("SecureTabs-2.0", true)
		if tabs then
			skin:Hook(tabs, "Add", styleTabs)
		end
		styleTabs()
		_G.CollectionsJournal:HookScript("OnShow", function()
			skin:Call(alignTabs)
		end)

		-- The Rivals page builds itself on first show and ends by picking a tab.
		local journal = _G.PetTrackerRivalsJournal
		if not journal then
			return
		end
		local styled
		skin:Hook(journal, "SetTab", function()
			if styled or not journal.Card[1] then
				return
			end
			styled = true

			P.Clear(journal)
			P.CloseButton(journal.CloseButton)
			-- PetTracker draws its own logo into the portrait.
			journal.PortraitContainer:SetAlpha(0)
			journal:HookScript("OnShow", function()
				skin:Call(coverCollections, true)
			end)
			journal:HookScript("OnHide", function()
				skin:Call(coverCollections, false)
			end)
			coverCollections(journal:IsShown())

			P.Clear(journal.Count)
			P.Clear(journal.ListInset)
			-- Cleared, with the see-through backdrop of the Pet Journal's pet card.
			for _, panel in ipairs({ journal.Card, journal.History }) do
				P.Clear(panel)
				P.Backdrop(panel)
			end
			P.Inset(journal.Map.BorderFrame)
			P.EditBox(journal.SearchBox)
			P.ScrollBar(journal.List.scrollBar)
			P.Button(journal.History.LoadButton)
			for i = 1, 4 do
				P.ItemButton(journal.Card[i])
			end
			for _, row in ipairs(journal.List.buttons or {}) do
				row.background:SetAlpha(0)
				row.model.levelRing:SetAlpha(0)
				frameIcon(P, row, row.model, row.model.quality)
				P.Row(row, row.selectedTexture)
			end
			-- Character-sheet style tabs: the art goes, the dimming PetTracker
			-- lays over unselected tabs stays.
			for i = 1, 3 do
				local tab = journal["Tab" .. i]
				tab.TabBg:SetAlpha(0)
				P.Backdrop(tab)
			end

			-- The Enemy Team frame and title art; the title text stays.
			P.Clear(journal.Team)
			P.Clear(journal.Team.Border)
			for _, slot in ipairs(journal.Slots or {}) do
				styleSlot(skin, P, slot)
			end
		end)
	end,
})

ns.RegisterSkin({
	id = "PetTracker_Battle",
	title = "PetTracker Battle",
	apply = function(_, P)
		local switcher = _G.PetTrackerSwitcher
		if switcher then
			P.Window(switcher)
			P.Inset(switcher.Inset)
		end
	end,
})
