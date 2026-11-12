local _, ns = ...

ns.RegisterSkin({
	id = "Rarity",
	apply = function(skin, P)
		local Rarity = _G.Rarity
		local Tooltips = Rarity and Rarity.Tooltips
		local QTip = LibStub("LibQTip-1.0", true)
		assert(Tooltips and Tooltips.AcquireTooltip and QTip, "this Rarity has no LibQTip tooltips")

		local hooked = setmetatable({}, { __mode = "k" })

		-- LibQTip pools its tooltip frames and copies GameTooltip's border onto
		-- each one as it is acquired. The suite's style is applied once per
		-- frame; the border's alpha survives the copying.
		local function styleTooltip(tooltip)
			if tooltip.NineSlice then
				tooltip.NineSlice:SetAlpha(0)
			end
			P.Clear(tooltip)
			P.Backdrop(tooltip)
			if not hooked[tooltip] then
				hooked[tooltip] = true
				-- The scroll slider is made the first time a tooltip outgrows
				-- the screen.
				skin:Hook(tooltip, "UpdateScrolling", function(self)
					P.Slider(self.slider)
				end)
			end
			P.Slider(tooltip.slider)
		end

		skin:Hook(Tooltips, "AcquireTooltip", function(_, name)
			styleTooltip(QTip:Acquire(name))
		end)
	end,
})
