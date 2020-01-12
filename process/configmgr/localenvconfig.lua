local localEnvConfig = {
	-- 浏览器访问本地http服务的时候,需要提供的cookie
	Cookie = "hi=wow",
	-- 浏览器访问本地http服务需提供的sign
	Sign = "sign",
	-- 展示给浏览器中的网页中的链接中的host,支持域名
	PublicHttpHost = "baidu.com",
	-- 展示给浏览器中的网页中的链接中的port
	PublicHttpPort = 80,
	-- 本地根据规则生成html文件时需要找到的目录,大概率是本地网站根目录
	HttpDir = "/var/www/html/",
	-- 脑图文件目录,会在这个目录中生成一些新的文件
	MindMapDir = "mindmap/",
	-- 本地Ip,大概率就是 127.0.0.1,目前多用于服务启动时候拉代码
	InternalIp = "127.0.0.1",
	-- 本地部署的http端口,目前多用于服务器启动的时候拉代码
	InternalHttpPort = 80,
	-- TodoList使用的数据库地址和端口
	TodoDbHost = "127.0.0.1:3306",
	-- TodoList使用的数据库用户
	TodoDbUser = "todo",
	-- TodoList使用的数据库密码
	TodoDbPassword = "123456",

}

return localEnvConfig
