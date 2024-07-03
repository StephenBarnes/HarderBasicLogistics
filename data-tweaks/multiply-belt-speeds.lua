if settings.startup["HarderBasicLogistics-belt-speed-multiplier"].value ~= 1.0 then
	local categories = {
		"transport-belt",
		"underground-belt",
		"loader",
		"loader-1x1",
	}

	for _, c in pairs(categories) do
		for _, b in pairs(data.raw[c]) do
			b.speed = b.speed * settings.startup["HarderBasicLogistics-belt-speed-multiplier"].value
		end
	end
end