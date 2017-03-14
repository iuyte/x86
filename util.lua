local ffi
if jit then
	ffi = require("ffi")
end

local util = {}

local function decodeBits(n, s)
	if type(n) == "string" then
		s = s or (#n * 8)
		local bits = {}
		for l1 = 1, math.min(s, #n) do
			local c = n:byte(l1, l1)
			for l2 = 0, 7 do
				table.insert(bits, math.floor(c / (2 ^ (7 - l2))) % 2)
			end
		end
		for l1 = #bits + 1, s do
			table.insert(bits, 0)
		end
		return bits
	else
		local bits = {}
		while n > 0 and #bits < s do
			table.insert(bits, 1, n % 2)
			n = math.floor(n / 2)
		end
		for l1 = #bits + 1, s do
			table.insert(bits, 1, 0)
		end
		return bits
	end
end

local function encodeBits(bits, s)
	if s then
		local o = ""
		for l1 = 1, #bits, 8 do
			o = o .. string.char(
				bits[l1 + 7] +
				bits[l1 + 6] * 2 +
				bits[l1 + 5] * 4 +
				bits[l1 + 4] * 8 +
				bits[l1 + 3] * 16 +
				bits[l1 + 2] * 32 +
				bits[l1 + 1] * 64 +
				bits[l1] * 128
			)
		end
		return o
	else
		local o = 0
		for l1 = 1, #bits do
			o = o + bits[l1] * (2 ^ (#bits - l1))
		end
		return o
	end
end

function util.encodeDouble(f)
	if f == math.huge then
		return "\127\240\0\0\0\0\0\0"
	elseif f == -math.huge then
		return "\255\240\0\0\0\0\0\0"
	elseif f ~= f then
		return "\255\248\0\0\0\0\0\0"
	elseif f == 0 then
		if math.huge/f == math.huge then
			return "\0\0\0\0\0\0\0\0"
		else
			return "\127\0\0\0\0\0\0\0"
		end
	end
	local bits = 64
	local expbits = 11
	local shift = 0
	local significandbits = 52
	local sign = f < 0 and 1 or 0
	local fnorm = f < 0 and -f or f
	while fnorm >= 2 do
		fnorm = fnorm / 2
		shift = shift + 1
	end
	while fnorm < 1 do
		fnorm = fnorm * 2
		shift = shift - 1
	end
	fnorm = fnorm - 1
	local significand = math.floor(fnorm * ((2 ^ significandbits) + 0.5))
	local exp = shift + ((2 ^ (expbits - 1)) - 1)
	return encodeBits(table.cat({sign}, decodeBits(exp, expbits), decodeBits(significand, significandbits)), true)
end

function util.encodeDoubleFFI(n)
	local d = ffi.new("double[1]")
	d[0] = n
	return ffi.string(ffi.cast("const char*", d), 8):reverse()
end

function util.encodeDoubleRaw(sign, exponent, fraction)
	return encodeBits(table.cat({sign}, decodeBits(exponent, 11), decodeBits(fraction, 52)), true)
end

function util.decodeDouble(txt)
	if txt =="\127\240\0\0\0\0\0\0" then
		return math.huge
	elseif txt == "\255\240\0\0\0\0\0\0" then
		return -math.huge
	elseif txt == "\255\248\0\0\0\0\0\0" then
		return 0 / 0
	elseif txt == "\0\0\0\0\0\0\0\0" then
		return 0
	elseif txt == "\127\0\0\0\0\0\0\0" then
		return -0
	end
	local data = decodeBits(txt)
	local bits = 64
	local expbits = 11
	local significandbits = 52
	local result = encodeBits(table.sub(data, -significandbits, -1))
	result = (result / (2 ^ significandbits)) + 1
	local bias = (2 ^ (expbits - 1)) - 1
	shift = encodeBits(table.sub(data, 2, bits - (significandbits))) - bias
	for l1=1, shift do
		result=result * 2
	end
	for l1 = -1, shift, -1 do
		result = result / 2
	end
	return result * (data[1] == 0 and 1 or -1)
end

function util.decodeDoubleFFI(txt)
	return ffi.cast("double*", ffi.new("const char*", txt:reverse()))[0]
end

function util.decodeDoubleRaw(txt)
	local data=decodeBits(txt)
	return data[1], encodeBits(table.sub(data, 2, 64-(52))), encodeBits(table.sub(data, -52, -1))
end

--[=[ recursiveless serialization
function util.serialize(t, prefs)
	local o = ""
	local q = {{t}}
	while #q > 0 do
		local c = q[#q]
		table.remove(q)

		if c[3] then
			o = o .. c[3]
		end

		local t = type(c[1])
		if t == "table" then
			o = o .. "{"
			local idx = 1
			if not next(c[1]) then
				o = o .. "}"
			end

			local cidx = #q + 1

			local append = c[2] or ""
			c[2] = nil

			for k, v in pairs(c[1]) do
				if k == idx then
					idx = idx + 1
				else
					table.insert(q, cidx, {k, "]=", "["})
				end

				if next(c[1], k) then
					table.insert(q, cidx, {v, ","})
				else
					table.insert(q, cidx, {v, "}" .. append})
				end
			end
		elseif t == "number" or t == "boolean" or t == "nil" then
			o = o .. tostring(c[1])
		elseif t == "string" then
			o = o .. string.format("%q", c[1]):gsub("\\\n","\\n"):gsub("%z","\\z")
		else
			o = o .. "nil --[[" .. tostring(c[1]) .. "]]"
		end

		if c[2] then
			o = o .. c[2]
		end
	end
	return o
end--]=]

function util.serialize(value, pretty)
	local kw = {
		["and"]=true,["break"]=true, ["do"]=true, ["else"]=true,
		["elseif"]=true, ["end"]=true, ["false"]=true, ["for"]=true,
		["function"]=true, ["goto"]=true, ["if"]=true, ["in"]=true,
		["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
		["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
		["until"]=true, ["while"]=true
	}
	local id = "^[%a_][%w_]*$"
	local ts = {}
	local function s(v, l)
		local t = type(v)
		if t == "nil" then
			return "nil"
		elseif t == "boolean" then
			return v and "true" or "false"
		elseif t == "number" then
			if v ~= v then
				return "0/0"
			elseif v == math.huge then
				return "math.huge"
			elseif v == -math.huge then
				return "-math.huge"
			else
				return tostring(v)
			end
		elseif t == "string" then
			local o=string.format("%q", v):gsub("\\\n","\\n"):gsub("%z","\\z")
			return o
		elseif t == "table" and pretty and getmetatable(v) and getmetatable(v).__tostring then
			return tostring(v)
		elseif t == "table" then
			if ts[v] then
				return "recursive"
			end
			ts[v] = true
			local i, r = 1, nil
			local f
			for k, v in pairs(v) do
				if r then
					r = r .. "," .. (pretty and ("\n" .. string.rep(" ", l)) or "")
				else
					r = "{"
				end
				local tk = type(k)
				if tk == "number" and k == i then
					i = i + 1
					r = r .. s(v, l + 1)
				else
					if tk == "string" and not kw[k] and string.match(k, id) then
						r = r .. k
					else
						r = r .. "[" .. s(k, l + 1) .. "]"
					end
					r = r .. "=" .. s(v, l + 1)
				end
			end
			ts[v] = nil -- allow writing same table more than once
			return (r or "{") .. "}"
		elseif t == "function" then
			return "func"
		elseif t == "userdata" then
			return "userdata"
		elseif t == "cdata" then
			return "cd("..serialize(tostring(ffi.typeof(v)):match("^ctype<(.-)>$"))..","..serialize(tob64(ffi.dump(v)))..")"
		else
			if pretty then
				return tostring(t)
			else
				error("unsupported type: " .. t)
			end
		end
	end
	local result = s(value, 1)
	local limit = type(pretty) == "number" and pretty or 10
	if pretty then
		local truncate = 0
		while limit > 0 and truncate do
			truncate = string.find(result, "\n", truncate + 1, true)
			limit = limit - 1
		end
		if truncate then
			return result:sub(1, truncate) .. "..."
		end
	end
	return result
end

function util.unserialize(txt)
	local f

	if not setfenv then
		f = load("return " .. txt, "unserialize", "bt", {})
	else
		f = loadstring("return " .. txt, "unserialize")
	end

	if not f then
		return nil
	end

	if not setfenv then
		return f()
	else
		return setfenv(f, {})()
	end
end

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

function util.pescape(txt)
	local o=txt:gsub("[%.%[%]%(%)%%%*%+%-%?%^%$]","%%%1"):gsub("%z","%%z")
	return o
end

function util.proxy(p, t)
	return setmetatable(p, {__index = t})
end

function util.random(bytes)
	local f = io.open("/dev/urandom", "rb")
	local o = f:read(bytes)
	f:close()
	return o
end

local _tob64 = {
	[0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"0","1","2","3","4","5","6","7","8","9","+","/"
}

local floor = math.floor
local byte = string.byte
local char = string.char
local sub = string.sub

function util.tob64(txt)
	local d, o, d1, d2, d3 = {byte(txt, 1, -1)}, ""
	for l1 = 1, #txt - 2, 3 do
		d1, d2, d3 = d[l1], d[l1 + 1], d[l1 + 2]
		o = o
			.. _tob64[floor(d1 / 4)]
			.. _tob64[((d1 % 4) * 16) + floor(d2 / 16)]
			.. _tob64[((d2 % 16) * 4) + floor(d3 / 64)]
			.. _tob64[d3 % 64]
	end
	local m = #txt % 3
	if m == 1 then
		o = o
			.. _tob64[floor(d[#txt] / 4)]
			.. _tob64[((d[#txt] % 4) * 16)]
			.. "=="
	elseif m == 2 then
		o = o
			.. _tob64[floor(d[#txt - 1] / 4)]
			.. _tob64[((d[#txt - 1] % 4) * 16) + floor(d[#txt] / 16)]
			.. _tob64[(d[#txt] % 16) * 4]
			.. "="
	end
	return o
end

local _unb64 = {
	["A"]=0,["B"]=1,["C"]=2,["D"]=3,["E"]=4,["F"]=5,["G"]=6,["H"]=7,["I"]=8,["J"]=9,["K"]=10,["L"]=11,["M"]=12,["N"]=13,
	["O"]=14,["P"]=15,["Q"]=16,["R"]=17,["S"]=18,["T"]=19,["U"]=20,["V"]=21,["W"]=22,["X"]=23,["Y"]=24,["Z"]=25,
	["a"]=26,["b"]=27,["c"]=28,["d"]=29,["e"]=30,["f"]=31,["g"]=32,["h"]=33,["i"]=34,["j"]=35,["k"]=36,["l"]=37,["m"]=38,
	["n"]=39,["o"]=40,["p"]=41,["q"]=42,["r"]=43,["s"]=44,["t"]=45,["u"]=46,["v"]=47,["w"]=48,["x"]=49,["y"]=50,["z"]=51,
	["0"]=52,["1"]=53,["2"]=54,["3"]=55,["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["+"]=62,["/"]=63,
}

function util.unb64(txt)
	txt = txt:gsub("=+$", "")
	local o, d1, d2 = ""
	local ln = #txt
	local m = ln % 4
	for l1 = 1, ln - 3, 4 do
		d1, d2 = _unb64[sub(txt, l1 + 1, l1 + 1)], _unb64[sub(txt, l1 + 2, l1 + 2)]
		o = o .. char(
			(_unb64[sub(txt, l1, l1)] * 4) + floor(d1 / 16),
			((d1 % 16) * 16) + floor(d2 / 4),((d2 % 4) * 64) + _unb64[sub(txt, l1 + 3, l1 + 3)]
		)
	end
	if m == 2 then
		o = o .. char((_unb64[sub(txt, -2, -2)] * 4) + floor(_unb64[sub(txt, -1, -1)] / 16))
	elseif m == 3 then
		d1 = _unb64[sub(txt, -2, -2)]
		o = o .. char(
			(_unb64[sub(txt, -3, -3)] * 4) + floor(d1 / 16),
			((d1 % 16) * 16) + floor(_unb64[sub(txt, -1, -1)] / 4)
		)
	end
	return o
end

function util.tohex(txt)
	return ({txt:gsub(".",function(c) return string.format("%02x",c:byte()) end)})[1]
end

function util.unhex(txt)
	return ({txt:gsub("%X",""):gsub("%x%x?",function(c) return string.char(tonumber("0x"..c)) end)})[1]
end

function util.where(level)
	local bt = debug.traceback((level or 1) + 1)
	return (bt:match("\n\t([^\n]+)") or "Unknown"):gsub(": in function.+", "")
end

function util.onCollect(t, f)
	local m = getmetatable(t)
	if not m then
		m = setmetatable(t, {})
	end

	if not m.onCollect then
		m.onCollect = {}

		local prox = newproxy(true)
		getmetatable(prox).__gc = function()
			for k, v in pairs(m.onCollect) do
				k(t)
			end
		end

		m[prox] = true
	end

	m.onCollect[f] = true

	return t
end

function util.copy(v)
	if type(v) == "table" then
		local o = {}
		for n, l in pairs(v) do
			o[util.copy(n)] = util.copy(l)
		end
		return o
	end
	return v
end

function util.merge(base, t, except)
	for k, v in pairs(t) do
		if not except or not except[k] then
			if type(base[k]) == "table" then
				util.merge(base[k], v, except)
			elseif base[k] == nil then
				base[k] = v
			end
		end
	end

	return base
end

function util.parseArgs(txt, prefs)
	prefs = prefs or {}

	prefs.escapes = prefs.escapes or {
		a = "\a",
		b = "\b",
		f = "\f",
		n = "\n",
		r = "\r",
		t = "\t",
		v = "\v",
	}

	prefs.escapeChar = prefs.escapeChar or "\\"
	prefs.flagChar = prefs.flagChar or "-"

	local out = {}

	local function readString()
		if txt:sub(1, 1) == "\"" then
			txt = txt:sub(2)
			local str = ""
			while txt:sub(1, 1) ~= "\"" and #txt > 0 do
				if txt == "" then
					return str
				end

				local c = txt:sub(1, 1)
				txt = txt:sub(2)

				if c == "\\" then
					str = str .. (prefs.escapes[txt:sub(1, 1)] or txt:sub(1, 1))
					txt = txt:sub(2)
				else
					str = str .. c
				end
			end

			txt = txt:sub(2)

			return str
		else
			local str = ""

			while txt:sub(1, 1) ~= " " and #txt > 0 do
				str = str .. txt:sub(1, 1)
				txt = txt:sub(2)
			end

			return str
		end
	end

	while true do
		while txt:sub(1, 1) == " " do
			txt = txt:sub(2)
		end

		if #txt == 0 then
			break
		end

		if txt:sub(1, 1) == prefs.flagChar then
			txt = txt:sub(2)

			local key = ""

			while txt:sub(1, 1) ~= "=" and txt:sub(1, 1) ~= " " and #txt > 0 do
				key = key .. txt:sub(1, 1)
				txt = txt:sub(2)
			end

			local value = true

			if txt:sub(1, 1) == "=" then
				txt = txt:sub(2)
				value = readString()
			end

			out[key] = value
		else
			table.insert(out, readString())
		end
	end

	return out
end

function util.gmatch(pattern, txt)
	local o = {}

	for m in txt:gmatch(pattern) do
		table.insert(o, m)
	end

	return o
end

function util.split(txt, delim)
	local buf = ""
	local o = {}

	while #txt > 0 do
		if txt:sub(1, #delim) == delim then
			table.insert(o, buf or "")
			txt = txt:sub(#delim + 1)
			buf = ""
		else
			buf = (buf or "") .. txt:sub(1, 1)
			txt = txt:sub(2)
		end
	end

	if buf then
		table.insert(o, buf)
	end

	return o
end

function util.strdist(s, t)
	local m = #s
	local n = #t
	local d = {}
	for i = 0, m do
		d[i] = {}
		for j = 0, n do
			d[i][j] = 0
		end
	end

	for i = 1, m do
		d[i][0] = i
	end

	for j = 1, n do
		d[0][j] = j
	end

	for j = 1, n do
		for i = 1, m do
			d[i][j] = math.min(
				d[i - 1][j] + 1,
				d[i][j - 1] + 1,
				d[i - 1][j - 1] + (s:sub(i, i) == t:sub(j, j) and 0 or 1)
			)
		end
	end

	return d[m][n]
end

function util.time(s)
	if s==math.huge then
		return "Never"
	elseif s==1/0 or s~=s then
		return "Unknown"
	end
	local sr=""
	if s<0 then
		sr=" ago"
		s=math.abs(s)
	end
	local function c(n)
		local t=floor(s/rt[n])
		if wt[n] then
			t=t%wt[n]
		end
		return t.." "..n..(t>1 and "s" or "")
	end
	if s<1 then
		return c("millisecond")..sr
	elseif s<60 then
		return c("second")..sr
	elseif s<3600 then
		if (s/60<5) then
			return c("minute").." "..c("second")..sr
		end
		return c("minute")..sr
	elseif s<86400 then
		return c("hour").." "..c("minute")..sr
	elseif s<604800 then
		return c("day").." "..c("hour")..sr
	else
		return c("week").." "..c("day")..sr
	end
end

function util.next(t, k)
	return ((getmetatable(t) or {}).__next or next)(t, k)
end

function util.pack(...)
	return {
		...,
		n = select("#", ...),
	}
end

return util