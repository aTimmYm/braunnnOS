local manifest_url = "https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/manifest.txt"

local function write_f(path, data)
	local file = fs.open(path, "w")
	file.write(data)
	file.close()
end

local response, err = http.get(manifest_url)
if response then
	local temp = response.readAll()
	response.close()
	for line in temp:gmatch("([^\n]+)\n?") do
		local value = line:sub(36)
		local request = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/"..value)
		if request then
			print("Downloading "..value)
			write_f(value,request.readAll())
			request.close()
		end
	end
	local file = fs.open("manifest.txt","w")
	file.write(temp)
	file.close()
	print("Installing success. Rebooting")
	os.sleep(2)
	os.reboot()
else
	print(err)
end