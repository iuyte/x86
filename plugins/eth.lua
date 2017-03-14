local util = require("util")

event.listen("command", "do", function(txt, message)
	return "NO!"
end)

event.listen("command", "ping", function(txt, message)
	return "pong"
end)

event.listen("command", "eth", function(txt, message)
  x86.requirePerms(message.member, "gud")

	return "I'm not sure what to do (or how to do it)"
end)
