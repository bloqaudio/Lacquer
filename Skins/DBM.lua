local _, ns = ...

local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }

local paint
local boxes = setmetatable({}, { __mode = "k" })

local function pixel(frame)
	return PixelUtil.GetNearestPixelSize(1, frame:GetEffectiveScale(), 1)
end

local function placeIcon(icon, point, statusbar, relativePoint, offset)
	if icon.IsAnchoringSecret and icon:IsAnchoringSecret() then
		return
	end
	icon:ClearAllPoints()
	icon:SetPoint(point, statusbar, relativePoint, offset, 0)
end

local function boxFor(frame)
	local box = boxes[frame]
	if not box then
		box = CreateFrame("Frame", nil, frame)
		box:SetFrameLevel(frame:GetFrameLevel())
		paint.Backdrop(box)
		boxes[frame] = box
	end
	return box
end

-- Runs after DBM's own ApplyStyle, so it sees the icons DBM chose to show.
-- Texture, font, and spark stay as the player set them in DBM.
local function styleBar(bar)
	local frame = bar.frame
	local name = frame:GetName()
	local statusbar = _G[name .. "Bar"]
	local icon1, icon2 = _G[name .. "BarIcon1"], _G[name .. "BarIcon2"]

	local gap = pixel(frame)
	local size = statusbar:GetHeight()
	local left = icon1:IsShown() and size + gap or 0
	local right = icon2:IsShown() and size + gap or 0
	local box = boxFor(frame)
	box:ClearAllPoints()
	box:SetPoint("TOPLEFT", statusbar, "TOPLEFT", -left, 0)
	box:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", right, 0)

	placeIcon(icon1, "RIGHT", statusbar, "LEFT", -gap)
	placeIcon(icon2, "LEFT", statusbar, "RIGHT", gap)
	icon1:SetTexCoord(unpack(ICON_CROP))
	icon2:SetTexCoord(unpack(ICON_CROP))
end

local function eachBar(DBT, fn)
	local iterate, state = DBT:GetBarIterator()
	if not iterate then
		return
	end
	for bar in iterate, state do
		fn(bar)
	end
end

ns.RegisterSkin({
	id = "DBM-StatusBarTimers",
	title = "DBM",
	apply = function(skin, P)
		local DBT = _G.DBT
		assert(DBT and DBT.CreateBar and DBT.GetBarIterator, "this DBM has no bar API")
		paint = P

		-- DBM keeps its bar prototype private, so take it from the first bar.
		local hooked
		skin:Hook(DBT, "CreateBar", function()
			if hooked then
				return
			end
			eachBar(DBT, function(bar)
				local meta = getmetatable(bar)
				local prototype = meta and meta.__index
				if not hooked and type(prototype) == "table" and type(prototype.ApplyStyle) == "function" then
					hooked = true
					skin:Hook(prototype, "ApplyStyle", styleBar)
				end
			end)
			if hooked then
				eachBar(DBT, styleBar)
			end
		end)
	end,
})
