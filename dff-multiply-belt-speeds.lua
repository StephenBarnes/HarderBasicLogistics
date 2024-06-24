for _, b in pairs(data.raw["transport-belt"]) do
	b.speed = b.speed * settings.startup["HarderLogistics-belt-speed-multiplier"].value
end