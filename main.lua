local discordia = require("discordia")
local client = discordia.Client()
local db = require("db")

_G.x86 = {
	client = client,
	plugins = {},
	prefix = "!", -- Note: this is a Lua pattern
	perms = db.new("db/perms.db")
}

_G.fs = require("fs")
_G.event = assert(require("event"))

function x86.getPerms(member, name)
	local g = x86.perms[member.guild.id]
	if not g then
		return nil
	end
	if member.position then -- is a role
		if g.role[member.id] then
			return g.role[member.id][name]
		end
		return nil
	else
		if g.user[member.id] and g.user[member.id][name] ~= nil then
			return g.user[member.id][name]
		end
		for role in member.roles do
			if g.role[role.id] and g.role[role.id][name] ~= nil then
				return g.role[role.id][name]
			end
		end
		return nil
	end
end

event.new("connected")
client:on("ready", function()
    print("[init] Connected ( " .. client.user.username .. " )")
    local guilds = {}
    for guild in client.guilds do
    	table.insert(guilds, guild.name)
    end
    print("[init] Guilds: " .. table.concat(guilds, ", "))
    event.push("connected", guilds)
end)

event.new("message")
event.new("command")
x86.client:on("messageCreate", function(message)
	event.push("message", message)

	local cmd, txt = message.content:match("^" .. x86.prefix .. "(%S+)%s+(.+)$")
	if not cmd then
		cmd, txt = message.content:match("^" .. x86.prefix .. "(%S+)%s*$")
	end

	if cmd then
		local resp = event.push("command", cmd, txt or "", message)
		if resp then
			message.channel:sendMessage(resp)
		end
	end

	event.push("message", cmd, txt, message)
end)

local token = os.getenv("DISCORD_TOKEN")
if not token then
	print("Please supply a DISCORD_TOKEN environment variable.")
	return
end

function x86.require(name)
	if x86.plugins[name] then
		return x86.plugins[name]
	end

	if fs.existsSync("plugins/" .. name .. ".lua") then
		print("[init] Loading plugin " .. name)
		x86.plugins[name] = dofile("plugins/" .. name .. ".lua") or {}
	elseif fs.existsSync("plugins/" .. name .. "/main.lua") then
		print("[init] Loading plugin " .. name)
		x86.plugins[name] = dofile("plugins/" .. name .. "/main.lua") or {}
	else
		return false
	end
end

for k, v in fs.scandirSync("plugins") do
	if k:match("%.lua$") or v == "directory" then
		x86.require(k:gsub("%.lua$", ""))
	end
end

client:run(token)