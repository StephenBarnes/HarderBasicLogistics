data:extend({
    {
        order = "1a",
        name = "HarderLogistics-inserter-placement-blocking",
        type = "string-setting",
        setting_type = "startup",
        default_value = "block-arithmetic-trios",
        allowed_values = {
            "allow-all",
            "block-4",
            "block-8",
            "block-cross-5-5",
            "block-arithmetic-trios",
            -- TODO add some more interesting options
            -- I think I really need to sit on this idea for a bit longer, come up with a more interesting constraint.
            -- Maybe take inspiration from 14 Minesweeper Variants, or something.
            -- TODO add an option to ban triplets of inserters with positions in arithmetic progressions! Nice!!
            -- TODO add an option to ban all inserters at certain randomly-chosen positions determined by map seed.
        },
    },
    {
        order = "1b",
        name = "HarderLogistics-arithmetic-trio-radius",
        type = "int-setting",
        setting_type = "startup",
        default_value = 300,
        minimum_value = 1,
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
    -- TODO add an option for belts to only be buildable in certain orientations at certain positions. Maybe use a noise function to decide between them, and tune it so that there are continuous regions.
})

-- TODO maybe sth for more expensive splitters?
-- TODO maybe sth for more expensive undergrounds?

-- TODO add optional dependency on IR3, since I'm modifying its long inserter too. Also modify placement for its inserters.
-- TODO add compat with bob's belts and inserters, and add optional dependency on that.

-- TODO add a worldgen noise function / whatever to make it so that cliffs generate everywhere, and in maze-like patterns. Then also make cliff explosives more expensive.
-- TODO also make the player able to walk through cliffs, just not build on them.