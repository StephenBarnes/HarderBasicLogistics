
if settings.startup["HarderLogistics-remove-long-inserters"].value then
	require("dff-remove-long-inserters")
end

if settings.startup["HarderLogistics-shorten-underground-belts"].value ~= "off" then
	require("dff-shorten-underground-belts")
end

if settings.startup["HarderLogistics-reduce-splitter-speeds"].value then
	require("dff-reduce-splitter-speeds")
end