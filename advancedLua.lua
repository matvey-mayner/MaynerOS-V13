
--[[
	
	Advanced Lua Library v1.1 by ECS

	This library extends a lot of default Lua methods
	and adds some really cool features that haven't been
	implemented yet, such as fastest table serialization,
	table binary searching, string wrapping, numbers rounding, etc.

]]

local filesystem = require("filesystem")
local unicode = require("unicode")
local bit32 = require("bit32")

-------------------------------------------------- System extensions --------------------------------------------------

function _G.getCurrentScript()
	local info
	for runLevel = 0, math.huge do
		info = debug.getinfo(runLevel)
		if info then
			if info.what == "main" then
				return info.source:sub(2, -1)
			end
		else
			error("Failed to get debug info for runlevel " .. runLevel)
		end
	end
end

function enum(...)
	local args, enums = {...}, {}
	for i = 1, #args do
		if type(args[i]) ~= "string" then error("Function argument " .. i .. " have non-string type: " .. type(args[i])) end
		enums[args[i]] = i
	end
	return enums
end

function swap(a, b)
	return b, a
end

-------------------------------------------------- Bit32 extensions --------------------------------------------------

function bit32.numberToByteArray(number)
	local byteArray = {}
	while number > 0 do
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	end
	return byteArray
end

function bit32.byteArrayToNumber(byteArray)
	local number = byteArray[1]
	for i = 2, #byteArray do
		number = bit32.bor(byteArray[i], bit32.lshift(number, 8))
	end
	return number
end

function bit32.bitArrayToByte(bitArray)
	local number = 0
	for i = 1, #bitArray do
		number = bit32.bor(bitArray[i], bit32.lshift(number, 1))
	end
	return number
end

bit32.byteArrayFromNumber = bit32.numberToByteArray
bit32.numberFromByteArray = bit32.byteArrayToNumber

-------------------------------------------------- Math extensions --------------------------------------------------

function math.round(num) 
	if num >= 0 then
		return math.floor(num + 0.5)
	else
		return math.ceil(num - 0.5)
	end
end

