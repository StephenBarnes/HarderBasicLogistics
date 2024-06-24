
local longInserters = {
	["long-handed-inserter"] = true,

	-- For Industrial Revolution 3
	["long-handed-steam-inserter"] = true,

	-- TODO add more
}

function hideRecipe(s)
	local recipe = data.raw.recipe[s]
	if recipe ~= nil then
		if data.normal then -- Recipe has separate normal and expensive
			recipe.normal.hidden = true
			recipe.expensive.hidden = true
		else
			recipe.hidden = true
		end
	end
end

function removeLongInserterTechEffects(techDifficulty)
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

function removeLongInsertersFromTechnologies()
	for _, tech in pairs(data.raw.technology) do
		if tech.normal then -- Tech has separate normal and expensive
			removeLongInserterTechEffects(tech.normal)
			removeLongInserterTechEffects(tech.expensive)
		else
			removeLongInserterTechEffects(tech)
		end
	end
end

------------------------------------------------------------------------

for longInserter, _ in pairs(longInserters) do
	hideRecipe(longInserter)
end
removeLongInsertersFromTechnologies()