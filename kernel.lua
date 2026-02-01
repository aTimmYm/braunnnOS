package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local co_resume = coroutine.resume
local co_create = coroutine.create
local co_status = coroutine.status
local co_yield	= coroutine.yield
local co_running= coroutine.running
local unpack	= table.unpack
local t_remove	= table.remove
local t_insert	= table.insert

-- local _kernel = {}
_G.sysclipboard = ""
local processes = {}
local kernel_running = true
local t_native = term.native()
-- local dummy_term = window.create(term.current(), 1, 1, 51, 19, false)
local ids = 1
local instructions = 100000
-- local line_count = 0
local event_queue = {}
local interruption, need_resume = true

local sys = require "syscalls"
local wm = require "WManager"
package.loaded["WManager"] = nil

-- local dummy_term = {
--     write = function() end,
--     blit = function() end,
--     clear = function() end,
--     clearLine = function() end,
--     setCursorPos = function() end,
--     setCursorBlink = function() end,
--     getCursorPos = function() return 1, 1 end,
--     setTextColor = function() end,
--     setTextColour = function() end,
--     setBackgroundColor = function() end,
--     setBackgroundColour = function() end,
--     isColor = function() return true end,
--     isColour = function() return true end,
--     getSize = function() return 51, 19 end,
--     scroll = function() end,
--     redirect = function(target) return target end,
--     current = function() return dummy_term end,
--     native = function() return dummy_term end,
-- 	getPaletteColor = function () return 1 end,
-- 	getPaletteColour = function () return 1 end,
-- 	setPaletteColour = function () end,
-- 	setPaletteColor = function () end
-- }

local function hook()
	if coroutine.isyieldable() then
		need_resume = true
		co_yield("__interrupts")
	end
end

function sys.register_window(opts, x, y, w, h, border, order, menu)
	if not wm then return end
	local running_co = co_running()

	for pid, process in pairs(processes) do
		if process.co == running_co then
			process.win = wm.create(opts, x, y, w, h, border, pid, order, menu)
			term.redirect(process.win.term)
			return process.win
			-- break
		end
	end
end

local function process_end(pid)
	if wm then wm.close_window(pid) end
	processes[pid] = nil
end
sys.process_end = process_end

function sys.get_processes_info()
	local info = {}
	for pid, process in pairs(processes) do
		local temp = {
			pid = pid,
			title = process.win and process.win.title or process.name
		}
		table.insert(info, temp)
	end
	return info
end

function sys.get_proc_name(pid)
	return processes[pid].name
end

function sys.get_proc_path(pid)
	return processes[pid].path
end

function sys.getpid()
	local co = co_running()
	for pid, process in pairs(processes) do
		if process.co == co then
			return pid
		end
	end
end

function sys.screen_get_size()
	return t_native.getSize()
end

local function process_resume(pid, args)
	-- log("PID: "..tostring(pid).."  ARGS: "..args[1])
	-- log(args[1])
	if not pid then return end
	local process = processes[pid]
	local old_term = term.current()
	local win_term = process.win and process.win.term

	if process.filter and args[1] ~= process.filter or args[1] == "terminate" then return end
	-- local status, filter

	if win_term then term.redirect(win_term) end

	-- if args[1] ~= "__interrupts" then
	-- 	status, filter = co_resume(process.co, t_unpack(args))
	-- else
	-- 	status, filter = co_resume(process.co)
	-- end
	local status, filter = co_resume(process.co, unpack(args))

	term.redirect(old_term)

	if status then
		process.filter = filter

		if co_status(process.co) == "dead" then
			log(filter)
			process_end(pid)
		end
		-- debug.sethook(process.co, hook, "", instructions)
	else
        local traceback = debug.traceback(process.co, filter)
        log("Помилка в процесі PID " .. pid .. ":\n" .. traceback)
		process_end(pid)
	end
end

function sys.ipc(pid, ...)
	-- local co, main = co_running()
	-- process_resume(pid, {...})
	t_insert(event_queue, 1, {pid, {...}})
	-- os.queueEvent("ipc")
end

local function get_parent_path()
	local p_co = co_running()
	for _, process in pairs(processes) do
		if p_co == process.co then
			return process.path
		end
	end
end

function sys.process_create(func, args, name, path)
	local pid = ids
	ids = ids + 1
	local process = {}
	processes[pid] = process

	process.co = co_create(func)
	process.path = path or get_parent_path()
	process.name = name or process.path

	-- debug.sethook(process.co, hook, "", instructions)
	process_resume(pid, args)

	return pid
end

function sys.execute(path, name, env, args)
	args = args or {}
	local func, err = loadfile(path, env)
	if func then
		return sys.process_create(func, args, name, path)
	else
		log(err)
	end
end

local function event_handler(evt)
	-- if evt[1] == "ipc" then return end
	local wm_dispatch = wm.dispatch_event(evt)

	if not wm_dispatch then
		for pid, _ in pairs(processes) do
			t_insert(event_queue, 1, {pid, evt})
		end
	else
		if wm_dispatch ~= true then
			t_insert(event_queue, 1, wm_dispatch)
		end
	end
end

local function kernel_run()
	wm.panel_pid = sys.execute("lib/panel.lua", "panel", _ENV)
	wm.desktop_pid = sys.execute("lib/DManager.lua", "desktop", _ENV)
	wm.docker_pid = sys.execute("sbin/Docker/main.lua", "docker", _ENV)
	-- wm.uiserver_pid = sys.execute("sbin/SystemUIServer/main.lua", "SystemUIServer", _ENV)
	while kernel_running do
		if wm then wm.redraw_all() end
		local evt = {os.pullEventRaw()}
		local event_name = evt[1]

		if event_name == "term_resize" then evt[2], evt[3] = t_native.getSize() end
		if event_name == "terminate" then kernel_running = false end
		if event_name == "__interrupts" then interruption = true end
		if event_name == "paste" and _G.sysclipboard then evt[2] = _G.sysclipboard end
		if event_name == "paste_on" then _G.sysclipboard = "" goto continue end
		if event_name == "paste_off" then _G.sysclipboard = nil goto continue end

		event_handler(evt)

		while #event_queue > 0 do
			-- log(textutils.serialise(event_queue[#event_queue]))
			local queue = t_remove(event_queue, #event_queue)
			process_resume(queue[1], queue[2])
		end

		if need_resume and interruption then
			os.queueEvent("__interrupts")
			need_resume = false
			interruption = false
		end
		::continue::
	end
end

local function TEST()
	while true do
		term.write("A")
		os.sleep(1)
	end
end

kernel_run()