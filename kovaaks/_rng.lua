local rng = {}
local Rng = {}
Rng.__index = Rng

---construct isolated, deterministic RNG instance
---@param seed number
---@return table
function rng.new(seed)
    local self = setmetatable({}, Rng)
    self.state = math.floor(math.abs(seed or 1)) % 2147483647
    if self.state == 0 then
        self.state = 1
    end
    return self
end

---returns pseudo-random float in [0.0, 1.0)
---@return number
function Rng:next()
    self.state = (self.state * 48271) % 2147483647
    return (self.state - 1) / 2147483646
end

---returns pseudo-random integer in [min, max]
---@param min number
---@param max number
---@return number
function Rng:int(min, max)
    return math.floor(min + self:next() * (max - min + 1))
end

return rng
