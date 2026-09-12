--most, if not all, based on
--https://dl.acm.org/doi/10.1145/383259.383317
local sh = {}

local PI = math.pi
local TWO_PI = 2.0 * math.pi

--lambertian diffuse convolution factors
local A0 = PI
local A1 = 2.0 * PI / 3.0
local A2 = PI / 4.0

---evaluates 9 SH basis functions with convolution factors baked in
---@param dir {x: number, y: number, z: number} normalized direction vector (y-up)
---@return number[] 9 SH basis values
local function evaluateBasis(dir)
    local x, y, z = dir.x, dir.y, dir.z

    return {
        0.282095 * A0,

        0.488603 * A1 * z,
        0.488603 * A1 * y,
        0.488603 * A1 * x,

        1.092548 * A2 * x * z,
        1.092548 * A2 * z * y,
        0.315392 * A2 * (3.0 * y * y - 1.0),
        1.092548 * A2 * x * y,
        0.546274 * A2 * (x * x - z * z),
    }
end

---computes 9 RGB SH irradiance coefficients from equirectangular pixel data
---@param width number image width
---@param height number image height
---@param getPixelRGB fun(x: number, y: number): number, number, number returns (r, g, b) at pixel coordinates
---@return table[] list of 9 vec3-like tables {r, g, b}
function sh.compute(width, height, getPixelRGB)
    local coeffs = {}
    for i = 1, 9 do
        coeffs[i] = { r = 0, g = 0, b = 0 }
    end

    local dTheta = PI / height
    local dPhi = TWO_PI / width

    for y = 0, height - 1 do
        local theta = (y + 0.5) * dTheta
        local sinTheta = math.sin(theta)
        local cosTheta = math.cos(theta)
        local dOmega = sinTheta * dTheta * dPhi

        for x = 0, width - 1 do
            local phi = (x + 0.5) * dPhi - PI

            local dir = {
                x = sinTheta * math.cos(phi),
                y = cosTheta,
                z = sinTheta * math.sin(phi),
            }

            local basis = evaluateBasis(dir)
            local r, g, b = getPixelRGB(x, y)

            for i = 1, 9 do
                local weight = basis[i] * dOmega
                coeffs[i].r = coeffs[i].r + r * weight
                coeffs[i].g = coeffs[i].g + g * weight
                coeffs[i].b = coeffs[i].b + b * weight
            end
        end
    end

    return coeffs
end

return sh
