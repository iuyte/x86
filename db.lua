local util = require("util")
local db = {}

db.opened = setmetatable({}, {__mode = "v"})

function db.new(fn)
	fn = fn .. ".db"

	if db.opened[fn] then
		return db.opened[fn]
	end

	local data = {}

	local file = io.open(fn, "r")
	if file then
		data = util.unserialize(file:read("*a")) or {}
		file:close()
	end

	local function save()
		local file = assert(io.open(fn, "w"))
		file:write(util.serialize(data))
		file:close()
	end

	local cache = setmetatable({}, {__mode = "v"})

	local mt
	mt = {
		__index = function(s, k)
			local cmt = getmetatable(s)

			local r = cmt.real[1]
			if not r then
				error("attempt to index null database entry")
			end

			local v = r[k]
			if type(v) == "table" then
				if cache[v] then
					return cache[v]
				end

				local nmt = util.copy(mt)
				nmt.real = setmetatable({v}, {__mode="v"})
				local t = setmetatable({}, nmt)
				cache[v] = t
				return t
			else
				return v
			end
		end,

		__newindex = function(s, k, v)
			local cmt = getmetatable(s)

			local r = cmt.real[1]
			if not r then
				error("attempt to set index of null database entry")
			end

			if type(v) == "table" then
				local vt = cache[v]
				local vmt = getmetatable(v)
				if vt then
					r[k] = getmetatable(vt).real[1]
					return
				elseif vmt and vmt.real then
					v = vmt.real[1]
				else
					local nmt = util.copy(mt)
					assert(not vmt, "Metatables not allowed in database")
					nmt.real = setmetatable({v}, {__mode="v"})
					local t = setmetatable({}, nmt)
					cache[v] = t
				end
			end
			r[k] = v
			save()
		end,

		__pairs = function(s)
			local cmt = getmetatable(s)
			local r = cmt.real[1]
			if not r then
				error("attempt to index null database entry")
			end
			return function(t, k)
				local nk, v = next(t, k)
				return nk, s[nk]
			end, r, nil
		end,

		__next = function(s, k)
			local cmt = getmetatable(s)
			local nk, v = next(cmt.real[1],k)
			if nk then
				return nk, s[nk]
			end
			return nk, v
		end,

		__len = function(s)
			local cmt = getmetatable(s)
			return #cmt.real[1]
		end
	}

	local nmt = util.copy(mt)
	nmt.real = {data}
	local o = setmetatable({}, nmt)
	cache[data] = o

	return o
end

return db