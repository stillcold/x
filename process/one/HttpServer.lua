
local server = require "http.server"
local searchMgr = require "SearchMgr"
local write = server.write
local htmlTags = require "HtmlTags"
local console = require "sys.console"
local localConfig = require "LocalConfig"
local core = require "sys.core"
local keywordDatabaseMgr = require "KeywordDatabaseMgr"

local dispatch = {}

local defaultHead = htmlTags.Head
local defaultTail = htmlTags.Tail
local default = defaultHead..defaultTail
local signedHead = htmlTags.HeadWithSign or defaultHead
local addNewSearchItemHead = htmlTags.AddNewSearchItemHead or defaultHead
local addNewSearchItemWithSignHead = htmlTags.AddNewSearchItemHeadWithSign or defaultHead

local function checkRequest(request)

	if request.Cookie ~= core.envget("Cookie") then
		return false
	end

	if not request.form or request.form.sign ~= core.envget("Sign") then
		return false
	end
	
	return true
end

dispatch["/"] = function(fd, request, body)
	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if checkRequest(request) then
		body = signedHead
	end

	write(fd, 200, head, body)
end

local content = ""

dispatch["/download"] = function(fd, request, body)
	write(fd, 200, {"Content-Type: text/plain"}, content)
end

dispatch["/upload"] = function(fd, request, body)
	if request.form.Hello then
		content = request.form.Hello
	end
	local body = "Upload done, please access download to see the result"
	local head = {
		"Content-Type: text/plain",
		}
	write(fd, 200, head, body)
end

dispatch["/search"] = function(fd, request, body)
	if not checkRequest(request) then
		local head = {
			"Content-Type: text/html",
			}
		local body = "并不是谁都能访问的"

		if htmlTags.SearchResultNoSignHead then
			body = htmlTags.SearchResultNoSignHead.."并不是谁都能访问的"..htmlTags.SearchResultTail
		end
		write(fd, 200, head, body)
		return
	end
	if request.form.Hello then
		content = request.form.Hello
	end
	local body = htmlTags.SearchResultHead..searchMgr:GetAnswer(content)..htmlTags.SearchResultTail
	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)
end

dispatch["/detail"] = function(fd, request, body)
	if request.form.Hello then
		content = request.form.Hello
	end
	local body = htmlTags.SearchResultHead..searchMgr:GetDetail(content)..htmlTags.SearchResultTail
	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)
end


dispatch["/addWnd"] = function(fd, request, body)
	local body = addNewSearchItemHead..defaultTail
	local head = {
		"Content-Type: text/html",
		}

	if checkRequest(request) then
print("valid request found")
		body = addNewSearchItemWithSignHead..defaultTail
	end

	write(fd, 200, head, body)
end

dispatch["/add"] = function(fd, request, body)
	local body = default
	local head = {
		"Content-Type: text/html",
	}

	print("handle is add")
	if checkRequest(request) then
		local keyword = request.form.kwd
		local itemType = request.form.itemType
		local parseRule = request.form.parseRule
		local title = request.form.tit
		local content = request.form.cnt

		local item = {
			keyword 	= keyword,
			itemType 	= itemType,
			parseRule 	= parseRule,
			title 		= title,
			content 	= content,
		}
		
		local addResult = keywordDatabaseMgr:Add(item)
		body = addNewSearchItemHead..addResult..defaultTail
	else
		print("invalid request")
	end

	write(fd, 200, head, body)
end

-- Entry!
server.listen(":8089", function(fd, request, body)
	

	local c = dispatch[request.uri]
	if c then
		c(fd, request, body)
	else
		print("Unsupport uri", request.uri)
		write(fd, 404, {"Content-Type: text/plain"}, "404 Page Not Found")
	end
end)


console {
	addr = ":1234"
	}
