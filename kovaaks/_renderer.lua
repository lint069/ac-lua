local renderer = {
    MODE = {
        UNLIT = 'UNLIT',
        LIT = 'LIT'
    },
    mode = 'LIT',

    environmentColor = rgbm(0.1, 0.1, 0.1, 1),
    skyColor = rgbm(0.02, 0.05, 0.12, 1),

    targetColor = rgbm(1.00, 0.00, 0.50, 1),
    targetEmission = 1,

    lightDirection = vec3(0, 1, 0),
    lightColor = rgbm(1.0, 1.0, 1.0, 1.0)
}

local targetCapacity = -1
local renderParams = nil

local shader_core = [[
    struct Ray {
        float3 ro;
        float3 rd;
    };

    static const int HIT_NONE = 0;
    static const int HIT_ENV = 1;
    static const int HIT_TARGET = 2;

    static const float INF = 1e9;
    static const int NO_HIT = -1;
    static const float RAY_EPSILON = 1e-3;

    struct Hit {
        float t;
        float3 normal;
        int kind;
        int id;
    };

    Hit makeMiss() {
        Hit hit;
        hit.t = INF;
        hit.normal = float3(0.0, 0.0, 0.0);
        hit.kind = HIT_NONE;
        hit.id = NO_HIT;
        return hit;
    }
]]

local shader_geom = [[
    Hit traceEnvironment(Ray ray) {
        float3 t1 = (u_boxMin.xyz - ray.ro) / ray.rd;
        float3 t2 = (u_boxMax.xyz - ray.ro) / ray.rd;
        float3 tMax = max(t1, t2);
        float t = min(tMax.x, min(tMax.y, tMax.z));

        if (t == tMax.y && ray.rd.y > 0.0) {
            return makeMiss();
        }

        Hit hit;
        hit.t = t;
        hit.normal = -sign(ray.rd) * step(tMax, float3(t, t, t));
        hit.kind = HIT_ENV;
        hit.id = NO_HIT;
        return hit;
    }

    Hit intersectSphere(Ray ray, float4 sphere, int id) {
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
        hit.id = id;
        return hit;
    }

    Hit traceTargets(Ray ray) {
        Hit closest = makeMiss();
%s
        return closest;
    }

    Hit traceScene(Ray ray) {
        Hit closest = traceEnvironment(ray);
        Hit targetHit = traceTargets(ray);

        if (targetHit.kind != HIT_NONE && targetHit.t < closest.t) {
            closest = targetHit;
        }

        return closest;
    }
]]

local shader_surface = [[
    struct Surface {
        float3 albedo;
        float3 emission;
    };

    Surface resolveSurface(Hit hit) {
        Surface s;
        s.albedo = 0.0;
        s.emission = 0.0;

        if (hit.kind == HIT_TARGET) {
            s.albedo = u_targetColor.rgb;
            s.emission = u_targetColor.rgb * u_targetEmission;
        } else if (hit.kind == HIT_ENV) {
            s.albedo = u_environmentColor.rgb;
        }

        return s;
    }
]]

local shader_environment = [[
    float3 sampleEnvironment(float3 rd) {
        return u_skyColor.rgb;
    }
]]

local shader_lighting = [[
    float directionalVisibility(float3 position, float3 normal) {
        Ray shadowRay;
        shadowRay.ro = position + normal * RAY_EPSILON;
        shadowRay.rd = normalize(u_lightDirection.xyz);

        Hit blocker = traceScene(shadowRay);
        return blocker.kind == HIT_NONE ? 1.0 : 0.0;
    }

    float3 evaluateDirectLight(float3 position, Hit hit, Surface surface) {
        float3 L = normalize(u_lightDirection.xyz);
        float ndotl = max(dot(hit.normal, L), 0.0);

        if (ndotl <= 0.0) {
            return 0.0;
        }

        float visibility = directionalVisibility(position, hit.normal);
        return surface.albedo * u_lightColor.rgb * ndotl * visibility;
    }

    float3 evaluateEnvironmentDiffuse(Hit hit, Surface surface) {
        return surface.albedo * u_skyColor.rgb;
    }
]]

