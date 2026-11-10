local _, ns = ...

-- English strings are their own keys; translations can be added per locale later.
ns.L = setmetatable({}, {
	__index = function(t, key)
		t[key] = key
		return key
	end,
})
