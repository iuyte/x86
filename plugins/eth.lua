local util = require("util")
local exc = require("exc")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "pong", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return "x>ping"
end)

event.listen("command", "pic", function(txt, message)
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

event.listen("command", "help", function(txt, message)
	return "Feel free to help yourself!"
end)

event.listen("command", "say", function(txt, message)
	x86.requirePerms(message.member, "can say")
	local ndres = ""
	local ptxt = util.parseArgs(txt)
	if ptxt[1] then
		ndres = ndres .. ptxt[1]
	end
	if ptxt[2] then
		ndres = ndres .. " "
		ndres = ndres .. ptxt[2]
	end
	if ptxt[3] then
		ndres = ndres .. " "
		ndres = ndres .. ptxt[3]
	end
	if ptxt[4] then
		ndres = ndres .. " "
		ndres = ndres .. ptxt[4]
	end
	if ptxt[5] then
		ndres = ndres .. " "
		ndres = ndres .. ptxt[5]
	end
	return ndres
end)
