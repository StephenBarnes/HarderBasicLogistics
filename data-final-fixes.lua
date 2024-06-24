require("dff-recipe-multipliers")

if settings.startup["HarderLogistics-remove-long-inserters"].value then
	require("dff-remove-long-inserters")
end

-- This must go after recipe-multipliers, else recipe-multipliers will re-adjust the numbers of belts needed to make underground belts.
if settings.startup["HarderLogistics-shorten-underground-belts"].value ~= "off" then
	require("dff-shorten-underground-belts")
end

if settings.startup["HarderLogistics-splitter-speed-multiplier"].value ~= 1.0 then
	require("dff-multiply-splitter-speeds")
end
if settings.startup["HarderLogistics-belt-speed-multiplier"].value ~= 1.0 then
	require("dff-multiply-belt-speeds")
end


-- TODO give the mod a better name