local Common = require("common")

local function debugPrint(s) game.print(math.random(1000, 9999)..": "..s) end

local blockingType = settings.startup["HarderBasicLogistics-inserter-placement-blocking"].value
-- We could make this a runtime setting, not a startup setting. However, then we would need to register an event handler even when this blocking is turned off, so rather don't do that.

local placementBlockingBurnerInserters = settings.startup["HarderBasicLogistics-placement-blocking-burner-inserters"].value
local longInsertersExist = not settings.startup["HarderBasicLogistics-remove-long-inserters"].value

local lastMessageTick = 0
local messageWaitTicks = 10 -- Don't show message if a message was already shown within this many ticks ago.

local cardinalDirections = {defines.direction.north, defines.direction.south, defines.direction.west, defines.direction.east}

-- Some entities have different names for their localised strings vs for the entity.
local translateNames = {
	["chute-miniloader-inserter"] = "chute-miniloader",
	["miniloader-inserter"] = "miniloader",
	["fast-miniloader-inserter"] = "fast-miniloader",
	["express-miniloader-inserter"] = "express-miniloader",
	["filter-miniloader-inserter"] = "filter-miniloader",
	["fast-filter-miniloader-inserter"] = "fast-filter-miniloader",
	["express-filter-miniloader-inserter"] = "express-filter-miniloader",
	["aai-loader-pipe"] = "aai-loader",
	["aai-fast-loader-pipe"] = "aai-fast-loader",
	["aai-express-loader-pipe"] = "aai-express-loader",
}
local function translateName(s)
	return translateNames[s] or s
end

local function splitToSet(s)
	-- Given eg "A,B,C", returns {A=true, B=true, C=true}. If s is empty, returns nil (so we can check whether special machines are enabled at all).
	local trimmedS = s:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
	if trimmedS == "" then return nil end
	local result = {}
	for word in string.gmatch(trimmedS, '([^,]+)') do
		local trimmedWord = word:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
		if trimmedWord ~= "" then
			result[trimmedWord] = true
		end
	end
	return result
end
local specialLoadersInserters = splitToSet(settings.startup["HarderBasicLogistics-special-loaders-inserters"].value)
local specialMachines = splitToSet(settings.startup["HarderBasicLogistics-special-machines"].value) or {}
local alwaysSpecialMachineTypes = { -- Machine types always allowed on the sides of special loaders/inserters.
	["transport-belt"] = true,
	["underground-belt"] = true,
	["splitter"] = true,
}
if settings.startup["HarderBasicLogistics-containers-are-special"].value then
	alwaysSpecialMachineTypes["container"] = true
end

local function playBlockSound(player)
	if settings.startup["HarderBasicLogistics-sound-on-placement-blocking"].value then
		player.play_sound{path="HarderBasicLogistics-buzzer"}
	end
end

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

local function getParallelDirections(dir)
	if dir == defines.direction.north or dir == defines.direction.south then
		return {defines.direction.north, defines.direction.south}
	elseif dir == defines.direction.west or dir == defines.direction.east then
		return {defines.direction.west, defines.direction.east}
	else
		log("ERROR: Unknown direction: "..tostring(dir))
	end
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
	else
		log("ERROR: Unknown direction: "..tostring(dir))
	end
	return edge
end

local function getMachineAllEdges(entity)
	-- Given a machine entity, returns a list of 4 lists of positions, one containing the positions on each side.
	-- Lists are in order top, bottom, left, right.
	local absoluteBox = getAbsoluteBox(entity)
	local sides = {}
	for _, dir in pairs(cardinalDirections) do
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
		log("ERROR: Unknown inserter blocking type")
	end
	-- Could refactor all this to loop over cardinalDirections, concatenate lists etc., but I think that's slower and less clear.
end

local function dirAxis(dir)
	-- Returns true if dir is up/down, false if it's left/right. For comparing axes for perpendicular placement restrictions.
	return dir == defines.direction.north or dir == defines.direction.south
end
local function posDeltaAxis(pos1, pos2)
	-- Returns true if pos1 is up/down from pos2, false otherwise. For comparing axes for perpendicular placement restrictions.
	return pos1.x == pos2.x
end

