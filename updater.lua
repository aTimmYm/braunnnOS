local manifest_url = "https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/main/manifest.txt"
local old_manifest = {}
if fs.exists("manifest.txt") then
    for line in io.lines("manifest.txt") do
        local key = line:sub(1,32)
        local value = line:sub(36)
        old_manifest[key] = value
    end
end

local manifest_temp = {}
local files = {}

local function write_f(path, data)
    --fs.makeDir(fs.getDir(path))
    local file = fs.open(path, "w")
    file.write(data)
    file.close()
end

local function update()
    for line in io.lines("manifest_temp.txt") do
        local key = line:sub(1,32)
        local value = line:sub(36)
        manifest_temp[key] = value
    end

    for i,v in pairs(manifest_temp) do
        if not old_manifest[i] then
            table.insert(files,v)
        end
    end
end

local function download_updates()
    if not files[1] then print("No updates") os.sleep(2) return end
    for i,v in pairs(files) do
        local request = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/main/"..v)
        if request then
            local action = "Updating"
            if not fs.exists(v) then action = "Downloading" end
            print(action.." "..v)
            write_f(v,request.readAll())
            request.close()
        end
    end
    print("Update Success. Rebooting") os.sleep(2)
end

local response = http.get(manifest_url)
local server_manifest = response.readAll()
response.close()
if response then
    write_f("manifest_temp.txt",server_manifest)
    update()
    download_updates()
    local file = fs.open("manifest.txt","w")
    file.write(server_manifest)
    file.close()
    fs.delete("manifest_temp.txt")
    os.reboot()
end