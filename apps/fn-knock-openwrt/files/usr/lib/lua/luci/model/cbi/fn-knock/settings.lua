local m = Map("fn-knock", translate("敲门 fn-knock 设置"), translate("配置 fn-knock 服务参数"))

m:chain("/etc/config/fn-knock")

local s = m:section(NamedSection, "main", "fn-knock", translate("基本设置"))
s.anonymous = true

local enabled = s:option(Flag, "enabled", translate("启用服务"))
enabled.rmempty = false

local backend_port = s:option(Value, "backend_port", translate("后端 API 端口"))
backend_port.datatype = "port"
backend_port.default = "7998"
backend_port.description = translate("后端管理 API 监听端口")

local auth_port = s:option(Value, "auth_port", translate("认证服务端口"))
auth_port.datatype = "port"
auth_port.default = "7997"
auth_port.description = translate("认证服务监听端口")

local go_backend_port = s:option(Value, "go_backend_port", translate("Go 网关管理端口"))
go_backend_port.datatype = "port"
go_backend_port.default = "7996"
go_backend_port.description = translate("Go 网关管理接口端口")

local proxy_port = s:option(Value, "proxy_port", translate("网关代理端口"))
proxy_port.datatype = "port"
proxy_port.default = "7999"
proxy_port.description = translate("主要访问入口端口")

local node_bin = s:option(Value, "node_bin", translate("Node.js 路径"))
node_bin.placeholder = "/usr/bin/node"
node_bin.description = translate("留空则自动查找系统 Node.js")

local data_dir = s:option(Value, "data_dir", translate("数据目录"))
data_dir.default = "/var/run/fn-knock"
data_dir.description = translate("运行时数据存储目录")

return m
