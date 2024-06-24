
local longInserters = {
	-- vanilla
	["long-handed-inserter"] = true,

	-- Industrial Revolution 3
	["long-handed-steam-inserter"] = true,

	-- TODO add more
	-- TODO change this to rather use a regex match for "long-handed" and "long-inserter" inside data.raw.inserter.
}

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
		if effect.type == "unlock-recipe" and longInserters[effect.recipe] then
			needsChanging = true
			break
		end
	end
	if not needsChanging then return end
	local newEffects = {}
	for _, effect in pairs(oldEffects) do
		if not (effect.type == "unlock-recipe" and longInserters[effect.recipe]) then
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

for longInserter, _ in pairs(longInserters) do
	hideRecipe(longInserter)
end

for _, tech in pairs(data.raw.technology) do
	removeLongInserterFromTech(tech)
end