local _, ns = ...

-- The Explorer draws its frame border as loose textures on a child frame.
local function isBorder(frame)
	return frame.BaseFrameTopLeftCorner ~= nil
end

local function styleControl(P, child)
	if ns.IsDropdown(child) then
		P.Dropdown(child)
		return false
	elseif isBorder(child) then
		child:SetAlpha(0)
		return false
	elseif child.Track and child.Back and child.Forward then
		P.ScrollBar(child)
		return false
	elseif child:IsObjectType("CheckButton") then
		P.CheckBox(child)
	elseif child:IsObjectType("EditBox") then
		if child.Left and child.Middle and child.Right then
			P.EditBox(child)
		end
	elseif child:IsObjectType("Button") then
		if type(child.GetCenterAtlasName) == "function" then
			P.Button(child, { keep = { "Arrow" } })
		end
	end
end

-- A panel inside the Explorer: its own art goes, the suite's backdrop comes.
local function panel(P, frame, ...)
	for index = 1, select("#", ...) do
		local texture = frame[select(index, ...)]
		if texture then
			texture:SetAlpha(0)
		end
	end
	P.Backdrop(frame)
end

local function styleLootItem(P, item)
	P.Icon(item.Icon, item)
	item.IconBorder:SetAlpha(0)
end

local function styleExplorer(skin, P, explorer)
	P.Window(explorer)
	P.CloseButton(explorer.CloseButton)
	ns.Walk(explorer, function(child)
		return styleControl(P, child)
	end)

	panel(P, explorer.RareNPCList, "background")
	panel(P, explorer.RareLoot, "background")
	panel(P, explorer.RareInfo, "BaseFrameBackground", "BoardDropShadow", "Header")
	for _, key in ipairs({ "Mounts", "Pets", "Toys", "Custom", "Appearances" }) do
		-- Texture is the card's corner glyph, which stays.
		panel(P, explorer.RareInfo[key], "Background1")
	end
	local custom = explorer.CustomLoot
	panel(P, custom, "background", "background2")
	panel(P, custom.GroupInfo, "BG")

	-- List rows come from scroll box views and are styled as each is set up.
	local function onRows(scrollBox, style)
		scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnInitializedFrame, function(_, row)
			skin:Call(style, row)
		end, skin)
	end
	onRows(explorer.RareNPCList.scrollBox, function(row)
		row.BG:SetAlpha(0)
		row.NameBG:SetAlpha(0)
		P.Backdrop(row)
	end)
	onRows(explorer.RareLoot.scrollBox, function(row)
		row.BG:SetAlpha(0)
		P.Backdrop(row)
		P.Icon(row.Icon, row)
		P.CheckBox(row.FilterCheck)
	end)
	onRows(custom.GroupList.scrollBox, function(row)
		row.BG:SetAlpha(0)
		P.Backdrop(row)
	end)

	-- Loot icons come from frame pools; the custom loot pool is rebuilt each
	-- time that panel is initialized.
	local pools = setmetatable({}, { __mode = "k" })
	local function hookPool(pool)
		if not pool or pools[pool] then
			return
		end
		pools[pool] = true
		skin:Hook(pool, "Acquire", function(self)
			for item in self:EnumerateActive() do
				styleLootItem(P, item)
			end
		end)
	end
	hookPool(explorer.lootItemsPool)
	hookPool(custom.GroupInfo.lootItemsPool)
	skin:Hook(custom, "Initialize", function(self)
		hookPool(self.GroupInfo.lootItemsPool)
	end)
end

ns.RegisterSkin({
	id = "RareScanner",
	apply = function(skin, P)
		-- The rare-found button is built when RareScanner loads. It brightens
		-- its own border on hover, and that now lands on the suite's border.
		local button = _G.RARESCANNER_BUTTON
		assert(button, "RareScanner's button was not found")
		P.Window(button)
		P.CloseButton(button.CloseButton)

		-- Loot icons come from a pool and are reused for each rare found.
		local loot = button.LootBar and button.LootBar.itemFramesPool
		if loot and type(loot.ShowIfReady) == "function" then
			skin:Hook(loot, "ShowIfReady", function(pool)
				for item in pool:EnumerateActive() do
					P.Icon(item.Icon, item)
				end
			end)
		end

		-- The Explorer, opened from the minimap button.
		local explorer = _G.RSExplorerFrame
		if explorer then
			styleExplorer(skin, P, explorer)
		end
	end,
})
