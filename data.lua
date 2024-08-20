if settings.startup["HarderBasicLogistics-sound-on-placement-blocking"].value then
	data:extend({
		{
			type = "sound",
			name = "HarderBasicLogistics-buzzer",
			filename = "__base__/sound/programmable-speaker/buzzer-1.ogg",
		},
	})
end

require("data-tweaks.shorten-underground-belts")