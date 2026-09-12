local renderer = {}

local hdri = require('_render/hdri')
local settings = require('_settings')

local presentation = settings.graphics_presentation
local ssaa = settings.graphics_ssaa

local activeEnvironment = hdri.load(settings.graphics_hdri)
local targetCapacity = -1
local renderParams

local shader_core = [[
    struct Ray {
        float3 ro;
        float3 rd;
    };

    static const int HIT_NONE = 0;
    static const int HIT_ENV = 1;
    static const int HIT_TARGET = 2;

    static const float PI = 3.14159265359;
    static const float TWO_PI = 6.28318530718;

    static const float INF = 1e9;

    struct Hit {
        float t;
        float3 normal;
        int kind;
    };

    Hit makeMiss() {
        Hit hit;
        hit.t = INF;
        hit.normal = float3(0.0, 0.0, 0.0);
        hit.kind = HIT_NONE;
        return hit;
    }
]]

local shader_geom = [[
    Hit intersectBackdrop(Ray ray, float planeZ, float4 bounds) {
        if (abs(ray.rd.z) < 1e-6) {
            return makeMiss();
        }

        float t = (planeZ - ray.ro.z) / ray.rd.z;
        if (t <= 0.0) {
            return makeMiss();
        }

        float3 p = ray.ro + ray.rd * t;
        if (p.x < bounds.x || p.x > bounds.z || p.y < bounds.y || p.y > bounds.w) {
            return makeMiss();
        }

        Hit hit;
        hit.t = t;
        hit.normal = float3(0.0, 0.0, -1.0);
        hit.kind = HIT_ENV;
        return hit;
    }

    Hit intersectSphere(Ray ray, float4 sphere) {
        float3 oc = ray.ro - sphere.xyz;
        float b = dot(oc, ray.rd);
        float c = dot(oc, oc) - sphere.w * sphere.w;
        float disc = b * b - c;

        if (disc < 0.0) {
            return makeMiss();
        }

        float t = -b - sqrt(disc);
        if (t <= 0.0) {
            return makeMiss();
        }

        Hit hit;
        hit.t = t;
        hit.normal = normalize((ray.ro + t * ray.rd) - sphere.xyz);
        hit.kind = HIT_TARGET;
        return hit;
    }

    Hit traceTargets(Ray ray) {
        Hit closest = makeMiss();
%s
        return closest;
    }

    Hit traceScene(Ray ray) {
        Hit closest = intersectBackdrop(ray, u_backdropZ, u_backdropBounds);
        Hit targetHit = traceTargets(ray);

        if (targetHit.kind != HIT_NONE && targetHit.t < closest.t) {
            closest = targetHit;
        }

        return closest;
    }
]]

local shader_environment = [[
    float2 dirToEquirectUV(float3 d) {
        d = normalize(d);
        float phi = atan2(d.z, d.x);
        float theta = acos(clamp(d.y, -1.0, 1.0));
        return float2(phi / TWO_PI + 0.5, theta / PI);
    }

    float3 sampleEnvironment(float3 rd) {
        float2 uv = dirToEquirectUV(rd);
        return txHDRI.Sample(samLinear, uv).rgb;
    }

    float3 sampleIrradiance(float3 n) {
        float x = n.x;
        float y = n.y;
        float z = n.z;

        float3 E =
            u_sh0.rgb * 0.282095 +
            u_sh1.rgb * (0.488603 * z) +
            u_sh2.rgb * (0.488603 * y) +
            u_sh3.rgb * (0.488603 * x) +
            u_sh4.rgb * (1.092548 * x * z) +
            u_sh5.rgb * (1.092548 * z * y) +
            u_sh6.rgb * (0.315392 * (3.0 * y * y - 1.0)) +
            u_sh7.rgb * (1.092548 * x * y) +
            u_sh8.rgb * (0.546274 * (x * x - z * z));

        return max(E, 0.0);
    }
]]

local shader_integrators = [[
    float3 integrateUnlit(Ray ray) {
        Hit hit = traceTargets(ray);
        if (hit.kind == HIT_NONE) {
            return u_clearColor.rgb;
        }
        return u_targetColor.rgb;
    }

    float3 integrateLit(Ray ray) {
        Hit hit = traceScene(ray);
        if (hit.kind == HIT_NONE) {
            return sampleEnvironment(ray.rd);
        }
        float3 albedo;
        float3 emission = 0.0;
        if (hit.kind == HIT_TARGET) {
            albedo = u_targetColor.rgb;
            emission = u_targetColor.rgb * u_targetEmission;
        } else {
            albedo = u_environmentColor.rgb;
        }
        float3 irradiance = sampleIrradiance(hit.normal);
        return albedo * (irradiance / PI) + emission;
    }
]]

local shader_entry = [[
    float3 tonemapReinhard(float3 col) {
        //anything above this value is clipped
        const float whitePoint = 3.0;
        return (col * (1.0 + col / (whitePoint * whitePoint))) / (1.0 + col);
    }

    float4 main(PS_IN pin) {
        float3 ddxPos = ddx(pin.PosC);
        float3 ddyPos = ddy(pin.PosC);

        %s
        %s

        return float4(col, 1.0);
    }
]]

