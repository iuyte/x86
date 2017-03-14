event.listen("command", "ping", function(txt, message)
	return "x>pong"
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)
