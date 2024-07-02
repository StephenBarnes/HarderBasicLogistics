local Common = require("common")

local blockingType = settings.startup["HarderBasicLogistics-inserter-placement-blocking"].value
-- We could make this a runtime setting, not a startup setting. However, then we would need to register an event handler even when this blocking is turned off, so rather don't do that.

local placementBlockingBurnerInserters = settings.startup["HarderBasicLogistics-placement-blocking-burner-inserters"].value
local longInsertersExist = not settings.startup["HarderBasicLogistics-remove-long-inserters"].value

local lastMessageTick = 0
local messageWaitTicks = 5 -- Don't show message if a message was already shown within this many ticks ago.

local machinesToBlockSides = {
	["assembling-machine"] = true,
	["furnace"] = true,
	["lab"] = true,
	["boiler"] = true,
	["reactor"] = true,
	["generator"] = true,
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["roboport"] = true,

	-- Vanilla's containers are 1x1, but player could be using larger ones from a mod like AAI Containers.
	["logistic-container"] = true,
	["container"] = true,
}
local function machineSideBlockingAppliesToEntity(entity)
	return machinesToBlockSides[entity.type]
end

local function getAbsoluteBox(entity)
	-- Given a machine entity, returns a bounding box of tile positions it occupies.
	local pos = entity.position
	local halfWidth = entity.prototype.tile_width / 2
	local halfHeight = entity.prototype.tile_height / 2
	return {
		left_top = {pos.x-halfWidth, pos.y-halfHeight},
		right_bottom = {pos.x+halfWidth, pos.y+halfHeight},
	}
end

local function getMachineEdgePositions(entity, dir, absoluteBox)
	-- Returns a list of positions on one side of the entity, in the given direction.
	-- absoluteBox argument is optional, only used to get rid of duplicate computations.
	if absoluteBox == nil then
		absoluteBox = getAbsoluteBox(entity)
	end
	edge = {}
	if dir == defines.direction.north then
		for x = absoluteBox.left_top[1], absoluteBox.right_bottom[1] - 1 do
			table.insert(edge, {x, absoluteBox.left_top[2] - 1})
		end
	elseif dir == defines.direction.south then
		for x = absoluteBox.left_top[1], absoluteBox.right_bottom[1] - 1 do
			table.insert(edge, {x, absoluteBox.right_bottom[2]})
		end
	elseif dir == defines.direction.west then
		for y = absoluteBox.left_top[2], absoluteBox.right_bottom[2] - 1 do
			table.insert(edge, {absoluteBox.left_top[1] - 1, y})
		end
	elseif dir == defines.direction.east then
		for y = absoluteBox.left_top[2], absoluteBox.right_bottom[2] - 1 do
			table.insert(edge, {absoluteBox.right_bottom[1], y})
		end
	end
	return edge
end

local function getMachineAllEdges(entity)
	-- Given a machine entity, returns a list of 4 lists of positions, one containing the positions on each side.
	-- Lists are in order top, bottom, left, right.
	local absoluteBox = getAbsoluteBox(entity)
	local dirs = {defines.direction.north, defines.direction.south, defines.direction.west, defines.direction.east}
	local sides = {}
	for _, dir in pairs(dirs) do
		sides[dir] = getMachineEdgePositions(entity, dir, absoluteBox)
	end
	return sides
end

local function blockablePositions(entity)
	-- Returns a list of positions where entities could block placement of the given entity.
	-- When using machine-side blocking, this is only used for the inserters, not the assembling machines.
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
	-- When machine-side blocking is enabled, this is only used for the inserters, and doesn't perform direction check.
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

function movePosInDir(pos, dir, dist)
	-- Returns a new position moved in the given direction.
	if dir == defines.direction.north then
		return {pos[1], pos[2]-dist}
	elseif dir == defines.direction.south then
		return {pos[1], pos[2]+dist}
	elseif dir == defines.direction.west then
		return {pos[1]-dist, pos[2]}
	elseif dir == defines.direction.east then
		return {pos[1]+dist, pos[2]}
	else
		game.print("ERROR: Unknown direction")
	end
end

