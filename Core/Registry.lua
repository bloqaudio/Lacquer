local _, ns = ...
local L = ns.L

local skins, order = {}, {}
ns.skins, ns.skinOrder = skins, order
ns.errors = {}

local Skin = {}
Skin.__index = Skin

-- desc fields:
--   id        the target addon's folder name, unique
--   title     shown in options (defaults to id)
--   addon     folder that must be loaded first; false runs at login (defaults to id)
--   editions  "modern", "classic" or "all" (default)
--   skipWith  set of provider ids that already style this addon themselves
--   prepare   optional function(skin), run as soon as the addon loads and before
--             the provider is known; for registering with the addon's own API
--             early enough that choices it saved, such as a bar style, survive
--   apply     function(skin, paint)
function ns.RegisterSkin(desc)
	assert(type(desc.id) == "string" and type(desc.apply) == "function", "Lacquer skins need an id and an apply function")
	assert(not skins[desc.id], "Lacquer skin registered twice: " .. desc.id)
	local skin = setmetatable(desc, Skin)
	if skin.addon == nil then
		skin.addon = skin.id
	end
	skin.title = skin.title or skin.id
	skin.editions = skin.editions or "all"
	skins[skin.id] = skin
	order[#order + 1] = skin
	return skin
end

local function errorHandler(err)
	return tostring(err) .. "\n" .. debugstack(2)
end

function Skin:Fail(err)
	if self.failed then
		return
	end
	self.failed = true
	ns.errors[#ns.errors + 1] = { id = self.id, message = err }
	ns.Print(format(L["The %s skin hit an error and is off for this session. Type /lacquer errors for details."], self.title))
	geterrorhandler()(err)
end

-- Runs fn with the skin's error isolation; a failure disables only this skin.
function Skin:Call(fn, ...)
	if self.failed then
		return
	end
	local count = select("#", ...)
	local args = { ... }
	local ok, err = xpcall(function()
		return fn(unpack(args, 1, count))
	end, errorHandler)
	if not ok then
		self:Fail(err)
	end
end

function Skin:Hook(target, method, fn)
	hooksecurefunc(target, method, function(...)
		self:Call(fn, ...)
	end)
end

function Skin:IsForEdition()
	local editions = self.editions
	return editions == "all" or (editions == "modern" and ns.Modern) or (editions == "classic" and not ns.Modern)
end

function Skin:IsInstalled()
	if not self.addon then
		return true
	end
	local _, _, _, _, reason = C_AddOns.GetAddOnInfo(self.addon)
	return reason ~= "MISSING"
end

function Skin:Status()
	if self.failed then
		return L["Turned off after an error"]
	elseif not self:IsForEdition() then
		return L["Not used on this edition"]
	elseif ns.active and self.skipWith and self.skipWith[ns.active.id] then
		return format(L["Styled by %s itself"], ns.active.name)
	elseif not ns.db.profile.skins[self.id] then
		return L["Off"]
	elseif self.ran then
		return L["Active"]
	elseif not self:IsInstalled() then
		return L["Addon not installed"]
	end
	return L["Waiting for the addon to load"]
end

local function isReady(skin)
	if not skin:IsForEdition() or not ns.db.profile.skins[skin.id] then
		return false
	end
	return not skin.addon or C_AddOns.IsAddOnLoaded(skin.addon)
end

local function tryPrepare(skin)
	if skin.prepared or not skin.prepare or not isReady(skin) then
		return
	end
	skin.prepared = true
	skin:Call(skin.prepare, skin)
end

local function tryRun(skin)
	if skin.ran or not isReady(skin) then
		return
	end
	if skin.skipWith and skin.skipWith[ns.active.id] then
		return
	end
	skin.ran = true
	skin:Call(skin.apply, skin, ns.Paint)
end

local started

-- Called once the saved variables exist, before the provider is chosen.
function ns.PrepareSkins()
	for _, skin in ipairs(order) do
		tryPrepare(skin)
	end
	ns.addon:RegisterEvent("ADDON_LOADED", function(_, name)
		for _, skin in ipairs(order) do
			if skin.addon == name then
				tryPrepare(skin)
				if started then
					tryRun(skin)
				end
			end
		end
	end)
end

function ns.StartSkins()
	if started then
		return
	end
	started = true
	for _, skin in ipairs(order) do
		tryRun(skin)
	end
end

function ns.PrintErrors()
	if #ns.errors == 0 then
		ns.Print(L["No skin errors this session."])
		return
	end
	for _, entry in ipairs(ns.errors) do
		ns.Print(format("%s: %s", entry.id, entry.message:match("^[^\n]*")))
	end
	ns.Print(L["Full stack traces went to your error handler, such as BugSack."])
end