local SSAA_OFFSETS = {
    [1] = { { 0.0, 0.0 } },
    [2] = { { -0.25, -0.25 }, { 0.25, 0.25 } },
    [4] = { { -0.25, -0.25 }, { 0.25, -0.25 }, { -0.25, 0.25 }, { 0.25, 0.25 } },
    [8] = {
        { -0.375, -0.125 }, { -0.125, 0.375 }, { 0.125, -0.375 }, { 0.375, 0.125 },
        { -0.375, 0.375 }, { -0.125, -0.375 }, { 0.125, 0.125 }, { 0.375, -0.125 },
    },
}

local function makeSampling(integrator, samples)
    local offsets = SSAA_OFFSETS[samples]
    if not offsets then
        error('unsupported SSAA sample count: ' .. tostring(samples))
    end

    local rays = {}
    for i = 1, #offsets do
        local o = offsets[i]
        rays[#rays + 1] = string.format([[
            {
                Ray ray;
                ray.ro = u_cameraPosition.xyz;
                ray.rd = normalize(pin.PosC + ddxPos * %.6f + ddyPos * %.6f);
                col += %s(ray);
            }
        ]], o[1], o[2], integrator)
    end

    return string.format([[
        float3 col = 0.0;

        %s

        col *= %.9f;
    ]], table.concat(rays, '\n'), 1.0 / samples)
end

local function makeShader(capacity)
    local integrator
    local postProcess

    if presentation == "COMPETITIVE" then
        integrator = "integrateUnlit"
        postProcess = ""
    elseif presentation == "SCENIC" then
        integrator = "integrateLit"
        postProcess = [[
            col = tonemapReinhard(col);
            col = pow(saturate(col), 1.0 / 2.2);
        ]]
    else
        error('unknown renderer presentation: ' .. tostring(presentation))
    end

    local checks = {}
    for i = 0, capacity - 1 do
        checks[#checks + 1] = string.format([[
        if (u_targetCount > %d) {
            Hit h = intersectSphere(ray, u_target%d);
            if (h.kind != HIT_NONE && h.t < closest.t) {
                closest = h;
            }
        }]], i, i)
    end

    local formattedGeometry = string.format(shader_geom, table.concat(checks, "\n"))
    local sampling = makeSampling(integrator, ssaa)
    local formattedEntry = string.format(shader_entry, sampling, postProcess)

    return table.concat({
        shader_core,
        formattedGeometry,
        shader_environment,
        shader_integrators,
        formattedEntry
    }, "\n")
end

local function rebuild()
    if targetCapacity < 0 then
        return
    end

    local values = {
        u_cameraPosition = vec4(),
        u_backdropZ = 0.0,
        u_backdropBounds = vec4(),
        u_targetCount = 0,
        u_clearColor = rgbm(),
        u_environmentColor = rgbm(),
        u_targetColor = rgbm(),
        u_targetEmission = 0.0,
    }

    for i = 0, 8 do
        values["u_sh" .. i] = vec4()
    end

    for i = 0, targetCapacity - 1 do
        values["u_target" .. i] = vec4()
    end

    renderParams = {
        blendMode = render.BlendMode.OpaqueForced,
        depthMode = render.DepthMode.Off,
        textures = {
            txHDRI = activeEnvironment.texture,
        },
        values = values,
        shader = makeShader(targetCapacity),
    }

    activeEnvironment.dirty = true
end

---@param capacity number
function renderer.setTargetCapacity(capacity)
    if targetCapacity == capacity then
        return
    end

    targetCapacity = capacity
    rebuild()
end

---renders scene using given geometry and camera
---@param world table
---@param camera table
function renderer.draw(world, camera)
    if presentation ~= settings.graphics_presentation
        or ssaa ~= settings.graphics_ssaa
        or (activeEnvironment and activeEnvironment.name ~= settings.graphics_hdri) then
        presentation = settings.graphics_presentation
        ssaa = settings.graphics_ssaa
        activeEnvironment = hdri.load(settings.graphics_hdri)
        rebuild()
    end

    local count = #world.targets
    assert(count <= targetCapacity, 'target count exceeds renderer capacity')

    renderParams.values.u_cameraPosition:set(camera.position.x, camera.position.y, camera.position.z, 0.0)
    renderParams.values.u_backdropZ = world.environment.backdrop.z
    renderParams.values.u_backdropBounds:set(world.environment.backdrop.bounds)
    renderParams.values.u_targetCount = count

    for i = 1, count do
        local target = world.targets[i]
        renderParams.values["u_target" .. (i - 1)]:set(
            target.position.x,
            target.position.y,
            target.position.z,
            target.radius
        )
    end

    renderParams.values.u_clearColor = settings.graphics_clear_color
    renderParams.values.u_environmentColor = settings.graphics_backdrop_color
    renderParams.values.u_targetColor = settings.graphics_target_color
    renderParams.values.u_targetEmission = settings.graphics_target_emission

    if activeEnvironment.dirty then
        for i = 1, 9 do
            local c = activeEnvironment.sh[i]
            renderParams.values["u_sh" .. (i - 1)]:set(c.r, c.g, c.b, 0.0)
        end
        activeEnvironment.dirty = false
    end

    render.fullscreenPass(renderParams)
end

return renderer
