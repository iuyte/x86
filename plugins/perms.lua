local util = require("util")
local exc = require("exc")

event.listen("command", "perms", function(txt, message)
	if not message.member then
		return "This command cannot be used in a PM."
	end

	local ptxt = util.parseArgs(txt)
	if (ptxt[2] ~= "get" and ptxt[2] ~= "set" and ptxt[2] ~= "remove") or not ptxt[1] then
		return "Usage: " .. x86.prefix .. "perms <user/role> <command> ... | Commands: get, set, remove"
	end

	local user
	if ptxt[1] == "me" then
		user = message.member
	else
		local closest
		local closestn
		for cuser in message.member.guild.members do
			if
				ptxt[1] == cuser.id or
				ptxt[1] == cuser.name or
				ptxt[1] == cuser.nickname or
				ptxt[1] == cuser.user.mentionString
			then
				user = cuser
				break
			elseif (cuser.nickname or cuser.name):lower():sub(1, #ptxt[1]) == ptxt[1]:lower() then
				if not closest or #ptxt[1] > closestn then
					closestn = #ptxt[1]
					closest = cuser
				end
			end
		end
		user = user or closest
	end
	local role
	do
		local closest
		local closestn
		for crole in message.member.guild.roles do
			if
				ptxt[1] == crole.id or
				ptxt[1] == crole.name or
				ptxt[1] == crole.mentionString
			then
				role = crole
				break
			elseif crole.name:lower():sub(1, #ptxt[1]) == ptxt[1]:lower() then
				if not closest or #ptxt[1] > closestn then
					closestn = #ptxt[1]
					closest = crole
				end
			end
		end
		role = role or closest
	end

	if not user and not role then
		return "Could not find user or role \"" .. ptxt[1] .. "\""
	end

	if ptxt[2] == "get" then
		x86.requirePerms(message.member, "perms:get")
		if ptxt[4] then -- too many args
			return "Usage: " .. x86.prefix .. "perms get <user/role> [perm]"
		end
		local g = x86.perms[message.member.guild.id]
		if ptxt[3] then
			local p = x86.getPerms(user or role, ptxt[3])
			if p then
				return (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " )" .. " -> " .. ptxt[3] .. " = " .. util.serialize(p)
			else
				if user then
					return "No perm \"" .. ptxt[3] .. "\"for user " .. user.nickname .. " ( " .. user.name .. "#" .. user.discriminator .. " )"
				else
					return "No perm \"" .. ptxt[3] .. "\"for role " .. role.name
				end
			end
		elseif user then
			if not g then
				return "No perms for user " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " )"
			end
			local uperms = g.user[user.id] or {}
			local gperms = {}
			for crole in user.roles do
				if g.role[crole.id] then
					local og = {}
					for k, v in pairs(g.role[crole.id]) do
						if uperms[k] == nil then
							og[k] = v
						end
					end
					if next(og) then
						gperms[crole.name] = og
					end
				end
			end
			if not util.next(uperms) and not util.next(gperms) then
				return "No perms for user " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " )"
			end
			local o = "Perms for user " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " ) :\n"
			for k, v in pairs(uperms) do
				o = o .. "    " .. k .. " = " .. util.serialize(v) .. "\n"
			end
			for k, v in pairs(gperms) do
				o = o .. "    From " .. k .. ":\n"
				for n, l in pairs(v) do
					o = o .. "        " .. n .. " = " .. util.serialize(l) .. "\n"
				end
			end
			return o
		else
			if not g or not g.roles[role.id] then
				return "No perms for group " .. group.name
			end
			local o = "Perms for role " .. role.name .. ":\n"
			for k, v in pairs(g.roles[role.id]) do
				o = o .. "    " .. k .. " = " .. util.serialize(v) .. "\n"
			end
			return o
		end
	elseif ptxt[2] == "set" then
		x86.requirePerms(message.member, "perms:set")
		if not ptxt[4] or ptxt[5] then
			return "Usage: " .. x86.prefix .. "perms set <user/role> perm value"
		end
		x86.perms[message.member.guild.id] = x86.perms[message.member.guild.id] or {role = {}, user = {}}
		local g = x86.perms[message.member.guild.id]
		if user then
			g.user[user.id] = g.user[user.id] or {}
			g.user[user.id][ptxt[3]] = ptxt[4]
			return "Set " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " ) -> " .. ptxt[3] .. " = " .. util.serialize(ptxt[4])
		else
			g.role[role.id] = g.role[role.id] or {}
			g.role[role.id][ptxt[3]] = ptxt[4]
			return "Set " .. role.name .. " -> " .. ptxt[3] .. " = " .. util.serialize(ptxt[4])
		end
	elseif ptxt[2] == "remove" then
		x86.requirePerms(message.member, "perms:remove")
		if ptxt[4] then
			return "Usage: " .. x86.prefix .. "perms set <user/role> perm value"
		end
		local g = x86.perms[message.member.guild.id]
		if g then
			if user then
				for k, v in util.pairs(g.user[user.id]) do
					if not ptxt[3] or k == ptxt[3] then
						g.user[user.id][k] = nil
					end
				end
				if not util.next(g.user[user.id]) then
					g.user[user.id] = nil
				end
			else
				for k, v in util.pairs(g.role[role.id]) do
					if not ptxt[3] or k == ptxt[3] then
						g.role[role.id][k] = nil
					end
				end
				if not util.next(g.role[role.id]) then
					g.role[role.id] = nil
				end
			end
			if not util.next(g.user) and not util.next(g.role) then
				x86.perms[message.member.guild.id] = nil
			end
		end
		
		if ptxt[3] then
			if user then
				return "Set " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " ) -> " .. ptxt[3] .. " = nil"
			else
				return "Set " .. role.name .. " -> " .. ptxt[3] .. " = nil"
			end
		else
			if user then
				return "Set " .. (user.nickname or user.name) .. " ( " .. user.name .. "#" .. user.discriminator .. " ) = nil"
			else
				return "Set " .. role.name .. " = nil"
			end
		end
	end
end)