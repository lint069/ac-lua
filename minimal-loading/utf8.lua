local utf8 = {}

---@param str string @Input string.
---@return integer len @Number of characters in the string.
function utf8.len(str)
    local _, len = string.gsub(str, '[^\128-\191]', '')
    return len
end

---@param str string @Input string. Needs to be valid UTF-8.
---@param i integer? @Starting character index.
---@param j integer? @Ending character index.
---@return string substring @Substring of the input string from i to j.
function utf8.sub(str, i, j)
    i = i or 1
    j = j or -1

    if i < 0 or j < 0 then
        local n = utf8.len(str)
        if i < 0 then i = n + 1 + i end
        if j < 0 then j = n + 1 + j end
    end

    if j < i then return '' end

    local pos, bytes = 1, #str
    local len = 0
    local startByte, endByte

    while pos <= bytes do
        len = len + 1
        if len == i then startByte = pos end

        pos = pos + (
            str:byte(pos) >= 0xF0 and 4 or
            str:byte(pos) >= 0xE0 and 3 or
            str:byte(pos) >= 0xC0 and 2 or 1
        )

        if len == j then
            endByte = pos - 1
            break
        end
    end

    if not startByte then return '' end

    return str:sub(startByte, endByte)
end

return utf8