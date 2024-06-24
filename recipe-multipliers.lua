-- Map from "category name" to {default multiplier value, list of product item categories, list of product items}
return {
    ["belts"] = {default = 2, productCategories = {"transport-belt"}},
    ["underground-belts"] = {default = 1, productCategories = {"underground-belt"}},
    ["splitters"] = {default = 1, productCategories = {"splitter"}},

    ["loaders"] = {default = 2, productCategories = {"loader", "loader-1x1"}},
    ["inserters"] = {default = 2, productCategories = {"inserter"}},

    ["cliff-explosives"] = {default = 4, productItems = {"cliff-explosives"}},
    ["landfill"] = {default = 2, productItems = {"landfill"}},
}
