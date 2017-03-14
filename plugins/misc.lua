event.listen("command", "ping", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return "x>pong"
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)
