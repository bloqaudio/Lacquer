local _, ns = ...

local STYLE = "Lacquer"
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }

-- Set once the provider is ready. Bars and frames that turn up before then
-- are left as BigWigs drew them, or queued until apply runs.
local paint
local pending = {}
local messages = {}

local function pixel(frame)
	return PixelUtil.GetNearestPixelSize(1, frame:GetEffectiveScale(), 1)
end

local function layout(bar)
	local icon, fill = bar.candyBarIconFrame, bar.candyBarBar

	-- Midnight icons from the encounter timeline can lock the texture's
	-- anchoring. Reset it, then put the icon back without inspecting it,
	-- since the value may be secret.
	local secret = icon.IsAnchoringSecret and icon:IsAnchoringSecret()
	local isAtlas = bar:IsIconAtlas()
	local value
	if secret then
		if isAtlas then
			value = bar:GetIconAtlas()
		else
			value = bar:GetIcon()
		end
		icon:SetToDefaults()
	end

	icon:ClearAllPoints()
	fill:ClearAllPoints()
	if bar:IsIconVisible() then
		local gap = pixel(bar)
		local size = bar:GetHeight()
		icon:SetSize(size, size)
		if bar:GetIconPosition() == "RIGHT" then
			icon:SetPoint("TOPRIGHT", bar)
			fill:SetPoint("TOPLEFT", bar)
			fill:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", -gap, 0)
		else
			icon:SetPoint("TOPLEFT", bar)
			fill:SetPoint("TOPLEFT", icon, "TOPRIGHT", gap, 0)
			fill:SetPoint("BOTTOMRIGHT", bar)
		end
	else
		fill:SetAllPoints(bar)
	end

	if secret then
		if isAtlas then
			icon:SetAtlas(value)
		else
			icon:SetTexture(value)
			icon:SetTexCoord(unpack(ICON_CROP))
		end
		icon:SetShown(bar:IsIconVisible())
	end
end

local function styleBar(bar)
	if not paint then
		return
	end
	-- LibCandyBar's spare backdrop frame is shared by every bar style, and
	-- the previous one may have drawn on it directly.
	local backdrop = bar.candyBarBackdrop
	backdrop:SetBackdrop(nil)
	backdrop:ClearAllPoints()
	backdrop:SetAllPoints(bar)
	paint.Backdrop(backdrop)
	backdrop:Show()
	bar.candyBarIconFrameBackdrop:Hide()
	layout(bar)
end

local function unstyleBar(bar)
	bar.candyBarBackdrop:Hide()
end

-- Frames BigWigs announces through BigWigs_FrameCreated, by the name it sends.
local FRAMES = {
	QueueTimer = function(P, bar)
		local r, g, b, a = bar:GetStatusBarColor()
		P.StatusBar(bar)
		bar:SetStatusBarColor(r, g, b, a)
	end,
	-- AltPower and Proximity draw their contents on the frame itself.
	AltPower = function(P, frame)
		P.Backdrop(frame)
	end,
	Proximity = function(P, frame)
		P.Backdrop(frame)
	end,
}

local function styleFrame(frame, name)
	local style = FRAMES[name]
	if not style then
		return
	end
	if paint then
		style(paint, frame)
	else
		pending[#pending + 1] = { frame, name }
	end
end

ns.RegisterSkin({
	id = "BigWigs",
	prepare = function(skin)
		local api, loader = _G.BigWigsAPI, _G.BigWigsLoader
		assert(api and api.RegisterBarStyle and loader and loader.RegisterMessage,
			"this BigWigs has no bar style or message API")
		api:RegisterBarStyle(STYLE, {
			apiVersion = 1,
			version = 1,
			barSpacing = 4,
			spellIndicatorsOffset = 2,
			GetStyleName = function()
				return STYLE
			end,
			ApplyStyle = function(bar)
				skin:Call(styleBar, bar)
			end,
			BarStopped = function(bar)
				skin:Call(unstyleBar, bar)
			end,
		})
		loader.RegisterMessage(messages, "BigWigs_FrameCreated", function(_, frame, name)
			skin:Call(styleFrame, frame, name)
		end)
	end,
	apply = function(_, P)
		paint = P
		for _, entry in ipairs(pending) do
			styleFrame(entry[1], entry[2])
		end
		pending = {}
	end,
})
