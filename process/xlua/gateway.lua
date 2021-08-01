local core = require "sys.core"
local msg = require "saux.msg"
local rpc = require "saux.rpc"
local np = require "sys.netpacket"
local socket = require "sys.socket"

require "utils.tableutils"

local listen = socket.listen
local readline = socket.readline
local read = socket.read
local readall = socket.readall
local write = socket.write

local function ReadRpc(fd, handler)

	-- 一旦这个循环被打破,后面的数据就不会被消耗掉
	while true do

		local head_data = socket.read(fd, 4)
		if not head_data then return end

		local pcall = core.pcall
		local dataLen = string.unpack("<I4", head_data)

		local ok, err

		if dataLen <= 0 then
			ok, err = pcall(handler, fd, "")
		else
			local str = socket.read(fd, dataLen)
			ok, err = pcall(handler, fd, str)
		end

		if not ok then
			core.close(fd)
			return
		else
			-- core.close(fd)
		end
	end
	
end

function SocketAgent(fd, handler)
	ReadRpc(fd, handler)
end

local server = {
	listen = function (port, handler)
		local h = function(fd)
			SocketAgent(fd, handler)
		end
		listen(port, h)
	end,
}

return server


