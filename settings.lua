local nextOrder = 0
function getNextOrder()
    nextOrder = nextOrder + 1
    return string.format("%03d", nextOrder)
end

local settings = {
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-inserter-placement-blocking",
        type = "string-setting",
        setting_type = "startup",
        default_value = "block-cross-5-5",
        allowed_values = {
            "allow-all",
            "block-4",
            "block-8",
            "block-cross-5-5",
        },
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-shorten-underground-belts",
        type = "string-setting",
        setting_type = "startup",
        default_value = "all-1",
        allowed_values = {
            "off",
            "all-1",
            "1-then-increment",
        },
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-remove-long-inserters",
        type = "bool-setting",
        setting_type = "startup",
        default_value = true,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-belt-speed-multiplier",
        type = "double-setting",
        setting_type = "startup",
        default_value = 0.5,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-splitter-speed-multiplier",
        type = "double-setting",
        setting_type = "startup",
        default_value = 0.5,
    },
}

local recipeMultipliers = require("recipe-multipliers")
for recipeGroup, properties in pairs(recipeMultipliers) do
    table.insert(settings, {
        order = getNextOrder(),
        name = "HarderBasicLogistics-recipe-multiplier-"..recipeGroup,
        type = "double-setting",
        setting_type = "startup",
        default_value = properties.default,
    })
end

data:extend(settings)

-- TODO maybe: allow the player able to walk through cliffs, just not build on them. Probably some collision mask change. This is nice because it makes it less tedious to use high cliff settings, while preserving the design challenge.