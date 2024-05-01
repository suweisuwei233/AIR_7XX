

maker = loadfile("maker.lua")()

local _, names = io.lsdir("..\\lib\\", 100)
for _, v in pairs(names) do
    --print(json.encode(v))
    local name = v["name"]
    if name:endsWith(".lua") then
        local lines = {}
        for line in io.lines("..\\lib\\" .. name) do
            -- print(line)
            table.insert(lines, line)
        end
        local path
        local f = io.open(name:sub(1, #name - 4) .. ".md", "wb")
        f:write(maker(lines))
        f:close()
    end
end

