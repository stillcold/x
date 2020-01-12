require "global"
require "SAConfig"

local core = require "sys.core"

local CodeMgr = require "CodeMgr"


local function downloadCode()

	CodeMgr:DownLoadCode()
end

core.start(function()
	downloadCode()
end)


