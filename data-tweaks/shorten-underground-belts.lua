
local function adjustUndergroundRecipeDifficulty(recipeDifficulty, numBelts)
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

local function adjustUndergroundRecipe(recipe, numBelts)
	-- Adjusts the ingredients of `recipe` to require `numBelts` transport belts of that tier, if it currently requires any.
	if recipe.normal then
		adjustUndergroundRecipeDifficulty(recipe.normal, numBelts)
		adjustUndergroundRecipeDifficulty(recipe.expensive, numBelts)
	else
		adjustUndergroundRecipeDifficulty(recipe, numBelts)
	end
end

local function adjustUndergroundFor(belt, length)
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

local function shortenAllUndergroundsTo1()
	for _, belt in pairs(data.raw["transport-belt"]) do
		adjustUndergroundFor(belt, 2)
	end
end

local function findLowestTierTransportBelt()
	local currentBelt = data.raw["transport-belt"]["transport-belt"]
	local anotherRound = true
	while anotherRound do
		-- look through transport belts for something that upgrades to current belt
		anotherRound = false
		for _, belt in pairs(data.raw["transport-belt"]) do
			if belt.next_upgrade == currentBelt.name then
				currentBelt = belt
				anotherRound = true
				break
			end
		end
	end
	return currentBelt
end

local function shortenAllUndergroundsIncremental()
	local currentBelt = findLowestTierTransportBelt()
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
elseif setting ~= "off" then
	log("ERROR: Unrecognized belt shortening option")
end
