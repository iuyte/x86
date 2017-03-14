event.listen("command", "ping", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return "x>pong"
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)

event.listen("command", "help", function(txt, message)
	return
	[[Available commands:
		`x>`: the precursor to all commands
		`help`: display this
		`id`: return the id of the user
		`ping`: pong
		`pong`: ping
		`perms <user> (get/set/remove) <permission>`: assignes permissions stored in a database
		`say <anything>`: makes me say something
		`thank <any number of anything>`: thanks something/someone
		`picture (karthik/you)`: get a picture of me, or karthik
		`do <something>`: NO
		`purge <# of messages>`: purges the specified # of messages
	]]
end)