local function entityBlocksPlacement(entity, otherEntity)
	-- Returns whether the given entity blocks the placement of the other entity.
	-- This is only called for entities that are already known to be in one of the "blockable positions".
	-- So this function only checks that the entity isn't exempt (because it's a burner), and then does rotation-dependent checks.
	-- When machine-side blocking is enabled, this is only used for the inserters, and doesn't perform direction check.
	-- This function is only for non-special blocking.
	if Common.isLoaderRegisteredAsInserter(entity.name) then
		return false
	end
	if (not placementBlockingBurnerInserters) and entity.name == "burner-inserter" then
		return false
	end
	if blockingType == "block-perpendicular-2" or blockingType == "block-perpendicular-4" then
		-- Get facing of each inserter.
		axis1 = dirAxis(entity.direction)
		axis2 = dirAxis(otherEntity.direction)
		if axis1 ~= axis2 then return true end -- at least one of them must be blocking the other one.
		-- If they're on the same axis, they might block each other.
		return axis1 ~= posDeltaAxis(entity.position, otherEntity.position)
	end
	return true
end

local function movePosInDir(pos, dir, dist)
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
		log("ERROR: Unknown direction")
	end
end

local function checkMachineSideBlocking(entity, checkDir)
	-- Checks whether the given machine entity's placement is valid, given adjacent inserters etc.
	-- If it's not valid, returns a list of two entities blocking it, else returns nil.
	local sidesToCheck
	if checkDir == nil then
		sidesToCheck = getMachineAllEdges(entity)
	else
		sidesToCheck = {[checkDir] = getMachineEdgePositions(entity, checkDir)}
	end
	for dir, side in pairs(sidesToCheck) do
		local blockAxis = dirAxis(dir)
		local firstBlocker = nil
		for _, pos in pairs(side) do
			local blockers = entity.surface.find_entities_filtered {
				position = {pos[1] + 0.5, pos[2] + 0.5}, -- Offset by 0.5 because it checks the center of the other building.
				type = "inserter",
			}
			for _, blocker in ipairs(blockers) do
				if ((dirAxis(blocker.direction) == blockAxis)
						and entityBlocksPlacement(blocker, entity)) then
					if firstBlocker == nil then
						firstBlocker = blocker
					else
						return {firstBlocker, blocker}
					end
				end
			end

			-- handle long inserters
			if longInsertersExist then
				local posFurther = movePosInDir(pos, dir, 1)
				local longBlockers = entity.surface.find_entities_filtered {
					position = {posFurther[1] + 0.5, posFurther[2] + 0.5}, -- Offset by 0.5 because it checks the center of the other building.
					type = "inserter",
				}
				for _, blocker in ipairs(longBlockers) do
					if ((dirAxis(blocker.direction) == blockAxis)
							and Common.isLongInserter(blocker.name)
							and entityBlocksPlacement(blocker, entity)) then
						if firstBlocker == nil then
							firstBlocker = blocker
						else
							return {firstBlocker, blocker}
						end
					end
				end
			end
		end
	end
	return nil
end

local function checkInserterMachineSideBlocking(entity)
	-- Checks whether the given inserter's placement is blocked by a machine entity.
	-- Returns the machine blocking it, or else nil.
	local dist = Common.isLongInserter(entity.name) and 2 or 1
	for _, dir in pairs(getParallelDirections(entity.direction)) do
		local pos = movePosInDir({entity.position.x, entity.position.y}, dir, -dist)
		local blockers = entity.surface.find_entities_filtered {
			position = pos,
		}
		if #blockers == 1 and machineSideBlockingAppliesToEntity(blockers[1]) then
			local blocker = blockers[1]
			local machineBlockers = checkMachineSideBlocking(blocker, dir)
			if machineBlockers ~= nil then
				-- There's 3 entities here: the machine, and 2 inserters. We want to return the machine, and the inserter that isn't `entity`.
				if machineBlockers[1].name == entity.name then
					return {blocker, machineBlockers[2]}
				else
					return {blocker, machineBlockers[1]}
				end
			end
		end
	end
	return nil
end

