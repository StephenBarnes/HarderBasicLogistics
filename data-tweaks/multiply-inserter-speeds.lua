if settings.startup["HarderBasicLogistics-inserter-speed-multiplier"].value ~= 1.0 then
	for _, inserter in pairs(data.raw.inserter) do
		inserter.extension_speed = inserter.extension_speed * settings.startup["HarderBasicLogistics-inserter-speed-multiplier"].value
		inserter.rotation_speed = inserter.rotation_speed * settings.startup["HarderBasicLogistics-inserter-speed-multiplier"].value
	end
end