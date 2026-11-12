local _, ns = ...

local DIALOGS = { "PawnUIStringDialogSingleLine", "PawnUIStringDialogMultiLine" }

-- Left x, then the corner and x offset for the bottom right, in PawnUIFrame's
-- fixed 800x525 layout: the scale list, then the tab pages.
local COLUMNS = {
	{ 6, "BOTTOMLEFT", 196 },
	{ 200, "BOTTOMRIGHT", -6 },
}

-- UIPanelButtonTemplate and InputBoxTemplate both draw three-piece art.
local function hasThreePieceArt(frame)
	return frame.Left and frame.Middle and frame.Right
end

ns.RegisterSkin({
	id = "Pawn",
	apply = function(_, P)
		local tabs = {}

		local function styleWidget(child)
			local name = child:GetName()
			if tabs[child] then
				return
			elseif child:IsObjectType("CheckButton") then
				if name and name:find("Radio$") then
					P.Radio(child)
				else
					P.CheckBox(child)
				end
			elseif child:IsObjectType("EditBox") then
				if hasThreePieceArt(child) then
					P.EditBox(child)
				end
			elseif child:IsObjectType("ScrollFrame") then
				P.ScrollBar(child.ScrollBar or (name and _G[name .. "ScrollBar"]))
			elseif child:IsObjectType("Button") then
				if hasThreePieceArt(child) then
					P.Button(child)
				end
			elseif child.backdropInfo then
				-- The tooltip-bordered boxes inside the tab pages.
				P.Panel(child)
			end
		end

		local window = _G.PawnUIFrame
		P.Window(window)
		-- Pawn's background art drew the scale list column and the page area.
		-- Keep both visible on tabs that leave the column empty.
		for _, column in ipairs(COLUMNS) do
			local box = CreateFrame("Frame", nil, window)
			box:SetFrameLevel(window:GetFrameLevel())
			box:SetPoint("TOPLEFT", window, "TOPLEFT", column[1], -42)
			box:SetPoint("BOTTOMRIGHT", window, column[2], column[3], 6)
			P.Backdrop(box)
		end
		P.CloseButton(_G.PawnUIFrame_TinyCloseButton)
		local index = 1
		while _G["PawnUIFrameTab" .. index] do
			local tab = _G["PawnUIFrameTab" .. index]
			tabs[tab] = true
			P.Tab(tab)
			index = index + 1
		end
		ns.Walk(window, styleWidget)

		for _, dialogName in ipairs(DIALOGS) do
			local dialog = _G[dialogName]
			if dialog then
				P.Window(dialog)
				ns.Walk(dialog, styleWidget)
			end
		end
	end,
})
