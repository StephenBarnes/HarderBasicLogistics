data:extend({
    {
        order = "1",
        name = "HarderLogistics-inserter-placement-blocking",
        type = "string-setting",
        setting_type = "startup",
        default_value = "allow-all",
        allowed_values = {
            "allow-all",
            "block-4",
            "block-8",
            "block-cross-5-5",
        },
    },
    {
        order = "2",
        name = "HarderLogistics-shorten-underground-belts",
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
        order = "3",
        name = "HarderLogistics-remove-long-inserters",
        type = "bool-setting",
        setting_type = "startup",
        default_value = true,
    },
    {
        order = "4",
        name = "HarderLogistics-reduce-splitter-speeds",
        type = "bool-setting",
        setting_type = "startup",
        default_value = false,
    },
})

-- TODO add optional dependency on IR3, since I'm modifying its long inserter too. Also modify placement for its inserters.
-- TODO add compat with bob's belts and inserters, and add optional dependency on that.

-- TODO add a worldgen noise function / whatever to make it so that cliffs generate everywhere, and in maze-like patterns. Then also make cliff explosives more expensive.
-- TODO also make the player able to walk through cliffs, just not build on them.