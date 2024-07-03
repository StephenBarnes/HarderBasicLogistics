require("data-tweaks.multiply-recipes")
require("data-tweaks.remove-long-inserters")
require("data-tweaks.multiply-splitter-speeds")
require("data-tweaks.multiply-belt-speeds")
require("data-tweaks.multiply-inserter-speeds")

-- This must go after multiply-recipes, else multiply-recipes will re-adjust the numbers of belts needed to make underground belts.
require("data-tweaks.shorten-underground-belts")