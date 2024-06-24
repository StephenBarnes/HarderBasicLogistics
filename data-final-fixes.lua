require("data-tweaks.multiply-recipes")

if settings.startup["HarderBasicLogistics-remove-long-inserters"].value then
	require("data-tweaks.remove-long-inserters")
end

-- This must go after recipe-multipliers, else recipe-multipliers will re-adjust the numbers of belts needed to make underground belts.
if settings.startup["HarderBasicLogistics-shorten-underground-belts"].value ~= "off" then
	require("data-tweaks.shorten-underground-belts")
end

if settings.startup["HarderBasicLogistics-splitter-speed-multiplier"].value ~= 1.0 then
	require("data-tweaks.multiply-splitter-speeds")
end
if settings.startup["HarderBasicLogistics-belt-speed-multiplier"].value ~= 1.0 then
	require("data-tweaks.multiply-belt-speeds")
end