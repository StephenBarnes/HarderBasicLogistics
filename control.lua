
local blockingType = settings.startup["HarderLogistics-inserter-placement-blocking"].value
local arithmeticTrioRad = settings.startup["HarderLogistics-arithmetic-trio-radius"].value

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

function findPositionSetBlockingEntity(inserter)
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

function posEqual(p1, p2)
	return p1.x == p2.x and p1.y == p2.y
end

function findArithmeticTrioBlocking(inserter)
	-- If the named inserter completes an arithmetic trio, this returns the nearer of the two other inserters in that trio.
	-- If multiple trios, can return either of them.
	-- If no trio, returns nil.
	local pos1 = inserter.position
	local nearbyInserters = inserter.surface.find_entities_filtered {
		position = pos1,
		radius = arithmeticTrioRad / 2,
			-- Divide by 2, because for each second-inserter we find, we look double as far for the third inserter.
			-- This reduces search radius and also always returns the nearer blocking inserter.
		type = "inserter",
	}
	for _, second in pairs(nearbyInserters) do
		local pos2 = second.position
		if not posEqual(pos2, pos1) then
			local pos3 = {
				x = pos2.x * 2 - pos1.x,
				y = pos2.y * 2 - pos1.y,
			}
			local thirdCount = inserter.surface.count_entities_filtered {
				position = pos3,
				type = "inserter",
				limit = 1,
			}
			if thirdCount > 0 then return second end
		end
	end
	return nil
end

function findBlockingEntity(inserter)
	if blockingType == "block-arithmetic-trios" then
		return findArithmeticTrioBlocking(inserter)
	else
		return findPositionSetBlockingEntity(inserter, blockingType)
	end
end

function maybeBlockInserterPlacement(event)
	local player = game.get_player(event.player_index)
	local placed = event.created_entity
	local blockedBy = findBlockingEntity(placed)
	if blockedBy == nil then return end

	player.create_local_flying_text {
		text = {"cant-build-reason.entity-in-the-way", {"entity-name."..blockedBy.name}},
		create_at_cursor = true,
		time_to_live = 180,
	}
	player.mine_entity(placed, true) -- "true" says force mining it even if player's inventory is full.
end


if settings.startup["HarderLogistics-inserter-placement-blocking"].value then
	script.on_event(defines.events.on_built_entity, maybeBlockInserterPlacement, {{filter="type", type="inserter"}})
end

-- TODO event handler for when ghost built by a bot, that will instead place the minable result of that entity nearby.