function math.roundToDecimalPlaces(num, decimalPlaces)
	local mult = 10 ^ (decimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function math.getDigitCount(num)
	return num == 0 and 1 or math.ceil(math.log(num + 1, 10))
end

function math.doubleToString(num, digitCount)
	return string.format("%." .. (digitCount or 1) .. "f", num)
end

function math.shortenNumber(number, digitCount)
	local shortcuts = {
		"K",
		"M",
		"B",
		"T"
	}

	local index = math.floor(math.log(number, 1000))
	if number < 1000 then
		return number
	elseif index > #shortcuts then
		index = #shortcuts
	end

	return math.roundToDecimalPlaces(number / 1000 ^ index, digitCount) .. shortcuts[index]
end

-------------------------------------------------- Table extensions --------------------------------------------------

local function doSerialize(array, prettyLook, indentationSymbol, indentationSymbolAdder, equalsSymbol, currentRecusrionStack, recursionStackLimit)
	local text, keyType, valueType, stringValue = {"{"}
	table.insert(text, (prettyLook and "\n" or nil))
	
	for key, value in pairs(array) do
		keyType, valueType, stringValue = type(key), type(value), tostring(value)

		if keyType == "number" or keyType == "string" then
			table.insert(text, (prettyLook and table.concat({indentationSymbol, indentationSymbolAdder}) or nil))
			table.insert(text, "[")
			table.insert(text, (keyType == "string" and table.concat({"\"", key, "\""}) or key))
			table.insert(text, "]")
			table.insert(text, equalsSymbol)
			
			if valueType == "number" or valueType == "boolean" or valueType == "nil" then
				table.insert(text, stringValue)
			elseif valueType == "string" or valueType == "function" then
				table.insert(text, "\"")
				table.insert(text, stringValue)
				table.insert(text, "\"")
			elseif valueType == "table" then
				-- Ограничение стека рекурсии
				if currentRecusrionStack < recursionStackLimit then
					table.insert(text, table.concat(doSerialize(value, prettyLook, table.concat({indentationSymbol, indentationSymbolAdder}), indentationSymbolAdder, equalsSymbol, currentRecusrionStack + 1, recursionStackLimit)))
				else
					table.insert(text, "...")
				end
			end
			
			table.insert(text, ",")
			table.insert(text, (prettyLook and "\n" or nil))
		end
	end

	-- Удаляем запятую
	if prettyLook then
		if #text > 2 then
			table.remove(text, #text - 1)
		end
		-- Вставляем заодно уж символ индентации, благо чек на притти лук идет
		table.insert(text, indentationSymbol)
	else
		if #text > 1 then
			table.remove(text, #text)
		end
	end

	table.insert(text, "}")

	return text
end

function table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit)
	checkArg(1, array, "table")
	return table.concat(
		doSerialize(
			array,
			prettyLook,
			"",
			string.rep(indentUsingTabs and "	" or " ", indentationWidth or 2),
			prettyLook and " = " or "=",
			1,
			recursionStackLimit or math.huge
		)
	)
end

function table.unserialize(serializedString)
	checkArg(1, serializedString, "string")
	local success, result = pcall(load("return " .. serializedString))
	if success then return result else return nil, result end
end

table.toString = table.serialize
table.fromString = table.unserialize

function table.toFile(path, array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit, appendToFile)
	checkArg(1, path, "string")
	checkArg(2, array, "table")
	filesystem.makeDirectory(filesystem.path(path) or "")
	local file = io.open(path, appendToFile and "a" or "w")
	file:write(table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit))
	file:close()
end

function table.fromFile(path)
	checkArg(1, path, "string")
	if filesystem.exists(path) then
		if filesystem.isDirectory(path) then
			error("\"" .. path .. "\" is a directory")
		else
			local file = io.open(path, "r")
			local data = table.unserialize(file:read("*a"))
			file:close()
			return data
		end
	else
		error("\"" .. path .. "\" doesn't exists")
	end
end

function table.copy(tableToCopy)
	local function recursiveCopy(source, destination)
		for key, value in pairs(source) do
			if type(value) == "table" then
				destination[key] = {}
				recursiveCopy(source[key], destination[key])
			else
				destination[key] = value
			end
		end
	end

	local tableThatCopied = {}
	recursiveCopy(tableToCopy, tableThatCopied)

	return tableThatCopied
end

function table.binarySearch(t, requestedValue)
	local function recursiveSearch(startIndex, endIndex)
		local difference = endIndex - startIndex
		local centerIndex = math.floor(difference / 2 + startIndex)

		if difference > 1 then
			if requestedValue >= t[centerIndex] then
				return recursiveSearch(centerIndex, endIndex)
			else
				return recursiveSearch(startIndex, centerIndex)
			end
		else
			if math.abs(requestedValue - t[startIndex]) > math.abs(t[endIndex] - requestedValue) then
				return t[endIndex]
			else
				return t[startIndex]
			end
		end
	end

	return recursiveSearch(1, #t)
end

function table.size(t)
	local size = #t
	if size == 0 then for key in pairs(t) do size = size + 1 end end
	return size
end

-------------------------------------------------- String extensions --------------------------------------------------

function string.canonicalPath(str)
	return string.gsub("/" .. str, "%/+", "/")
end

function string.optimize(str, indentationWidth)
	str = string.gsub(str, "\r\n", "\n")
	str = string.gsub(str, "	", string.rep(" ", indentationWidth or 2))
	return str
end

function string.optimizeForURLRequests(code)
	if code then
		code = string.gsub(code, "([^%w ])", function (c)
			return string.format("%%%02X", string.byte(c))
		end)
		code = string.gsub(code, " ", "+")
	end
	return code 
end

function string.unicodeFind(str, pattern, init, plain)
	if init then
		if init < 0 then
			init = -#unicode.sub(str,init)
		elseif init > 0 then
			init = #unicode.sub(str, 1, init - 1) + 1
		end
	end
	
	a, b = string.find(str, pattern, init, plain)
	
	if a then
		local ap, bp = str:sub(1, a - 1), str:sub(a,b)
		a = unicode.len(ap) + 1
		b = a + unicode.len(bp) - 1
		return a, b
	else
		return a
	end
end

function string.limit(text, size, fromLeft, noDots)
	local length = unicode.len(text)
	if length <= size then return text end

	if fromLeft then
		if noDots then
			return unicode.sub(text, length - size + 1, -1)
		else
			return "…" .. unicode.sub(text, length - size + 2, -1)
		end
	else
		if noDots then
			return unicode.sub(text, 1, size)
		else
			return unicode.sub(text, 1, size - 1) .. "…"
		end
	end
end

function string.wrap(strings, limit)
	strings = type(strings) == "string" and {strings} or strings

	local currentString = 1
	while currentString <= #strings do
		local words = {}; for word in string.gmatch(tostring(strings[currentString]), "[^%s]+") do table.insert(words, word) end

		local newStringThatFormedFromWords, oldStringThatFormedFromWords = "", ""
		local word = 1
		local overflow = false
		while word <= #words do
			oldStringThatFormedFromWords = oldStringThatFormedFromWords .. (word > 1 and " " or "") .. words[word]
			if unicode.len(oldStringThatFormedFromWords) > limit then
				if unicode.len(words[word]) > limit then
					local left = unicode.sub(oldStringThatFormedFromWords, 1, limit)
					local right = unicode.sub(strings[currentString], unicode.len(left) + 1, -1)
					overflow = true
					strings[currentString] = left
					if strings[currentString + 1] then
						strings[currentString + 1] = right .. " " .. strings[currentString + 1]
					else
						strings[currentString + 1] = right
					end 
				end
				break
			else
				newStringThatFormedFromWords = oldStringThatFormedFromWords
			end
			word = word + 1
		end

		if word <= #words and not overflow then
			local fuckToAdd = table.concat(words, " ", word, #words)
			if strings[currentString + 1] then
				strings[currentString + 1] = fuckToAdd .. " " .. strings[currentString + 1]
			else
				strings[currentString + 1] = fuckToAdd
			end
			strings[currentString] = newStringThatFormedFromWords
		end

		currentString = currentString + 1
	end

	return strings
end

-------------------------------------------------- Playground --------------------------------------------------

-- local t =  {
-- 	abc = 123,
-- 	def = {
-- 		lox = "debil",
-- 		vagina = {
-- 			chlen = 555,
-- 			devil = 666,
-- 			god = 777,
-- 			serost = {
-- 				tripleTable = "aefaef",
-- 				aaa = "bbb",
-- 				ccc = 123,
-- 			}
-- 		}
-- 	},
-- 	ghi = "HEHE",
-- 	emptyTable = {},
-- }

-- print(table.toString(t, true))

------------------------------------------------------------------------------------------------------------------

return {loaded = true}