local shader_integrators = [[
    float3 integrateUnlit(Ray ray) {
        Hit hit = traceScene(ray);
        if (hit.kind == HIT_NONE) {
            return sampleEnvironment(ray.rd);
        }
        Surface surface = resolveSurface(hit);
        return surface.albedo;
    }

    float3 integrateLit(Ray ray) {
        Hit hit = traceScene(ray);
        if (hit.kind == HIT_NONE) {
            return sampleEnvironment(ray.rd);
        }
        Surface surface = resolveSurface(hit);
        float3 position = ray.ro + ray.rd * hit.t;
        return surface.emission
             + evaluateEnvironmentDiffuse(hit, surface)
             + evaluateDirectLight(position, hit, surface);
    }

]]

local shader_entry = [[
    float4 main(PS_IN pin) {
        Ray ray;
        ray.ro = u_cameraPosition.xyz;
        ray.rd = normalize(pin.PosC);
        return float4(%s(ray), 1.0);
    }
]]

---@param capacity number
---@param mode string
---@return string
local function makeShader(capacity, mode)
    local integrator
    if mode == renderer.MODE.UNLIT then
        integrator = 'integrateUnlit'
    elseif mode == renderer.MODE.LIT then
        integrator = 'integrateLit'
    else
        ac.error('unknown renderer mode: ' .. tostring(mode))
    end

    local checks = {}
    for i = 0, capacity - 1 do
        checks[#checks + 1] = string.format([[
        if (u_targetCount > %d) {
            Hit h = intersectSphere(ray, u_target%d, %d);
            if (h.kind != HIT_NONE && h.t < closest.t) {
                closest = h;
            }
        }]], i, i, i)
    end

    local formattedGeometry = string.format(shader_geom, table.concat(checks, '\n'))
    local formattedEntry = string.format(shader_entry, integrator)

    return table.concat({
        shader_core,
        formattedGeometry,
        shader_surface,
        shader_environment,
        shader_lighting,
        shader_integrators,
        formattedEntry
    }, '\n')
end

---Rebuilds shader from scratch.
local function rebuild()
    if targetCapacity < 0 then
        return
    end

    local values = {
        u_cameraPosition = vec4(),
        u_boxMin = vec4(),
        u_boxMax = vec4(),
        u_targetCount = 0,
        u_lightDirection = vec4(),
        u_lightColor = rgbm(),
        u_environmentColor = rgbm(),
        u_skyColor = rgbm(),
        u_targetColor = rgbm(),
        u_targetEmission = 0.0,
    }

    for i = 0, targetCapacity - 1 do
        values['u_target' .. i] = vec4()
    end

    renderParams = {
        blendMode = render.BlendMode.OpaqueForced,
        depthMode = render.DepthMode.Off,
        values = values,
        shader = makeShader(targetCapacity, renderer.mode),
    }
end

---Sets renderer mode and recompiles if needed.
---@param mode string
function renderer.setMode(mode)
    if mode ~= renderer.MODE.UNLIT and mode ~= renderer.MODE.LIT then
        ac.error('unknown renderer mode: ' .. tostring(mode))
    end

    if renderer.mode == mode then
        return
    end

    renderer.mode = mode
    rebuild()
end

---Recompiles shader for a specific target capacity if changed.
---@param capacity number
function renderer.configure(capacity)
    if targetCapacity == capacity then
        return
    end

    targetCapacity = capacity
    rebuild()
end

---Renders scene using given geometry and camera.
---@param world table
---@param camera table
function renderer.draw(world, camera)
    if not renderParams then
        return
    end

    local count = #world.targets
    if count > targetCapacity then
        ac.debug('target overflow', count)
        count = targetCapacity
    end

    renderParams.values.u_cameraPosition:set(camera.position.x, camera.position.y, camera.position.z, 0.0)
    renderParams.values.u_boxMin:set(world.environment.boxMin)
    renderParams.values.u_boxMax:set(world.environment.boxMax)
    renderParams.values.u_targetCount = count

    for i = 1, count do
        local target = world.targets[i]
        renderParams.values['u_target' .. (i - 1)]:set(
            target.position.x,
            target.position.y,
            target.position.z,
            target.radius
        )
    end

    renderer.lightDirection:set(ac.getSkyFeatureDirection(ac.SkyFeature.Sun))
    renderParams.values.u_lightDirection:set(
        renderer.lightDirection.x,
        renderer.lightDirection.y,
        renderer.lightDirection.z,
        0.0
    )

    renderParams.values.u_lightColor = renderer.lightColor
    renderParams.values.u_environmentColor = renderer.environmentColor
    renderParams.values.u_skyColor = renderer.skyColor
    renderParams.values.u_targetColor = renderer.targetColor
    renderParams.values.u_targetEmission = renderer.targetEmission

    render.fullscreenPass(renderParams)
end

return renderer
