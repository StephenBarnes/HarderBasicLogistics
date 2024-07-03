local Common = {}

Common.isLongInserter = function(name)
	-- Used for recipe names, item names, and entity names.
	return ((string.find(name, "long%-inserter") ~= nil)
		or ((string.find(name, "long%-handed") ~= nil) and (string.find(name, "inserter") ~= nil)))
end

Common.isLoaderRegisteredAsInserter = function(name)
	-- For the Miniloaders mod.
	return (string.find(name, "miniloader") ~= nil)
end

return Common