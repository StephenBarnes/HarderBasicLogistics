
local blockingType = settings.startup["HarderBasicLogistics-inserter-placement-blocking"].value
-- We could make this a runtime setting, not a startup setting. However, then we would need to register an event handler even when this blocking is turned off, so rather don't do that.

local lastMessageTick = 0
local messageWaitTicks = 15 -- Don't show message if a message was already shown within this many ticks ago.

function posEqual(p1, p2)
	return p1.x == p2.x and p1.y == p2.y
end

function blockablePositions(pos)
	if blockingType == "block-4" then
		return {
			{pos.x+1, pos.y},
			{pos.x-1, pos.y},
			{pos.x, pos.y+1},
			{pos.x, pos.y-1},
		}
	elseif blockingType == "block-8" then
		return {
			{pos.x+1, pos.y},
			{pos.x-1, pos.y},
			{pos.x, pos.y+1},
			{pos.x, pos.y-1},

			{pos.x+1, pos.y+1},
			{pos.x+1, pos.y-1},
			{pos.x-1, pos.y+1},
			{pos.x-1, pos.y-1},
		}
	elseif blockingType == "block-cross-5-5" then
		return {
			{pos.x+1, pos.y},
			{pos.x-1, pos.y},
			{pos.x, pos.y+1},
			{pos.x, pos.y-1},

			{pos.x+2, pos.y},
			{pos.x-2, pos.y},
			{pos.x, pos.y+2},
			{pos.x, pos.y-2},
		}
	else
		game.print("ERROR: Unknown inserter blocking type")
	end
end

function findBlockingEntity(inserter)
	for _, pos in ipairs(blockablePositions(inserter.position)) do
		local entities = inserter.surface.find_entities_filtered {
			position = pos,
			type = "inserter",
			limit = 1,
		}
		if #entities > 0 then
			return entities[1]
		end
	end
	return nil
end

local function maybeBlockPlayerPlacement(event)
	local placed = event.created_entity
	local blockedBy = findBlockingEntity(placed)
	if blockedBy == nil then return end

	local player = game.get_player(event.player_index)
	if player == nil then
		log("Player is nil")
		return
	end
	if game.tick > lastMessageTick + messageWaitTicks then
		lastMessageTick = game.tick
		player.create_local_flying_text {
			text = {"cant-build-reason.entity-in-the-way", {"entity-name."..blockedBy.name}},
			create_at_cursor = true,
			time_to_live = 120,
		}
	end
	player.mine_entity(placed, true) -- "true" says force mining it even if player's inventory is full.
end

local function maybeBlockRobotPlacement(event)
	local placed = event.created_entity
	local blockedBy = findBlockingEntity(placed)
	if blockedBy == nil then return end

	local surface = placed.surface
	local pos = placed.position
	placed.destroy()
	surface.spill_item_stack(pos, event.stack, nil, event.robot.force)
		-- Force arg is to mark the spilled item stack for deconstruction by the robot's force.
end

if blockingType ~= "allow-all" then
	script.on_event(defines.events.on_built_entity, maybeBlockPlayerPlacement, {{filter="type", type="inserter"}})
	script.on_event(defines.events.on_robot_built_entity, maybeBlockRobotPlacement, {{filter="type", type="inserter"}})
end