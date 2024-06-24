function recipeNameIsLongInserter(recipeName)
	return ((string.find(recipeName, "long%-inserter") ~= nil)
		or ((string.find(recipeName, "long%-handed") ~= nil) and (string.find(recipeName, "inserter") ~= nil)))
end

function hideRecipe(s)
	local recipe = data.raw.recipe[s]
	if recipe ~= nil then
		if recipe.normal then -- Recipe has separate normal and expensive
			recipe.normal.hidden = true
			recipe.expensive.hidden = true
		else
			recipe.hidden = true
		end
	end
end

function removeLongInserterFromTechDifficulty(techDifficulty)
	local oldEffects = techDifficulty.effects
	if oldEffects == nil then return end
	local needsChanging = false
	for _, effect in pairs(oldEffects) do
		if effect.type == "unlock-recipe" and recipeNameIsLongInserter(effect.recipe) then
			needsChanging = true
			break
		end
	end
	if not needsChanging then return end
	local newEffects = {}
	for _, effect in pairs(oldEffects) do
		if not (effect.type == "unlock-recipe" and recipeNameIsLongInserter(effect.recipe)) then
			table.insert(newEffects, effect)
		end
	end
	techDifficulty.effects = newEffects
end

function removeLongInserterFromTech(tech)
	if tech.normal then -- Tech has separate normal and expensive
		removeLongInserterFromTechDifficulty(tech.normal)
		removeLongInserterFromTechDifficulty(tech.expensive)
	else
		removeLongInserterFromTechDifficulty(tech)
	end
end

------------------------------------------------------------------------

for name, _ in pairs(data.raw.recipe) do
	if recipeNameIsLongInserter(name) then
		hideRecipe(name)
	end
end

for _, tech in pairs(data.raw.technology) do
	removeLongInserterFromTech(tech)
end