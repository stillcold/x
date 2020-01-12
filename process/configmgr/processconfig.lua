
return {
	--[[
	processName = {
		{
			path 	= "文件路径",
			fileType= <config/lua>,
			lineEnd	= 空串 或者 逗号, -- lua文件结尾有逗号,config没有
			items	= {
				{"条目名", 本地变量名, 默认值},
			},
		},
	}
	--]]

	one = 
	{
		{
			path 	= "process/one/entry.config",
			lineEnd = "",
			fileType="config",
			items 	= {
				{"daemon", nil, 0},
				{"bootstrap", nil, "process/one/entry.lua"},
				{"lualib_path", nil, "test/?.lua;lualib/?.lua;process/one/?.lua;"},
				{"lualib_cpath", nil, "luaclib/?.so"},
				{"Cookie", "Cookie", "ticket=koujue"},
				{"Sign", "Sign", "sign"},
			},
		},
		{
			path	= "process/one/LocalConfig.lua",
			lineEnd	= ",",
			fileType= "lua",
			items	= {
				{"InternalIp", "InternalIp", "127.0.0.1"},
				{"InternalHttpPort", "InternalHttpPort", 80},
				{"PublicHttpHost", "PublicHttpHost", "sample.com"},
				{"PublicHttpPort", "PublicHttpPort", 80},
				{"HttpDir", "HttpDir", "/var/www/html/"},
				{"MindMapDir", "MindMapDir","mindmap/"},

			},
		},
	},
	todolist = 
	{
		{
			path	= "process/todolist/entry.config",
			lineEnd	= "",
			fileType= "config",
			items	= {
				{"daemon", nil, 0},
				{"bootstrap", nil, "process/todolist/main.lua"},
				{"lualib_path", nil, "test/?.lua;lualib/?.lua;process/todolist/?.lua;"},
				{"lualib_cpath", nil, "luaclib/?.so"},
				{"Cookie", "Cookie", "ticket=koujue"},
				{"Sign", "Sign", "sign"},
				{"DbUser","TodoDbUser", "todo"},
				{"DbPass", "TodoDbPassword", "123456"},
				{"DbHost", "TodoDbHost", "127.0.0.1:3306"},
			},
		},
	},
	basestaion = 
	{
		{
			path	= "process/basestation/master/entry.config",
			lineEnd	= "",
			fileType= "config",
			items	= {
				{"daemon", nil, 0},
				{"bootstrap", nil, "process/basestation/master/main.lua"},
				{"lualib_path", nil, "test/?.lua;lualib/?.lua;process/basestation/master/?.lua;process/basestation/common/?.lua;"},
				{"lualib_cpath", nil, "luaclib/?.so"},
				{"master_listen_ip", "BaseStationMasterListenIp", "0.0.0.0"},
				{"master_listen_port", "BaseStaionMasterListenPort", 10001},
				{"admin_port", "BaseStaionAdminPort", 10002},
				{"log_level", "BaseStaionLogLevel", 2},
				{"log_default", "BaseStationLogDefault", -1},
				{"auth_salt", "BaseStationAuthSalt", "salt"},
				{"auth_code", "BaseStationAuthCode", "code"},
			},
		},
		{
			path	= "process/basestation/slave/entry.config",
			lineEnd	= "",
			fileType= "config",
			items	= {
				{"daemon", nil, 0},
				{"bootstrap", nil, "process/basestation/slave/main.lua"},
				{"lualib_path", nil, "test/?.lua;lualib/?.lua;process/basestation/slave/?.lua;process/basestation/common/?.lua;"},
				{"lualib_cpath", nil, "luaclib/?.so"},
				{"master_host", "PublicIp", "127.0.0.1"},
				{"master_listen_port", "BaseStaionMasterListenPort", 10001},
				{"log_level", "BaseStaionLogLevel", 2},
				{"log_default", "BaseStationLogDefault", -1},
				{"auth_salt", "BaseStationAuthSalt", "salt"},
				{"auth_code", "BaseStationAuthCode", "code"},
			},
		},
	},
}