local function getNonSpecialBlockingMessage(entity)
	-- If placement of entity is blocked by the main "inserter placement restriction" settings, returns localised string with message to show.
	-- If not blocked, returns nil.
	-- This function completely ignores the special machines/inserters settings.
	if blockingType == "block-machine-side" then
		if machineSideBlockingAppliesToEntity(entity) then -- Placing a machine blocked by two inserters.
			local machineSideBlockers = checkMachineSideBlocking(entity)
			if machineSideBlockers == nil then
				return nil
			else
				if machineSideBlockers[1].name == machineSideBlockers[2].name then
					return { "cant-build-reason.HarderBasicLogistics-2-blockers-same",
						{ "entity-name." .. translateName(machineSideBlockers[1].name) } }
				end
				return { "cant-build-reason.HarderBasicLogistics-2-blockers",
					{ "entity-name." .. translateName(machineSideBlockers[1].name) },
					{ "entity-name." .. translateName(machineSideBlockers[2].name) } }
			end
		else
			local blockers = checkInserterMachineSideBlocking(entity)
			if blockers == nil then
				return nil
			else
				return { "cant-build-reason.HarderBasicLogistics-2-blockers",
					{ "entity-name." .. translateName(blockers[1].name) },
					{ "entity-name." .. translateName(blockers[2].name) } }
			end
		end
	end
	for _, pos in pairs(blockablePositions(entity)) do
		local blockers = entity.surface.find_entities_filtered {
			position = pos,
			type = "inserter",
		}
		for _, blocker in ipairs(blockers) do
			if entityBlocksPlacement(blocker, entity) then
				return { "cant-build-reason.HarderBasicLogistics-1-blocker",
					{ "entity-name." .. translateName(blocker.name) } }
			end
		end
	end
	return nil
end

local function getSpecialLoaderInserterBlockingMessage(entity)
	-- Only called on special loaders/inserters.
	-- If placement of the special loader/inserter here would violate the special rules, returns localised string with message saying it's blocked.
	-- Otherwise, returns nil.
	-- "If it would violate the special rules" means that the special loader/inserter would have input/output on a non-special machine.
	local dist = Common.isLongInserter(entity.name) and 2 or 1
	for _, dir in pairs(getParallelDirections(entity.direction)) do
		local pos = movePosInDir({entity.position.x, entity.position.y}, dir, -dist)
		local blockers = entity.surface.find_entities_filtered { position = pos }
		for _, blocker in ipairs(blockers) do
			if not alwaysSpecialMachineTypes[blocker.type] and (not specialMachines[blocker.name]) then
				return { "cant-build-reason.HarderBasicLogistics-special-loader-inserter-blocked",
					{ "entity-name." .. translateName(entity.name) },
					{ "entity-name." .. translateName(blocker.name) },
				}
			end
		end
	end
	return nil
end

local function getNonSpecialMachineBlockingMessage(entity)
	-- Only called on non-special machines.
	-- If placement of the machine here would violate the special rules, returns localised string with message saying it's blocked.
	-- Otherwise, returns nil.
	-- "If it would violate the special rules" means that the machine would be the input/output point of a special loader/inserter.
	if specialLoadersInserters == nil then return nil end
	local sides = getMachineAllEdges(entity)
	for dir, side in pairs(sides) do
		local machineSideAxis = dirAxis(dir)
		for _, pos in pairs(side) do
			local blockers = entity.surface.find_entities_filtered {
				position = {pos[1] + 0.5, pos[2] + 0.5}, -- Offset by 0.5 because it checks the center of the other building.
				-- Can't do limit = 1 here, because eg the AAI loader has an extra entity called aai-loader-pipe in the same position.
			}
			for _, blocker in pairs(blockers) do
				if specialLoadersInserters[blocker.name] then
					if dirAxis(blocker.direction) == machineSideAxis then
						return { "cant-build-reason.HarderBasicLogistics-special-loader-inserter-blocked",
							{ "entity-name." .. translateName(blocker.name) },
							{ "entity-name." .. translateName(entity.name) },
						}
					end
				end
			end

			-- handle long inserters
			if longInsertersExist then
				local posFurther = movePosInDir(pos, dir, 1)
				local longBlockers = entity.surface.find_entities_filtered {
					position = {posFurther[1] + 0.5, posFurther[2] + 0.5},
				}
				for _, longBlocker in pairs(longBlockers) do
					if specialLoadersInserters[longBlocker.name] then
						if dirAxis(longBlocker.direction) == machineSideAxis then
							return { "cant-build-reason.HarderBasicLogistics-special-loader-inserter-blocked",
								{ "entity-name." .. translateName(longBlocker.name) },
								{ "entity-name." .. translateName(entity.name) },
							}
						end
					end
				end
			end
		end
	end
	return nil
end

local function getSpecialBlockingMessage(entity)
	-- If placement of entity is blocked by the special machines/inserters settings, returns localised string with message to show.
	-- If not blocked, returns nil.
	if specialLoadersInserters == nil then return nil end
	if alwaysSpecialMachineTypes[entity.type] then return nil end
	if specialMachines[entity.name] then return nil end
	if specialLoadersInserters ~= nil and specialLoadersInserters[entity.name] then
		return getSpecialLoaderInserterBlockingMessage(entity)
	end
	if not specialMachines[entity.name] then
		return getNonSpecialMachineBlockingMessage(entity)
	end
	return nil
end

