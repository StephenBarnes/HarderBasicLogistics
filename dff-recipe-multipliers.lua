local recipeMultiplierGroups = require("recipe-multipliers")
for groupName, group in pairs(recipeMultiplierGroups) do
	group.value = settings.startup["HarderBasicLogistics-recipe-multiplier-"..groupName].value
end

------------------------------------------------------------------------

function multiplyRecipeDifficulty(recipeDifficulty, multiplier)
	if not recipeDifficulty.ingredients then return end
	for _, ingredient in pairs(recipeDifficulty.ingredients) do
		-- Ingredients are in format {"iron-ore", 1} or in format {type="item", name="iron-ore", amount=1}.
		if ingredient.type ~= nil then
			ingredient.amount = math.ceil(ingredient.amount * multiplier)
		else
			ingredient[2] = math.ceil(ingredient[2] * multiplier)
		end
	end
end

function multiplyRecipe(recipe, multiplier)
	if recipe.normal then
		multiplyRecipeDifficulty(recipe.normal, multiplier)
		multiplyRecipeDifficulty(recipe.expensive, multiplier)
	else
		multiplyRecipeDifficulty(recipe, multiplier)
	end
end

------------------------------------------------------------------------

-- Now this is a bit difficult because recipes can have multiple products, etc.
-- So, we look through all recipes, look through all their products, and then check whether any products fall into certain categories.

function getRecipeDifficultyProducts(recipeDifficulty)
	local products = {}
	if recipeDifficulty.main_product ~= nil then table.insert(products, recipeDifficulty.main_product) end
	if recipeDifficulty.result ~= nil then table.insert(products, recipeDifficulty.result) end
	if recipeDifficulty.results ~= nil then
		for _, product in pairs(recipeDifficulty.results) do
			if product.name ~= nil then
				table.insert(products, product.name)
			else
				table.insert(products, product[1])
			end
		end
	end
	return products
end

function getRecipeDifficultyProductGroup(recipeDifficulty)
	local products = getRecipeDifficultyProducts(recipeDifficulty)
	for groupName, group in pairs(recipeMultiplierGroups) do
		if group.productItems ~= nil then
			for _, productItem in pairs(group.productItems) do
				for _, product in pairs(products) do
					if productItem == product then
						return groupName
					end
				end
			end
		end
		if group.productCategories ~= nil then
			for _, productCategory in pairs(group.productCategories) do
				for _, product in pairs(products) do
					if data.raw[productCategory][product] ~= nil then
						return groupName
					end
				end
			end
		end
	end
	return nil
end

function getRecipeProductGroup(recipe)
	local group = nil
	if recipe.normal then
		group = getRecipeDifficultyProductGroup(recipe.normal)
		if group == nil then
			group = getRecipeDifficultyProductGroup(recipe.expensive)
		end
	else
		group = getRecipeDifficultyProductGroup(recipe)
	end
	return group
end

------------------------------------------------------------------------

for _, recipe in pairs(data.raw["recipe"]) do
	local groupName = getRecipeProductGroup(recipe)
	--log("For recipe "..recipe.name.." the product group is "..(groupName or "nil"))
	if groupName ~= nil then
		local group = recipeMultiplierGroups[groupName]
		if group ~= nil then
			local multiplier = group.value
			multiplyRecipe(recipe, multiplier)
		end
	end
end