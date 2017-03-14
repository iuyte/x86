local util = require("util")
local exc = require("exc")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "pong", function(txt, message)
	return "x>ping"
end)

event.listen("command", "pic", function(txt, message)
  x86.requirePerms(message.member, "to be gud")
	local ptxt = util.parseArgs(txt)
	if (ptxt[2] ~= "get" and ptxt[2] ~= "set" and ptxt[2] ~= "remove") or not ptxt[1] then
		return "Commands: you, karthik"
	end
	if ptxt[1] == "you" then
		return "https://www.vexforum.com/index.php/attachment/571ea8d9f093f_Capture.JPG"
	elseif ptxt[1] == "karthik" then
		return"https://i.ytimg.com/vi/hF9GiTlG-Go/maxresdefault.jpg"
	else
		return "Please choose either me or karthik"
	end
end)

event.listen("command", "help", function(txt, message)
	return "Feel free to help yourself!"
end)
