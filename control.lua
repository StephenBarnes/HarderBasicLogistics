
local blockingType = settings.startup["HarderBasicLogistics-inserter-placement-blocking"].value
-- We could make this a runtime setting, not a startup setting. However, then we would need to register an event handler even when this blocking is turned off, so rather don't do that.

local placementBlockingBurnerInserters = settings.startup["HarderBasicLogistics-placement-blocking-burner-inserters"].value

local lastMessageTick = 0
local messageWaitTicks = 5 -- Don't show message if a message was already shown within this many ticks ago.

local function blockablePositions(entity)
	-- Returns a list of positions where entities could block placement of the given entity.
	local pos = entity.position
	if blockingType == "block-4" or blockingType == "block-perpendicular-2" then
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
	elseif blockingType == "block-cross-5-5" or blockingType == "block-perpendicular-4" then
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
	elseif blockingType == "block-distance-2" then
		return {
			{pos.x+1, pos.y},
			{pos.x-1, pos.y},
			{pos.x, pos.y+1},
			{pos.x, pos.y-1},

			{pos.x+2, pos.y},
			{pos.x-2, pos.y},
			{pos.x, pos.y+2},
			{pos.x, pos.y-2},

			{pos.x+1, pos.y+1},
			{pos.x+1, pos.y-1},
			{pos.x-1, pos.y+1},
			{pos.x-1, pos.y-1},
		}
	else
		game.print("ERROR: Unknown inserter blocking type")
	end
end

local function dirAxis(dir)
	-- Returns true if dir is up/down, false if it's left/right. For comparing axes for perpendicular placement restrictions.
	return dir == defines.direction.north or dir == defines.direction.south
end
local function posDeltaAxis(pos1, pos2)
	-- Returns true if pos1 is up/down from pos2, false otherwise. For comparing axes for perpendicular placement restrictions.
	return pos1.y == pos2.y
end

local function entityBlocksPlacement(entity, otherEntity)
	-- Returns whether the given entity blocks the placement of the other entity.
	-- This is only called for entities that are already known to be in one of the "blockable positions".
	-- So this function only checks that the entity isn't exempt (because it's a burner), and then does rotation-dependent checks.
	if (not placementBlockingBurnerInserters) and entity.name == "burner-inserter" then
		return false
	end
	if blockingType == "block-perpendicular-2" or blockingType == "block-perpendicular-4" then
		-- Get facing of each inserter.
		axis1 = dirAxis(entity.direction)
		axis2 = dirAxis(otherEntity.direction)
		if axis1 ~= axis2 then return true end -- at least one of them must be blocking the other one.
		-- If they're on the same axis, they might block each other.
		return axis1 == posDeltaAxis(entity.position, otherEntity.position)
	end
	return true
end

local function findBlockingEntity(inserter)
	for _, pos in ipairs(blockablePositions(inserter)) do
		local entities = inserter.surface.find_entities_filtered {
			position = pos,
			type = "inserter",
			limit = 1,
		}
		for _, entity in ipairs(entities) do
			if entityBlocksPlacement(entity, inserter) then
				return entity
			end
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

local function blockingAppliesToEntity(entity)
	-- Given an arbitrary entity, returns whether it can be blocked by the placement restrictions.
	return (entity.type == "inserter") and ((not placementBlockingBurnerInserters) or entity.name ~= "burner-inserter")
end

local function maybeBlockPlayerRotation(event)
	local entity = event.entity
	if not blockingAppliesToEntity(entity) then return end -- necessary because we can't use event filters for the rotation event.
	local blockedBy = findBlockingEntity(entity)
	if blockedBy == nil then return end

	local player = game.get_player(event.player_index)
	if player == nil then
		log("Player is nil")
	else
		if game.tick > lastMessageTick + messageWaitTicks then
			lastMessageTick = game.tick
			player.create_local_flying_text {
				text = {"cant-build-reason.entity-in-the-way", {"entity-name."..blockedBy.name}},
				create_at_cursor = true,
				time_to_live = 120,
			}
		end
	end
	-- Rotate it back, by flipping it.
	entity.direction = event.previous_direction
end

local function maybeBlockRobotPlacement(event)
	local placed = event.created_entity
	local blockedBy = findBlockingEntity(placed)
	if blockedBy == nil then return end

	-- This event is caused by multiple situations:
	-- The robot placed a new entity on empty land. We can just destroy it and spill the same stack used to build it.
	-- The robot rotated an entity in-place. We can't rotate it back, so we need to make a new item stack and spill it.
	-- The robot upgraded an entity (eg a burner inserter), perhaps with rotation. We can treat this the same as the placed-new-entity case, because the vanilla game already puts the replaced item in the robot's inventory. So we just destroy the placed entity and spill the stack used to upgrade it (the new item).
	-- From testing, all these cases work fine.

	local surface = placed.surface
	local pos = placed.position

	if event.stack ~= nil and event.stack.valid_for_read then
		game.print(math.random().."A")
		placed.destroy()
		surface.spill_item_stack(pos, event.stack, nil, event.robot.force)
		-- Force arg is to mark the spilled item stack for deconstruction by the robot's force.
	else
		game.print(math.random().."B")
		local newStack = {name=placed.name, count=1}
		placed.destroy()
		surface.spill_item_stack(pos, newStack, nil, event.robot.force)
	end

	if game.tick > lastMessageTick + messageWaitTicks then
		lastMessageTick = game.tick
		surface.create_entity {
			name = "flying-text",
			position = pos,
			text = {"cant-build-reason.entity-in-the-way", {"entity-name."..blockedBy.name}},
			time_to_live = 40,
		}
	end
end

local function getEventFilters()
	-- TODO also listen to placement of assemblers etc. if one-per-side is enabled.
	if placementBlockingBurnerInserters then
		return {{filter="type", type="inserter"}}
	else
		return {
			{filter="type", type="inserter"},
			{filter="name", name="burner-inserter", invert=true, mode="and"},
		}
	end
end

if blockingType ~= "allow-all" then
	local eventFilters = getEventFilters()
	script.on_event(defines.events.on_built_entity, maybeBlockPlayerPlacement, eventFilters)
	script.on_event(defines.events.on_robot_built_entity, maybeBlockRobotPlacement, eventFilters)
	if blockingType == "block-perpendicular-2" or blockingType == "block-perpendicular-4" then
		script.on_event(defines.events.on_player_rotated_entity, maybeBlockPlayerRotation) -- Doesn't support event filters.
	end
end