local categories = {
	"transport-belt",
	"underground-belt",
	"loader",
	"loader-1x1",
}

for _, c in pairs(categories) do
	for _, b in pairs(data.raw[c]) do
		b.speed = b.speed * settings.startup["HarderLogistics-belt-speed-multiplier"].value
	end
end