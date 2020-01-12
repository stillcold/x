local zproto = require "zproto"

local xproto = zproto:parse[[
	rpc 0x1001 {
		.content:string 1
	}
]]

return xproto
