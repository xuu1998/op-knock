module("luci.controller.fn-knock", package.seeall)

function index()
    entry({"admin", "services", "fn-knock"}, alias("admin", "services", "fn-knock", "status"), _("敲门 fn-knock"), 60).dependent = true
    entry({"admin", "services", "fn-knock", "status"}, template("fn-knock/status"), _("状态"), 1)
    entry({"admin", "services", "fn-knock", "settings"}, cbi("fn-knock/settings"), _("设置"), 2)
    entry({"admin", "services", "fn-knock", "action"}, call("action_handler"), nil).leaf = true
end

function action_handler()
    local action = luci.http.formvalue("action")
    local result = {}

    if action == "start" then
        result.success, result.output = run_cmd("/etc/init.d/fn-knock start")
    elseif action == "stop" then
        result.success, result.output = run_cmd("/etc/init.d/fn-knock stop")
    elseif action == "restart" then
        result.success, result.output = run_cmd("/etc/init.d/fn-knock restart")
    elseif action == "status" then
        result.running = is_running()
        result.enabled = is_enabled()
    elseif action == "enable" then
        result.success, result.output = run_cmd("/etc/init.d/fn-knock enable")
    elseif action == "disable" then
        result.success, result.output = run_cmd("/etc/init.d/fn-knock disable")
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function run_cmd(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    local output = handle:read("*a")
    handle:close()
    return true, output
end

function is_running()
    local handle = io.popen("/etc/init.d/fn-knock status >/dev/null 2>&1; echo $?")
    local rc = handle:read("*l")
    handle:close()
    return rc == "0"
end

function is_enabled()
    local f = io.open("/etc/rc.d/S99fn-knock", "r")
    if f then
        f:close()
        return true
    end
    return false
end
