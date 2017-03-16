local util = require("util")

event.listen("command", "backdoor", function(txt, message)
	if not x86.backdoor[message.member.id] then
		return "Sorry! You are not on the backdoor list."
	end
	if x86.backdoorMode then
		x86.backdoorMode = false
		return "Backdoor mode OFF"
	else
		x86.backdoorMode = true
		return "Backdoor mode ON"
	end
end)

local aluaEnv = setmetatable({
	util = util,
	exc = require("exc"),
	event = require("event"),
}, {
	__index = _G,
	__newindex = _G,
})

event.listen("command", "frontdoor", function(txt, message)
	if not x86.backdoorMode then
		return "The frontdoor is locked."
	else
		return "The frontdoor was left unlocked! You may now proceed inside."
	end
end)

event.listen("command", ">", function(txt, message)
	x86.requirePerms(message.member, "alua")
	local chunk, err = loadstring("return " .. txt, "@>")
	if not chunk then
		chunk, err = loadstring(txt, "@>")
	end

	if not chunk then
		return err
	end

	aluaEnv.message = message
	aluaEnv.member = message.member
	aluaEnv.user = message.member.user
	aluaEnv.guild = message.guild
	aluaEnv.channel = message.channel

	local res = table.pack(xpcall(setfenv(chunk, aluaEnv), debug.traceback))
	if not res[1] then
		return res[2]
	end

	local o = {}
	for i = 2, math.max(2, res.n) do
		table.insert(o, tostring(res[i]))
	end

	return table.concat(o, " | ")
end)

event.listen("command", "purge", function(txt, message)
	x86.requirePerms(message.member, "purge")
	local repdelS = x86.repdel
	x86.repdel = false
	local n = tonumber(txt)
	if not n or n ~= n or math.floor(n) ~= n or n < 0 or n == math.huge then
		return "Usage: " .. x86.p.prefix .. "purge <number> ( max 1000 )"
	end
	n = math.min(n, 1000)
	while n > 0 do
		message.channel:bulkDelete(math.min(n, 100))
		n = n - 100
	end
	x86.repdel = repdelS
end)

event.listen("command", "ring", function(txt, message)
	return "DING DONG\n```\n............\n```\nThere's no response"
end)
