local Common = require("common")

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

	for _, inserter in pairs(data.raw.inserter) do
		if Common.isLoaderRegisteredAsInserter(inserter.name) then
			inserter.extension_speed = inserter.extension_speed * settings.startup["HarderBasicLogistics-belt-speed-multiplier"].value
			inserter.rotation_speed = inserter.rotation_speed * settings.startup["HarderBasicLogistics-belt-speed-multiplier"].value
		end
	end
end