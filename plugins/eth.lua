local util = require("util")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "pong", function(txt, message)
	return "ping"
end)

event.listen("command", "eth", function(txt, message)
  x86.requirePerms(message.member, "to be gud")

	return "I'm not sure what to do (or how to do it)"
end)

event.listen("command", "help", function(txt, message)
	return "Feel free to help yourself!"
end)
