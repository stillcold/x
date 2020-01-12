local LocalConfig = require "LocalConfig"

SAConfig = {
	CodeConfig = {
		Host = LocalConfig.InternalIp or "127.0.0.1",
		Port = LocalConfig.InternalHttpPort or "80",
		PublicHttpHost = LocalConfig.PublicHttpHost,
		PublicHttpPort = LocalConfig.PublicHttpPort,
		DownloadPreUrl = "DownloadCode.php?actionName=no&fileName=",
		ListDirPreUrl = "DownloadCode.php?actionName=list&fileName=",
		DownloadDir = {
			{"keywords", "extra"},
		},
		LocalHttpDir = LocalConfig.HttpDir or "/var/www/html/",
		LocalMindMapDir = LocalConfig.MindMapDir or "mind/SkillSet/",
		MindMapConfig = {
			GenDynamicFilePath = LocalConfig.HttpDir..LocalConfig.MindMapDir,
			GenDynamicFileName = "bundle_dynamic.js",
		},
		Alias = {
			{"HtmlTags", "process/one/HtmlTags.lua"},
			{"KeywordTbl", "process/one/KeywordTbl.lua"},
			{"keywords/J1900", "process/one/keywords/J1900.lua"},
			{"keywords/XEngineConfig", "process/one/keywords/XEngineConfig.lua"},
		},
	},
	
}
