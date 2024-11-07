local ecr = require("packages/ecr")

local pc = require("shared/pc")
local zap = require("shared/zap/server")
local zapqueue = require("shared/zap/queue")
local serde = require("shared/serde")

local world = require("server/world")

--[[
	Component names that do not replicate (i.e. replicate at 0 Hz)
	```
	local hz0: Array<string> = {
		"BobComponent",
		"AliceComponent"
	}
	```
]]
local hz0: Array<string> = {
	
}

--[[
	Component names that only replicate their addition (to entities) and changes, but not removal
	```
	local add_only: Array<string> = {
		"BobComponent",
		"AliceComponent"
	}
	```
]]
local add_only: Array<string> = {
	
}

--[[
	Component names that replicate over UDP (unreliable)
	```
	local udp: Array<string> = {
		"BobComponent",
		"AliceComponent"
	}
	```
]]
local udp: Array<string> = {
	
}

--[[
	Creates an empty diff table using components found in the definition file.
	@param include whitelist for component names to include
	@return the empty diff table
]]
local function diff_table(include: {string}?): pc.WorldDiff
	local diff = {} do
		diff.changes = {}
		for cname in next, pc do
			if include and not table.find(include, cname) then
				continue
			end

			diff.changes[cname] = {
				added_or_changed = {
					entities = {},
					values = {}
				},
				removed = {}
			}
		end
		diff.destroyed = {}
	end

	return diff
end

--[[
	Returns a function that, when invoked, replicates changes in the world to clients.
	@return the replication function
]]
local function delta_context(): () -> ()
	local context = world:context()

	local updated_ffl = {} :: Map<string, Map<ecr.entity, unknown>>

	for cname, ctype in next, pc do
		local updated = {}
		updated_ffl[cname] = updated

		if table.find(hz0, cname) then continue end

		if ecr.is_tag(ctype) then
			world:on_add(ctype):connect(function(id)
				updated[id] = true
			end)
		else
			world:on_add(ctype):connect(function(id, value)
				updated[id] = value
			end)

			world:on_change(ctype):connect(function(id, value)
				updated[id] = value
			end)
		end

		if table.find(add_only, cname) then continue end
		
		world:on_remove(ctype):connect(function(id)
			updated[id] = "remove"
		end)
	end

	return function()
		local diff = diff_table()
		local udp_diff = diff_table(udp)

		for cname, updated in updated_ffl do
			local is_tag = ecr.is_tag(pc[cname])
			local serialize = serde.ser[cname]

			for id, value in updated do
				local changes = diff.changes[cname]

				if value == "remove" then
					if world:contains(id) then
						table.insert(changes.removed, id)
					else
						table.insert(diff.destroyed, id)
					end
				else
					if table.find(udp, cname) then
						changes = udp_diff.changes[cname]
					end

					table.insert(changes.added_or_changed.entities, id)
					if not is_tag then
						table.insert(changes.added_or_changed.values,
							if serialize then serialize(value) else value)
					end
				end
			end
		end

		-- tcp diff
		if next(diff.changes) or next(diff.destroyed) then
			zap.replicate_world.fire_list(context:get(pc.ConnectedPlayers), diff)
		end
		
		-- udp diff
		if next(udp_diff.changes) or next(udp_diff.destroyed) then
			zap.udp_replicate_world.fire_list(context:get(pc.ConnectedPlayers), udp_diff)
		end

		for _, updated in updated_ffl do
			table.clear(updated)
		end
	end
end

--[[
	Replicates the entire world to a player.
	@param player the player to replicate to
	@return the replication function
]]
local function full_context(player: Player)
	local diff = diff_table()

	for cname, ctype in next, pc do
		local is_tag = ecr.is_tag(ctype)
		local serialize = serde.ser[cname]
		local changes = diff.changes[cname]

		if table.find(hz0, cname) then continue end

		for id, value in world:view(ctype) do
			table.insert(changes.added_or_changed.entities, id)
			if not is_tag then
				table.insert(changes.added_or_changed.values,
					if serialize then serialize(value) else value)
			end
		end
	end

	zap.replicate_world.fire(player, diff)
end

local context = delta_context()

--[[
	Queue for new clients that are ready to recieve the initial context (world)
]]
local client_ready = zapqueue(zap.client_ready)

--[[
	Replicates the entire world to new players, and the change in the world for existing ones.
	@param dt deltatime
]]
return function(dt: number)
	for player in client_ready do
		full_context(player)
	end

	context()
end