local util
if cv then
	util = cv.require("lib.util")
else
	util = {}

	function util.indexof(t, nv)
		for k, v in pairs(t) do
			if v == nv then
				return k
			end
		end
		return nil
	end

	function util.pairs(tbl)
		local s = {}
		local c = 1
		for k, v in pairs(tbl) do
			s[c] = k
			c = c + 1
		end
		c = 0
		return function()
			c = c + 1
			return s[c], tbl[s[c]]
		end
	end
end

local ev_stop = {}
local ev_kill = {}

local create
function create(parent)
	local pev = event

	--@apidef event
	--|Event API
	--|Used to set callbacks for event names and push them
	local event = {
		children = setmetatable({}, {__mode = "k"}),
		exports = {},
		callbacks = {},
	}

	if parent ~= false then
		event.parent = parent or pev
		if event.parent then
			event.parent.children[event] = true
		end
	end

	--@apidef event.fork
	--|Forks the current event object
	--|Usage:
	--|    event.fork() -> event
	--|    event.fork(false) -> event
	--|    event.fork(parent) -> event
	function event.fork(parent)
		return create(parent ~= false and event or parent)
	end

	--@apidef event.new
	--|Registers event callback lists in the current context
	--|Usage:
	--|    event.new("foo") -> ...
	--|    event.new({"foo1", "foo2", ...}) -> ...
	function event.new(name)
		if not event.callbacks[name] then
			event.callbacks[name] = {}
		end

		return name
	end

	--@apidef event.listen
	--|Registers a callback to event(s)
	--|Usage:
	--|    event.listen("foo", func) -> func
	--|Returns callback function for convenience
	function event.listen(...)
		local p = {...}
		local import
		if type(p[#p]) == "table" then
			import = p[#p]
			table.remove(p)
		end

		if #p < 2 or type(p[1]) ~= "string" or type(p[#p]) ~= "function" then
			local x = {}
			for i = 1, #p do
				x[i] = type(p[i])
			end
			error("Usage: event.listen(name, [..., ]func) got " .. table.concat(x, ", "))
		end

		local name = p[1]
		local func = p[#p]
		table.remove(p)
		table.remove(p, 1)

		if #p == 0 then
			p = nil
		end

		if not event.callbacks[name] then
			if not event.parent then
				error("Attempt to listen to unregistered event \"" .. name .. "\"")
			end
			local op = {...}
			table.insert(op, import or event)
			event.parent.listen(unpack(op))
		else
			local cbt = {name = name, func = func, import = import, event = event, params = p}
			table.insert(event.callbacks[name], cbt)
			if import then
				import.exports[cbt] = true
			end
		end

		return func
	end

	--@apidef event.remove
	--|Removes a registered callback
	--|Usage:
	--|    event.remove("foo"[, func])
	--|    event.remove({"foo1", "foo2", ...}[, func])
	function event.remove(name, func)
		if func then
			local idx = util.indexof(event.callbacks[name], func)
			if idx then
				table.remove(event.callbacks[name], idx)
			end
			for k, v in util.pairs(event.exports) do
				if k.name == name and k.func == func then
					local idx = util.indexof(k.event.callbacks[k.name], k)
					table.remove(k.event.callbacks[k.name], idx)
					event.exports[k] = nil
				end
			end
		else
			for k, v in pairs(event.callbacks[name] or {}) do
				if v.import then
					v.import.exports[v] = nil
				end
			end

			for k, v in util.pairs(event.exports) do
				if k.name == name then
					local idx = util.indexof(k.event.callbacks[k.name], k)
					table.remove(k.event.callbacks[k.name], idx)
					event.exports[k] = nil
				end
			end
		end
	end

	--@apidef event.stop
	--|When returned from a callback it supresses callbacks following it
	event.stop = ev_stop
	--@apidef event.kill
	--|When returned from a callback it unregisters itself
	event.kill = ev_kill

	--@apidef event.push
	--|Calls all the functions associated with an event name
	--|Usage:
	--|    event.push("foo", ...)
	function event.push(name, ...)
		local p = {...}
		local ret = {}

		if event.callbacks[name] then
			for i = 1, #event.callbacks[name] do
				local c = event.callbacks[name][i]

				local match = true
				local st = 1
				if c.params then
					st = (#c.params) + 1

					for j = 1, #c.params do
						if p[j] ~= c.params[j] then
							match = false
							break
						end
					end
				end

				local stop

				if match then
					local o = table.pack(c.func(unpack(p, st)))

					if o[1] == ev_stop then
						stop = true
						o = table.pack(table.unpack(o, 2))
					elseif o[1] == ev_kill then
						table.insert(rem, c.func)
						o = table.pack(table.unpack(o, 2))
					end

					if o.n > 0 then
						ret = o
					end
				end

				if stop then
					break
				end
			end

			local rem = {}

			for i = 1, #rem do
				event.remove(name, rem[i])
			end
		elseif event.parent then
			event.parent.push(name, ...)
		else
			error("Attempt to push unregistered event \"" .. name .. "\"")
		end

		return table.unpack(ret)
	end

	--@apidef event.destroy()
	--|Destroys all of the events and children, including imports and exports
	function event.destroy()
		for k, v in pairs(event.children) do
			k.destroy()
		end
		
		for k, v in util.pairs(event.callbacks) do
			event.remove(k)
		end
		
		for k, v in util.pairs(event.exports) do
			local idx = util.indexof(k.event.callbacks[k.name], k)
			table.remove(k.event.callbacks[k.name], idx)
			event.exports[k] = nil
		end

		if event.parent then
			event.parent.children[event] = nil
		end
	end

	return event
end

return create()
