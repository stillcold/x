
local configMgr = require "configmgr"

local core = require "sys.core"

require "utils/tableutils"

core.start(
	function()
		configMgr:DoGen()
	end
)
