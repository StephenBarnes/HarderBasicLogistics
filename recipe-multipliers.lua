-- Map from "category name" to {default multiplier value, list of product item categories, list of product items}
return {
    ["belts"] = {default = 1, productCategories = {"transport-belt"}},
    ["underground-belts"] = {default = 1, productCategories = {"underground-belt"}},
    ["splitters"] = {default = 1, productCategories = {"splitter"}},

    ["loaders"] = {default = 1, productCategories = {"loader", "loader-1x1"}},
    ["inserters"] = {default = 1, productCategories = {"inserter"}},

    ["cliff-explosives"] = {default = 1, productItems = {"cliff-explosives"}},
    ["landfill"] = {default = 1, productItems = {"landfill"}},
}
