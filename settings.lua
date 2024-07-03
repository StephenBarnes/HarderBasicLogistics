local nextOrder = 0
local function getNextOrder()
    nextOrder = nextOrder + 1
    return string.format("%03d", nextOrder)
end

local settings = {
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-inserter-placement-blocking",
        type = "string-setting",
        setting_type = "startup",
        default_value = "block-machine-side",
        allowed_values = {
            "allow-all",
            "block-4",
            "block-8",
            "block-cross-5-5",
            "block-distance-2",
            "block-perpendicular-2",
            "block-perpendicular-4",
            "block-machine-side",
        },
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-sound-on-placement-blocking",
        type = "bool-setting",
        setting_type = "startup",
        default_value = true,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-placement-blocking-burner-inserters",
        type = "bool-setting",
        setting_type = "startup",
        default_value = true,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-special-loaders-inserters",
        type = "string-setting",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-containers-are-special",
        type = "bool-setting",
        setting_type = "startup",
        default_value = false,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-special-machines",
        type = "string-setting",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-shorten-underground-belts",
        type = "string-setting",
        setting_type = "startup",
        default_value = "1-then-increment",
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
        default_value = 1,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-splitter-speed-multiplier",
        type = "double-setting",
        setting_type = "startup",
        default_value = 1,
    },
    {
        order = getNextOrder(),
        name = "HarderBasicLogistics-inserter-speed-multiplier",
        type = "double-setting",
        setting_type = "startup",
        default_value = 1,
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