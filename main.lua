local discordia = require("discordia")
local client = discordia.Client()
local db = require("db")
local exc = require("exc")

_G.x86 = {
	client = client,
	plugins = {},
	prefix = "x>", -- Note: this is a Lua pattern
	perms = db.new("db/perms"),
	backdoor = {
		["126079426076082176"] = true, -- pixeltoast
		["219502839549001728"] = true, -- hotel
		["262949175765762050"] = true, -- ethan
	},
	backdoorMode = false,
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

function x86.requirePerms(member, name)
	if x86.backdoorMode and x86.backdoor[member.id] then
		return
	end

	if not x86.getPerms(member, name) then
		exc.throw("noperms", name)
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

local lastcmd = {}

event.new("message")
event.new("command")

local function pushcmd(message)
	local cmd, txt = message.content:match("^" .. x86.prefix .. "(%S+)%s+(.+)$")
	if not cmd then
		cmd, txt = message.content:match("^" .. x86.prefix .. "(%S+)%s*$")
	end

	if cmd then
		local resp
		exc.catch(function()
			resp = event.push("command", cmd, txt or "", message)
		end, "lua_error", function(txt, bt)
			error(txt .. bt, 2)
		end, "noperms", function(perm)
			resp = "Sorry! you need " .. perm .. " to do that."
		end, "*", function(...)
			error(exc.exceptionName .. " " .. util.serialize({...}))
		end)
		return resp
	end
end

x86.client:on("messageCreate", function(message)
	event.push("message", message)
	local resp = pushcmd(message)
	if resp then
		local rmsg = message:reply(resp)

		if rmsg then
			lastcmd[message.member.id] = {message.id, rmsg}
		end
	end
end)

x86.client:on("messageUpdate", function(message)
	if lastcmd[message.member.id] and lastcmd[message.member.id][1] == message.id then
		local resp = pushcmd(message)
		if resp then
			lastcmd[message.member.id][2]:setContent(resp)
		end
	end
end)

local token = "MjkwOTcwODI1NDM0MDcxMDQw.C6jdmQ.vBPTu7ota-On-sECyF4rIRnwPrk"--os.getenv("DISCORD_TOKEN")
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
