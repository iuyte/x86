event.listen("command", "pong", function(txt, message)
	return "ping"
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)
