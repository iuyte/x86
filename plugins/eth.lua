local util = require("util")
local exc = require("exc")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "pong", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return x86.prefix .. "ping"
end)

event.listen("command", "thank", function(txt, message)
	local ptxt = util.parseArgs(txt)
	if not ptxt[1] then
		return "thank who?"
	end
	local n = math.min(1, 1000)
	while n > 0 do
		message.channel:bulkDelete(math.min(n, 100))
		n = n - 100
	end
	local ndres = "I'd like to give a huge thank you to "
	local spacer = " and "
	ndres = ndres .. ptxt[1]
	for i = 2, #ptxt do
		ndres = ndres .. spacer .. ptxt[i]
	end
	return ndres
end)

event.listen("command", "picture", function(txt, message)
  x86.requirePerms(message.member, "to be gud")
	local ptxt = util.parseArgs(txt)
	if (ptxt[1] ~= "you" and ptxt[1] ~= "karthik") or not ptxt[1] then
		return "Commands: you, karthik"
	end
	if ptxt[1] == "you" then
		return "https://www.vexforum.com/index.php/attachment/571ea8d9f093f_Capture.JPG"
	elseif ptxt[1] == "karthik" then
		return "https://i.imgur.com/JtaQliK.jpg"
	else
		return "Please choose either me or karthik"
	end
end)

event.listen("command", "say", function(txt, message)
	x86.requirePerms(message.member, "can say")
	local n = math.min(1, 1000)
	while n > 0 do
		message.channel:bulkDelete(math.min(n, 100))
		n = n - 100
	end
	local ndres = ""
	local spacer = " "
	local ptxt = util.parseArgs(txt)
	for i = 1, #ptxt do
		ndres = ndres .. spacer .. ptxt[i]
	end
	return ndres
end)

event.listen("command", "kek", function(txt, message)
	return "kek has been said " .. tostring(x86.kek["kekcount"]) .. " times!"
end)
