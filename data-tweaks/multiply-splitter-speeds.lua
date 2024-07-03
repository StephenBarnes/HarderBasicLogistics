if settings.startup["HarderBasicLogistics-splitter-speed-multiplier"].value ~= 1.0 then
	for _, splitter in pairs(data.raw.splitter) do
		splitter.speed = splitter.speed * settings.startup["HarderBasicLogistics-splitter-speed-multiplier"].value

		-- I thought we might need to adjust these animation speed values, but from testing it seems we don't.
		--if splitter.animation_speed_coefficient ~= nil then
		--	splitter.animation_speed_coefficient = splitter.animation_speed_coefficient / 2
		--end
		--if splitter.structure_animation_speed_coefficient ~= nil then
		--	splitter.structure_animation_speed_coefficient = splitter.structure_animation_speed_coefficient / 2
		--end
		--if splitter.structure_animation_movement_cooldown ~= nil then
		--	splitter.structure_animation_movement_cooldown = splitter.structure_animation_movement_cooldown * 2
		--end
	end
end