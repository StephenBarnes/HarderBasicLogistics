
if settings.startup["HarderLogistics-remove-long-inserters"].value then
	require("dff-remove-long-inserters")
end

if settings.startup["HarderLogistics-shorten-underground-belts"].value ~= "off" then
	require("dff-shorten-underground-belts")
end

if settings.startup["HarderLogistics-splitter-speed-multiplier"].value ~= 1.0 then
	require("dff-multiply-splitter-speeds")
end