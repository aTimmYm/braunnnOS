-- Pure Lua MD5 implementation (based on public domain code)
local bit = {}
bit.bnot = function(n)
    return -n - 1  -- In Lua 5.1+ this works for 32-bit
end
bit.band = function(m, n) return m & n end
bit.bor = function(m, n) return m | n end
bit.bxor = function(m, n) return m ~ n end
bit.brshift = function(n, bits) return n >> bits end
bit.blshift = function(n, bits) return n << bits end

local md5 = {}
md5.ff = 0xffffffff
md5.consts = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
}

local function z(f, a, b, c, d, x, s, ac)
    a = bit.band(a + f(b, c, d) + x + ac, md5.ff)
    return bit.bor(bit.blshift(bit.band(a, bit.brshift(md5.ff, s)), s), bit.brshift(a, 32 - s)) + b
end

local function f(x, y, z) return bit.bor(bit.band(x, y), bit.band(bit.bnot(x), z)) end
local function g(x, y, z) return bit.bor(bit.band(x, z), bit.band(y, bit.bnot(z))) end
local function h(x, y, z) return bit.bxor(x, bit.bxor(y, z)) end
local function i(x, y, z) return bit.bxor(y, bit.bor(x, bit.bnot(z))) end

local function transform(A, B, C, D, X)
    local a, b, c, d = A, B, C, D
    local t = md5.consts

    -- Round 1
    a = z(f, a, b, c, d, X[1], 7, t[1])
    d = z(f, d, a, b, c, X[2], 12, t[2])
    c = z(f, c, d, a, b, X[3], 17, t[3])
    b = z(f, b, c, d, a, X[4], 22, t[4])
    a = z(f, a, b, c, d, X[5], 7, t[5])
    d = z(f, d, a, b, c, X[6], 12, t[6])
    c = z(f, c, d, a, b, X[7], 17, t[7])
    b = z(f, b, c, d, a, X[8], 22, t[8])
    a = z(f, a, b, c, d, X[9], 7, t[9])
    d = z(f, d, a, b, c, X[10], 12, t[10])
    c = z(f, c, d, a, b, X[11], 17, t[11])
    b = z(f, b, c, d, a, X[12], 22, t[12])
    a = z(f, a, b, c, d, X[13], 7, t[13])
    d = z(f, d, a, b, c, X[14], 12, t[14])
    c = z(f, c, d, a, b, X[15], 17, t[15])
    b = z(f, b, c, d, a, X[16], 22, t[16])

    -- Round 2
    a = z(g, a, b, c, d, X[2], 5, t[17])
    d = z(g, d, a, b, c, X[7], 9, t[18])
    c = z(g, c, d, a, b, X[12], 14, t[19])
    b = z(g, b, c, d, a, X[1], 20, t[20])
    a = z(g, a, b, c, d, X[6], 5, t[21])
    d = z(g, d, a, b, c, X[11], 9, t[22])
    c = z(g, c, d, a, b, X[16], 14, t[23])
    b = z(g, b, c, d, a, X[5], 20, t[24])
    a = z(g, a, b, c, d, X[10], 5, t[25])
    d = z(g, d, a, b, c, X[15], 9, t[26])
    c = z(g, c, d, a, b, X[4], 14, t[27])
    b = z(g, b, c, d, a, X[9], 20, t[28])
    a = z(g, a, b, c, d, X[14], 5, t[29])
    d = z(g, d, a, b, c, X[3], 9, t[30])
    c = z(g, c, d, a, b, X[8], 14, t[31])
    b = z(g, b, c, d, a, X[13], 20, t[32])

    -- Round 3
    a = z(h, a, b, c, d, X[6], 4, t[33])
    d = z(h, d, a, b, c, X[9], 11, t[34])
    c = z(h, c, d, a, b, X[12], 16, t[35])
    b = z(h, b, c, d, a, X[15], 23, t[36])
    a = z(h, a, b, c, d, X[2], 4, t[37])
    d = z(h, d, a, b, c, X[5], 11, t[38])
    c = z(h, c, d, a, b, X[8], 16, t[39])
    b = z(h, b, c, d, a, X[11], 23, t[40])
    a = z(h, a, b, c, d, X[14], 4, t[41])
    d = z(h, d, a, b, c, X[1], 11, t[42])
    c = z(h, c, d, a, b, X[4], 16, t[43])
    b = z(h, b, c, d, a, X[7], 23, t[44])
    a = z(h, a, b, c, d, X[10], 4, t[45])
    d = z(h, d, a, b, c, X[13], 11, t[46])
    c = z(h, c, d, a, b, X[16], 16, t[47])
    b = z(h, b, c, d, a, X[3], 23, t[48])

    -- Round 4
    a = z(i, a, b, c, d, X[1], 6, t[49])
    d = z(i, d, a, b, c, X[8], 10, t[50])
    c = z(i, c, d, a, b, X[15], 15, t[51])
    b = z(i, b, c, d, a, X[6], 21, t[52])
    a = z(i, a, b, c, d, X[13], 6, t[53])
    d = z(i, d, a, b, c, X[4], 10, t[54])
    c = z(i, c, d, a, b, X[11], 15, t[55])
    b = z(i, b, c, d, a, X[2], 21, t[56])
    a = z(i, a, b, c, d, X[9], 6, t[57])
    d = z(i, d, a, b, c, X[16], 10, t[58])
    c = z(i, c, d, a, b, X[7], 15, t[59])
    b = z(i, b, c, d, a, X[14], 21, t[60])
    a = z(i, a, b, c, d, X[5], 6, t[61])
    d = z(i, d, a, b, c, X[12], 10, t[62])
    c = z(i, c, d, a, b, X[3], 15, t[63])
    b = z(i, b, c, d, a, X[10], 21, t[64])

    return bit.band(A + a, md5.ff), bit.band(B + b, md5.ff), bit.band(C + c, md5.ff), bit.band(D + d, md5.ff)
