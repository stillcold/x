local core = require "sys.core"
local unpack = table.unpack

function registertick(func, inteval, ...)

	local argc = select("#", ...)
	local nextFun
	if argc > 0 then
		
		local args = {...}
		
		nextFun = function()
			
			func(unpack(args, 1, argc))
			core.timeout(inteval, nextFun)
		end
	else
		nextFun = function()
			func()
			core.timeout(inteval, nextFun)
		end
	end
	
	core.timeout(inteval, nextFun)
end

function registertickwithcount(func, inteval, tickCount, ...)

	tickCount = tickCount or -1

	local argc = select("#", ...)

	local nextFun

	if argc > 0 then
		
		local args = {...}
		
		nextFun = function ()

			if tickCount == 0 then
				return
			end

			if tickCount > 0 then
				tickCount = tickCount - 1
			end

			core.debug(0, "tick count left is ", tickCount)
			
			func(unpack(args, 1, argc))
			core.timeout(inteval, nextFun)
		end
	else
		nextFun = function()
			if tickCount == 0 then
				return
			end

			if tickCount > 0 then
				tickCount = tickCount - 1
			end

			print("tick count left is ", tickCount)

			func()
			core.timeout(inteval, nextFun)
		end
	end
	core.timeout(inteval, nextFun)
end
