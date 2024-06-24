
function multiplyRecipeDifficulty(recipeDifficulty, numBelts)
	if not recipeDifficulty.ingredients then return end
	for _, ingredient in pairs(recipeDifficulty.ingredients) do
		-- Ingredients are in format {"iron-ore", 1} or in format {type="item", name="iron-ore", amount=1}.
		if ingredient.type ~= nil then
			if ingredient.type == "item" and data.raw["transport-belt"][ingredient.name] ~= nil then
				ingredient.amount = numBelts
			end
		else
			if data.raw["transport-belt"][ingredient[1]] ~= nil then
				ingredient[2] = numBelts
			end
		end
	end
end

function adjustUndergroundRecipe(recipe, numBelts)
	-- Adjusts the ingredients of `recipe` to require `numBelts` transport belts of that tier, if it currently requires any.
	if recipe.normal then
		multiplyRecipeDifficulty(recipe.normal, numBelts)
		multiplyRecipeDifficulty(recipe.expensive, numBelts)
	else
		multiplyRecipeDifficulty(recipe, numBelts)
	end
end

function adjustUndergroundFor(belt, length)
	local underground = data.raw["underground-belt"][belt.related_underground_belt]
	if underground == nil then
		log("Couldn't find related underground belt: "..(belt.related_underground_belt or "nil"))
		return
	end
	underground.max_distance = length -- This is 1 more than the number of tiles between the 2 underground-belt entities.
	local recipe = data.raw.recipe[underground.name]
	if recipe then
		adjustUndergroundRecipe(recipe, length)
	end
end

function shortenAllUndergroundsTo1()
	for _, belt in pairs(data.raw["transport-belt"]) do
		adjustUndergroundFor(belt, 2)
	end
end

function shortenAllUndergroundsIncremental()
	local currentBelt = data.raw["transport-belt"]["transport-belt"]
	local currentBeltLen = 2
	while true do
		adjustUndergroundFor(currentBelt, currentBeltLen)
		local nextTierName = currentBelt.next_upgrade
		if nextTierName == nil then return end
		currentBelt = data.raw["transport-belt"][nextTierName]
		currentBeltLen = currentBeltLen + 1
	end
end

------------------------------------------------------------------------

local setting = settings.startup["HarderBasicLogistics-shorten-underground-belts"].value
if setting == "all-1" then
	shortenAllUndergroundsTo1()
elseif setting == "1-then-increment" then
	shortenAllUndergroundsIncremental()
else
	log("ERROR: Unrecognized belt shortening option")
end