local _, ns = ...

local TITLE = "TomCat's Tours"
local CYCLER_HEIGHT = 24
local POPOUT_MARGIN = 5

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

local function isCycler(frame)
	return frame.Button and frame.Popout and frame.BackButton and frame.NextButton and frame.entries
end

-- TomCats draws an entry's hover in character-creation art; a flat bar
-- replaces it, and TomCats still fades it in and out.
local function flattenEntryHover(entry)
	local glow = entry.HighlightBGTex
	if not (glow and glow.Middle) then
		return
	end
	glow.Left:SetAlpha(0)
	glow.Right:SetAlpha(0)
	glow.Middle:SetColorTexture(1, 1, 1)
	glow.Middle:ClearAllPoints()
	glow.Middle:SetAllPoints(glow)
end

-- A setting cycler: a popout list between back and next arrows. TomCats
-- puts its character-creation art back on hover and click, so those setters
-- are disabled on each button once it is painted.
local cyclers = setmetatable({}, { __mode = "k" })

local function styleCycler(P, cycler)
	if cyclers[cycler] then
		return
	end
	cyclers[cycler] = true
	local button, popout = cycler.Button, cycler.Popout

	button:SetHeight(CYCLER_HEIGHT)
	button.SelectionName:ClearAllPoints()
	button.SelectionName:SetPoint("CENTER")
	P.Button(button)
	button.SetNormalAtlas = nop
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetAlpha(0)
		highlight.SetAlpha = nop
	end

	for arrow, direction in pairs({ [cycler.BackButton] = "left", [cycler.NextButton] = "right" }) do
		P.ArrowButton(arrow, direction)
		arrow.SetHighlightAtlas = nop
		arrow:SetSize(CYCLER_HEIGHT, CYCLER_HEIGHT)
	end

	popout.Border:Hide()
	P.Window(popout)
	popout:ClearAllPoints()
	popout:SetPoint("TOP", button, "BOTTOM", 0, -2)
	local first = cycler.entries[1]
	if first then
		first:SetPoint("TOPLEFT", POPOUT_MARGIN, -POPOUT_MARGIN)
	end
	popout.widthPadding = 2 * POPOUT_MARGIN
	popout.heightPadding = 2 * POPOUT_MARGIN
	for _, entry in ipairs(cycler.entries) do
		flattenEntryHover(entry)
	end
	popout:Layout()
end

local function styleOptionsControl(P, child)
	if isCycler(child) then
		styleCycler(P, child)
		return false
	elseif child.Track and child.Back and child.Forward then
		P.ScrollBar(child)
		return false
	end
	return ns.StyleSettingsControl(child)
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

		-- The options page is a private canvas, recognised by its category
		-- name. TomCats builds its contents the first time the page shows.
		local panel = _G.SettingsPanel
		if not panel then
			return
		end
		local page
		local function styleOptions()
			ns.Walk(page, function(child)
				return styleOptionsControl(P, child)
			end)
		end
		local function isOptions(layout)
			local category = panel:GetCurrentCategory()
			return category and category:GetName() == TITLE and panel:GetLayout(category) == layout
		end
		skin:Hook(panel, "DisplayLayout", function(_, layout)
			if page or not isOptions(layout) then
				return
			end
			page = layout:GetFrame()
			page:HookScript("OnShow", function()
				skin:Call(styleOptions)
			end)
			styleOptions()
		end)
	end,
})
