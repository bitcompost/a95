-- bunch of hacks to make fennel run in arcan

package = { preload = {}, config = "" }

loaded_pkgs = {}

function require(name)
	if loaded_pkgs[name] == nil then
		loaded_pkgs[name] = package.preload[name]()
	end
	return loaded_pkgs[name]
end

local function read(file, what)
	if what == "*all" then
		local res = ""
		local f = open_nonblock(file.filename)
		local line, alive = f:read(true)
		while alive do
			if line then
				res = res .. line
			end
			line, alive = f:read(true)
		end 
		return res
	end
	return nil
end

local function close(_)
	return nil
end

local function open(filename, _)
	return { filename = filename, read = read, close = close  }
end

io = { open = open }

function load(code, name, mode, env)
	if env then
		setmetatable(_G, getmetatable(env))
	end
	return loadstring(code, name)
end

function xpcall(f1, err)
	local ok, res = pcall(f1)
	if not ok then
		return ok, err(res)
	end
	return ok, res
end

fennel = system_load("fennel.lua")()

debug.traceback = fennel.traceback

fennel.dofile("a95.fnl", {allowedGlobals = false, correlate = true})