local function getBlockingMessage(entity)
	-- If placement of entity is blocked, returns localised string with message to show.
	-- If not blocked, returns nil.
	local nonSpecialBlockingMessage = getNonSpecialBlockingMessage(entity)
	if nonSpecialBlockingMessage ~= nil then
		return nonSpecialBlockingMessage
	end
	return getSpecialBlockingMessage(entity)
end

local function nonSpecialBlockingAppliesToEntity(entity)
	-- Given an arbitrary entity, returns whether it can be blocked by the non-special placement restrictions.
	if Common.isLoaderRegisteredAsInserter(entity.name) then
		return false
	elseif blockingType == "block-machine-side" and machineSideBlockingAppliesToEntity(entity) then
		return true
	else
		return (entity.type == "inserter") and ((not placementBlockingBurnerInserters) or entity.name ~= "burner-inserter")
	end
end

local function specialBlockingAppliesToEntity(entity)
	-- Given an arbitrary entity, returns whether it can be blocked by the special placement restrictions.
	if specialLoadersInserters ~= nil and (not alwaysSpecialMachineTypes[entity.type]) then
		if (not specialMachines[entity.name]) or specialLoadersInserters[entity.name] then
			return true
		end
	end
	return false
end

local function blockingAppliesToEntity(entity)
	return specialBlockingAppliesToEntity(entity) or nonSpecialBlockingAppliesToEntity(entity)
end

local function maybeBlockPlayerPlacement(event)
	local placed = event.created_entity
	if not blockingAppliesToEntity(placed) then return end
	local blockMessage = getBlockingMessage(placed)
	if blockMessage == nil then return end

	local player = game.get_player(event.player_index)
	if player == nil then
		log("Player is nil")
		return
	end
	if game.tick > lastMessageTick + messageWaitTicks then
		lastMessageTick = game.tick
		player.create_local_flying_text {
			text = blockMessage,
			create_at_cursor = true,
			time_to_live = 120,
		}
		playBlockSound(player)
	end
	player.mine_entity(placed, true) -- "true" says force mining it even if player's inventory is full.
end

local function maybeBlockPlayerRotation(event)
	local entity = event.entity
	if not blockingAppliesToEntity(entity) then return end
	local blockMessage = getBlockingMessage(entity)
	if blockMessage == nil then return end

	local player = game.get_player(event.player_index)
	if player == nil then
		log("Player is nil")
	else
		if game.tick > lastMessageTick + messageWaitTicks then
			lastMessageTick = game.tick
			player.create_local_flying_text {
				text = blockMessage,
				create_at_cursor = true,
				time_to_live = 120,
			}
			playBlockSound(player)
		end
	end
	-- Rotate it back.
	entity.direction = event.previous_direction
end

local function maybeBlockRobotPlacement(event)
	local placed = event.created_entity
	if not blockingAppliesToEntity(placed) then return end
	local blockMessage = getBlockingMessage(placed)
	if blockMessage == nil then return end

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
			text = blockMessage,
			time_to_live = 40,
		}
	end
end

local function getEventFilters()
	if specialLoadersInserters ~= nil then
		-- We need to listen to all events, because we need to know about all non-special machines placed.
		-- We could maybe build a complex filter list with inverted conditions: (not specialMachine1) and (not specialMachine2) etc.
		return nil
	elseif blockingType == "block-machine-side" then
		-- Only listen to events for inserters and side-blocking machines.
		local filters = {{filter="type", type="inserter"}}
		for machineType, _ in pairs(machinesToBlockSides) do
			table.insert(filters, {filter="type", type=machineType})
		end
		return filters
	-- In other cases, we only care about inserters, possibly excluding burner inserters.
	elseif placementBlockingBurnerInserters then
		return {{filter="type", type="inserter"}}
	else
		return {
			{filter="type", type="inserter"},
			{filter="name", name="burner-inserter", invert=true, mode="and"},
		}
	end
end

if blockingType ~= "allow-all" or specialLoadersInserters ~= nil then
	local eventFilters = getEventFilters()
	script.on_event(defines.events.on_built_entity, maybeBlockPlayerPlacement, eventFilters)
	script.on_event(defines.events.on_robot_built_entity, maybeBlockRobotPlacement, eventFilters)
	if (blockingType == "block-perpendicular-2"
			or blockingType == "block-perpendicular-4"
			or blockingType == "block-machine-side"
			or specialLoadersInserters ~= nil) then
		script.on_event(defines.events.on_player_rotated_entity, maybeBlockPlayerRotation) -- Doesn't support event filters.
	end
end
