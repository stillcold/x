
function PrintTable(node, debugLv)
	debugLv = debugLv or 1

	local function indent(amt)
		local str = ""
		for i=1,amt do
			str = str .. "\t"
		end
		return str
	end

	local cache, stack, output = {},{},{}
	local depth = 1
	local outputStr = "{\n"

	while true do
		local size = 0
		for k,v in pairs(node) do
			size = size + 1
		end

		local cur_index = 1
		for k,v in pairs(node) do
			if (cache[node] == nil) or (cur_index >= cache[node]) then

				if (string.find(outputStr,"}",outputStr:len())) then
					outputStr = outputStr .. ",\n"
				elseif not (string.find(outputStr,"\n",outputStr:len())) then
					outputStr = outputStr .. "\n"
				end

				table.insert(output,outputStr)
				outputStr = ""

				local key
				if (type(k) == "number" or type(k) == "boolean") then
					key = "["..tostring(k).."]"
				else
					key = "['"..tostring(k).."']"
				end

				if (type(v) == "number" or type(v) == "boolean") then
					outputStr = outputStr .. indent(depth) .. key .. " = "..tostring(v)
				elseif (type(v) == "table") then
					outputStr = outputStr .. indent(depth) .. key .. " = {\n"
					table.insert(stack,node)
					table.insert(stack,v)
					cache[node] = cur_index+1
					break
				else
					outputStr = outputStr .. indent(depth) .. key .. " = '"..tostring(v).."'"
				end

				if (cur_index == size) then
					outputStr = outputStr .. "\n" .. indent(depth-1) .. "}"
				else
					outputStr = outputStr .. ","
				end
			else
				if (cur_index == size) then
					outputStr = outputStr .. "\n" .. indent(depth-1) .. "}"
				end
			end

			cur_index = cur_index + 1
		end

		if (size == 0) then
			outputStr = outputStr .. "\n" .. indent(depth-1) .. "}"
		end

		if (#stack > 0) then
			node = stack[#stack]
			stack[#stack] = nil
			depth = cache[node] == nil and depth + 1 or depth - 1
		else
			break
		end
	end

	table.insert(output,outputStr)
	outputStr = table.concat(output)

	if core and core.debug then
		core.debug(1, outputStr)
	else
		print(outputStr)
	end
end
