event.listen("command", "pong", function(txt, message)
	return "ping"
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)

event.listen("command", "do", function(txt, message)
	return "NO!"
end)
