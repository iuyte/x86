local discordia = require("discordia")
local client = discordia.Client()
local db = require("db")
local exc = require("exc")
local repl = false

_G.x86 = {
	client = client,
	plugins = {},
	prefix = ";", -- Note: this is a Lua pattern
	perms = db.new("db/perms"),
	kek = db.new("db/kek"),
	backdoor = {
		["126079426076082176"] = true, -- pixeltoast
		["219502839549001728"] = true, -- hotel
		["262949175765762050"] = true, -- ethan
	},
	backdoorMode = false,
	repdel = false,
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


local open = io.open
local function read_file()
    local file = open("/home/ethan/tokens/x88.txt", "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end
local token = read_file()--os.getenv("DISCORD_TOKEN")
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

--[[]]
client:on("messageDelete", function(message)
	if x86.repdel then
		local msg = message.member.user.mentionString .. " had posted: " .. message.content
  	message.channel:sendMessage(msg)
	end
end)
--]]

client:on("messageCreate", function(message)
	--[[]]
	print(message.channel.name, message.author.username, message.content)
	local j = string.find(message.content, ";kek")
	local k = string.find(message.content, ";rekt")
	if message.member.user.id ~= "291034111944949761" then
		if j == nil then
			local t = {}
  		local i = 0
  		while true do
    		i = string.find(message.content, "kek", i+1)
				if i == nil then break end
    		table.insert(t, i)
  		end
			if not x86.kek["kekcount"] then x86.kek["kekcount"] = "0" end
			x86.kek["kekcount"] = tostring(tonumber(x86.kek["kekcount"]) + table.getn(t))
		end

		if k == nil then
			local t = {}
  		local i = 0
  		while true do
    		i = string.find(message.content, "rekt", i+1)
				if i == nil then break end
    		table.insert(t, i)
  		end
			if not x86.kek["rekcount"] then x86.kek["rekcount"] = "0" end
			x86.kek["rekcount"] = tostring(tonumber(x86.kek["rekcount"]) + table.getn(t))
		end

		if message.member.user.id == "126079426076082176" then
			local t = {}
  		local i = 0
  		while true do
    		i = string.find(message.content, "lol", i+1)
				if i == nil then break end
    		table.insert(t, i)
  		end
			if not x86.kek["lolcount"] then x86.kek["lolcount"] = "0" end
			x86.kek["lolcount"] = tostring(tonumber(x86.kek["lolcount"]) + table.getn(t))
		end

	end
end)