local function checkMachineSideBlocking(entity, checkDir)
	-- Checks whether the given machine entity's placement is valid, given adjacent inserters etc.
	-- If it's not valid, returns one entity blocking it, else returns nil.
	local sidesToCheck
	if checkDir == nil then
		sidesToCheck = getMachineAllEdges(entity)
	else
		sidesToCheck = {[checkDir] = getMachineEdgePositions(entity, checkDir)}
	end
	for dir, side in pairs(sidesToCheck) do
		local blockAxis = dirAxis(dir)
		local numBlockersOnSide = 0
		for _, pos in pairs(side) do
			local blockers = entity.surface.find_entities_filtered {
				position = {pos[1] + 0.5, pos[2] + 0.5}, -- Offset by 0.5 because it checks the center of the tile.
				type = "inserter",
				limit = 1,
			}
			for _, blocker in ipairs(blockers) do
				if ((dirAxis(blocker.direction) == blockAxis)
						and entityBlocksPlacement(blocker, entity)) then
					numBlockersOnSide = numBlockersOnSide + 1
					if numBlockersOnSide > 1 then
						return blocker
					end
				end
			end

			-- handle long inserters
			if longInsertersExist then
				local posFurther = movePosInDir(pos, dir, 1) -- TODO refactor that other function to use this
				local longBlockers = entity.surface.find_entities_filtered {
					position = {posFurther[1] + 0.5, posFurther[2] + 0.5}, -- Offset by 0.5 because it checks the center of the tile.
					type = "inserter",
					limit = 1,
				}
				for _, blocker in ipairs(longBlockers) do
					if ((dirAxis(blocker.direction) == blockAxis)
							and Common.isLongInserter(blocker.name)
							and entityBlocksPlacement(blocker, entity)) then
						numBlockersOnSide = numBlockersOnSide + 1
						if numBlockersOnSide > 1 then
							return blocker
						end
					end
				end
			end
		end
	end
	return nil
end

local function sidesAndDirsTo(pos, dist)
	-- Given a position, returns a table of direction -> position such that `pos` is in that direction at that dist.
	return {
		[defines.direction.south] = {pos.x, pos.y-dist},
		[defines.direction.north] = {pos.x, pos.y+dist},
		[defines.direction.west] = {pos.x+dist, pos.y},
		[defines.direction.east] = {pos.x-dist, pos.y},
	}
end

local function checkInserterMachineSideBlocking(entity)
	-- Checks whether the given inserter's placement is blocked by a machine entity.
	-- Returns the machine blocking it, or else nil.
	local dist = Common.isLongInserter(entity.name) and 2 or 1
	for dir, pos in pairs(sidesAndDirsTo(entity.position, dist)) do
		-- TODO fix bug: this shouldn't check all directions, only the 2 parallel to inserter.
		local blockers = entity.surface.find_entities_filtered {
			position = pos,
			limit = 1,
		}
		if #blockers == 1 and machineSideBlockingAppliesToEntity(blockers[1]) then
			local blocker = blockers[1]
			local machineBlocker = checkMachineSideBlocking(blocker, dir)
			if machineBlocker ~= nil then
				-- We could return either `blocker` (the machine) or `machineBlocker` (the inserter).
				-- I think let's return the machine, especially since `machineBlocker` could be the same as `entity`, which isn't helpful.
				return blocker
			end
		end
	end
	return nil
end

local function findBlockingEntity(entity)
	if blockingType == "block-machine-side" then
		if machineSideBlockingAppliesToEntity(entity) then
			return checkMachineSideBlocking(entity)
			-- TODO maybe show a different message in these cases.
		else
			return checkInserterMachineSideBlocking(entity)
		end
	end
	for _, pos in pairs(blockablePositions(entity)) do
		local blockers = entity.surface.find_entities_filtered {
			position = pos,
			type = "inserter",
			limit = 1,
		}
		for _, blocker in ipairs(blockers) do
			if entityBlocksPlacement(blocker, entity) then
				return blocker
			end
		end
	end
	return nil
end

local function blockingAppliesToEntity(entity)
	-- Given an arbitrary entity, returns whether it can be blocked by the placement restrictions.
	if blockingType == "block-machine-side" and machineSideBlockingAppliesToEntity(entity) then
		return true
	end
	return (entity.type == "inserter") and ((not placementBlockingBurnerInserters) or entity.name ~= "burner-inserter")
end

local function maybeBlockPlayerPlacement(event)
	local placed = event.created_entity
	if not blockingAppliesToEntity(placed) then return end
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

local function maybeBlockPlayerRotation(event)
	local entity = event.entity
	if not blockingAppliesToEntity(entity) then return end
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
	if not blockingAppliesToEntity(placed) then return end
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
		placed.destroy()
		surface.spill_item_stack(pos, event.stack, nil, event.robot.force)
		-- Force arg is to mark the spilled item stack for deconstruction by the robot's force.
	else
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
	if blockingType == "block-machine-side" then
		local filters = {{filter="type", type="inserter"}}
		for machineType, _ in pairs(machinesToBlockSides) do
			table.insert(filters, {filter="type", type=machineType})
		end
		return filters
	end
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
	if blockingType == "block-perpendicular-2" or blockingType == "block-perpendicular-4" or blockingType == "block-machine-side" then
		script.on_event(defines.events.on_player_rotated_entity, maybeBlockPlayerRotation) -- Doesn't support event filters.
	end
end

-- TODO handle long inserters with the max-1-per-side restriction.