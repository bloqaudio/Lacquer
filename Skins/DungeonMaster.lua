local _, ns = ...

local THIN_EDGE = "Interface\\Buttons\\WHITE8x8"
-- Inset by the suite's 4px each side, this draws a 16px box.
local CHECK_BOX_SIZE = 24

-- DungeonMaster keeps its frames private; these find them by their fields.
local function findChild(parent, test)
	for _, child in ipairs({ parent:GetChildren() }) do
		if test(child) then
			return child
		end
	end
end

-- The thin gold outline DungeonMaster puts around each window, twice: a
-- bare child frame with a one-pixel edge and nothing else.
local function isOutline(frame)
	local info = frame.backdropInfo
	return info and info.edgeFile == THIN_EDGE and not info.bgFile
		and frame:GetNumChildren() == 0 and select("#", frame:GetRegions()) <= 9
		and frame:IsObjectType("Frame") and not frame:IsObjectType("Button")
end

local function hideOutlines(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if isOutline(child) then
			child:Hide()
		end
	end
end

-- Textures that are content, such as a search glass, which a suite's
-- edit box styling clears; returns a function that puts them back.
local function holdTextures(frame)
	local held = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") and region:GetTexture() then
			held[region] = region:GetTexture()
		end
	end
	return function()
		for region, file in pairs(held) do
			region:SetTexture(file)
		end
	end
end

ns.RegisterSkin({
	id = "DungeonMaster",
	title = "DungeonMaster",
	editions = "modern",
	apply = function(skin, P)
		local f = _G.DungeonMasterFrame
		assert(f and f.CloseButton, "this DungeonMaster has no main window")

		P.Window(f)
		hideOutlines(f)
		P.CloseButton(f.CloseButton)

		local details = findChild(f, function(c)
			return c.title and c.body and c.items and c.labels
		end)
		if details then
			P.Window(details)
			hideOutlines(details)
			local close = findChild(details, function(c)
				return c:IsObjectType("Button") and c.text and not c.icon
			end)
			if close then
				P.CloseButton(close)
				close.text:SetAlpha(0)
			end
		end

		-- The search results open over the list, so theirs is opaque.
		local results = findChild(f, function(c)
			return c.rows and not c:IsObjectType("Button")
		end)
		if results then
			P.Panel(results)
			hideOutlines(results)
		end

		local legend = findChild(f, function(c)
			return c.act and c.star and c.rest
		end)
		if legend then
			P.Panel(legend)
		end

		local search = findChild(f, function(c)
			return c:IsObjectType("EditBox") and c.backdropInfo
		end)
		if search then
			search:ClearBackdrop()
			local restore = holdTextures(search)
			P.EditBox(search)
			restore()
		end

		local styled = setmetatable({}, { __mode = "k" })
		local function styleControl(child)
			if child:IsObjectType("CheckButton") then
				if styled[child] then
					return
				end
				styled[child] = true
				-- The template's 32px button sets the labels' spacing, so only
				-- the drawn box shrinks.
				local box = CreateFrame("Frame", nil, child)
				box:SetSize(CHECK_BOX_SIZE, CHECK_BOX_SIZE)
				box:SetPoint("CENTER")
				P.CheckBox(child, box)
			elseif child:IsObjectType("EditBox") then
				if child.Left and child.Middle and child.Right then
					P.EditBox(child)
				end
			elseif child:IsObjectType("Button") then
				local icon = child.icon
				local isTexture = icon and icon.IsObjectType and icon:IsObjectType("Texture")
				if child.backdropInfo and child.text and isTexture then
					-- The "mark entrance" button.
					P.Button(child, { keep = { "icon" } })
				elseif isTexture and child.border and not styled[child] then
					-- A boss's loot; its border is tinted by quality.
					styled[child] = true
					P.ItemButton(child)
					P.IconFrame(child, child.border)
				elseif isTexture and child.glow and child.text then
					-- An item line in the details panel.
					P.Icon(icon, child)
				end
			end
		end

		local function styleAll()
			ns.Walk(f, styleControl)
		end

		-- Rows and their loot are pooled and grow as lists refill, and each
		-- refill ends by sizing its list.
		local watched = setmetatable({}, { __mode = "k" })
		local function watch(list)
			if list and not watched[list] then
				watched[list] = true
				skin:Hook(list, "SetHeight", function()
					ns.Walk(list, styleControl)
				end)
			end
		end
		ns.Walk(f, function(child)
			if child:IsObjectType("ScrollFrame") then
				watch(child:GetScrollChild())
			end
		end)
		watch(details)

		f:HookScript("OnShow", function()
			skin:Call(styleAll)
		end)
		styleAll()
	end,
})
