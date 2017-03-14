local util = require("util")
local exc = require("exc")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "pong", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return "x>ping"
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
	local ndres = "THANK YOU SO MUCH "
	local spacer = " and "
	ndres = ndres .. ptxt[1]
	if ptxt[3] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[3]
	end
	if ptxt[5] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[5]
	end
	if ptxt[7] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[7]
	end
	if ptxt[9] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[9]
	end
	return ndres
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
	local n = math.min(1, 1000)
	while n > 0 do
		message.channel:bulkDelete(math.min(n, 100))
		n = n - 100
	end
	local ndres = ""
	local spacer = " "
	local ptxt = util.parseArgs(txt)
	if ptxt[1] then
		ndres = ndres .. ptxt[1]
	end
	if ptxt[2] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[2]
	end
	if ptxt[3] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[3]
	end
	if ptxt[4] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[4]
	end
	if ptxt[5] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[5]
	end
	if ptxt[5] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[5]
	end
	if ptxt[6] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[6]
	end
	if ptxt[7] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[7]
	end
	if ptxt[8] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[8]
	end
	if ptxt[9] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[9]
	end
	if ptxt[10] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[10]
	end
	if ptxt[11] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[11]
	end
	if ptxt[12] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[12]
	end
	if ptxt[13] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[13]
	end
	if ptxt[14] then
		ndres = ndres .. spacer
		ndres = ndres .. ptxt[14]
	end
	return ndres
end)