end

local function md5_update(state, text)
    local len = #text
    local left = state.len % 64
    state.len = state.len + len
    -- 56 bytes or more? Process one block
    if left + len >= 64 then
        table.move(text, 1, 64 - left, left + 1, state.buffer)
        state.A, state.B, state.C, state.D = transform(state.A, state.B, state.C, state.D, state.buffer)
        local i = 65 - left
        while len - i + 1 >= 64 do
            local block = {string.byte(text, i, i + 63)}
            state.A, state.B, state.C, state.D = transform(state.A, state.B, state.C, state.D, block)
            i = i + 64
        end
        left = (left + len) % 64
        if left > 0 then
            table.move(text, i, i + left - 1, 1, state.buffer)
        end
    else
        table.move(text, 1, len, left + 1, state.buffer)
        left = left + len
    end
    return state
end

local function md5_finish(state)
    local lo = state.len * 8 % 2^32
    local hi = math.floor(state.len * 8 / 2^32)
    local left = state.len % 64
    local fill = 64 - left
    if left == 0 then
        fill = 64
    end
    state.buffer[left + 1] = 0x80
    if left + 1 < fill then
        for i = left + 2, fill do state.buffer[i] = 0 end
    end
    if fill <= 8 then
        for i = 1, fill do state.buffer[i + 64 - fill] = state.buffer[i] end
        for i = 1, 56 do state.buffer[i] = 0 end
        state.A, state.B, state.C, state.D = transform(state.A, state.B, state.C, state.D, state.buffer)
        for i = 1, 64 do state.buffer[i] = 0 end
    else
        for i = left + 2, 64 do state.buffer[i] = 0 end
    end
    state.buffer[57] = lo % 256
    state.buffer[58] = math.floor(lo / 256) % 256
    state.buffer[59] = math.floor(lo / 65536) % 256
    state.buffer[60] = math.floor(lo / 16777216) % 256
    state.buffer[61] = hi % 256
    state.buffer[62] = math.floor(hi / 256) % 256
    state.buffer[63] = math.floor(hi / 65536) % 256
    state.buffer[64] = math.floor(hi / 16777216) % 256
    state.A, state.B, state.C, state.D = transform(state.A, state.B, state.C, state.D, state.buffer)
    lo = state.A
    hi = state.B
    local hash = string.format("%08x%08x%08x%08x", lo, hi, state.C, state.D)
    return hash
end

local function md5(text)
    local state = {
        A = 0x67452301, B = 0xefcdab89, C = 0x98badcfe, D = 0x10325476,
        len = 0, buffer = {}
    }
    md5_update(state, text)
    return md5_finish(state)
end

local function compute_md5(file_path)
    if not fs.exists(file_path) then return nil end
    local file = fs.open(file_path, "r")
    if not file then return nil end
    local content = file.readAll()
    file.close()
    return md5(content)
end

-- Updater logic
local repo_owner = "aTimmYm"  -- Замените на вашего owner
local repo_name = "braunnnOS"  -- Замените на имя repo
local branch = "main"  -- Ваша ветка
local base_url = "https://raw.githubusercontent.com/" .. repo_owner .. "/" .. repo_name .. "/" .. branch .. "/"

local function download_file(url, path)
    local response = http.get(url)
    if not response then
        print("Error downloading: " .. url)
        return false
    end
    local content = response.readAll()
    response.close()
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local file = fs.open(path, "w")
    file.write(content)
    file.close()
    print("Downloaded: " .. path)
    return true
end

-- Main update function
local function update_os()
    -- Download manifest
    local manifest_url = base_url .. "manifest.txt"
    local response = http.get(manifest_url)
    if not response then
        print("Failed to download manifest.txt")
        return
    end
    local manifest_content = response.readAll()
    response.close()

    -- Parse manifest lines
    local files_to_update = {}
    for line in manifest_content:gmatch("[^\r\n]+") do
        local hash, file_path = line:match("(%w+)%s+(.+)")
        if hash and file_path then
            local local_hash = compute_md5(file_path)
            if local_hash ~= hash then
                table.insert(files_to_update, file_path)
            end
        end
    end

    -- Download only needed files
    for _, file_path in ipairs(files_to_update) do
        local file_url = base_url .. file_path
        download_file(file_url, file_path)
    end

    -- Update local manifest if all ok
    if #files_to_update > 0 then
        download_file(manifest_url, "manifest.txt")
        print("Update complete. Updated " .. #files_to_update .. " files.")
    else
        print("No updates needed.")
    end
end

-- Run the update
update_os()