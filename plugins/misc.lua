event.listen("command", "ping", function(txt, message)
	x86.requirePerms(message.member, "pingpong")
	return x86.prefix .. "pong"
end)

event.listen("command", "time", function(txt, message)
	return message.timestamp
end)

event.listen("command", "id", function(txt, message)
	return message.member.id
end)

event.listen("command", "help", function(txt, message)
	return
	[[Available commands:
		]] .. x86.prefix .. [[ : the precursor to all commands
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
		`repeat`: toggle repeating of deleted messages
		`time`: get the timestamp
		`kek`: gets the number of times kek has been said since someone altered my database
		`rekt`: gets the number of times rekt has been said since someone altered my database
		`lol`: gets the number of times Pixel or Hotel said lol since someone altered my database
	]]
end)

event.listen("command", "repeat", function(txt, message)
	x86.requirePerms(message.member, "repeat")
	if x86.repdel[message.channel.guild.id] then
		x86.repdel[message.channel.guild.id] = false
		return "Repeating of deleted messages is now OFF"
	else
		x86.repdel[message.channel.guild.id] = true
		return "Repeating of deleted messages is now ON"
	end
end)
