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

event.listen("command", ">", function(txt, message)
	x86.requirePerms(message.member, "alua")
	local chunk, err = loadstring("return " .. txt, "@>")
	if not chunk then
		chunk, err = loadstring(txt, "@>")
	end

	if not chunk then
		return err
	end

	local res = table.pack(xpcall(chunk, debug.traceback))
	if not res[1] then
		return res[2]
	end

	local o = {}
	for i = 2, math.max(2, res.n) do
		table.insert(o, tostring(res[i]))
	end

	return table.concat(o, " | ")
end)