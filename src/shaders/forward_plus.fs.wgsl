@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterLights: array<ClusterLights>;
@group(${bindGroup_scene}) @binding(3) var screenSizeTexture: texture_2d<f32>;

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @builtin(position) fragCoord: vec4f,
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

fn getClusterIndex(fragCoord: vec4f, screenSize: vec2f) -> u32 {
    let tileX = min(u32(fragCoord.x / screenSize.x * f32(${tileCountX})), ${tileCountX}u - 1u);
    let tileY = min(u32(fragCoord.y / screenSize.y * f32(${tileCountY})), ${tileCountY}u - 1u);
    let tileZ = 0u;
    //fix edge
    return tileX + tileY * ${tileCountX}u + tileZ * ${tileCountX}u * ${tileCountY}u;
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }

    let screenSize = vec2f(textureDimensions(screenSizeTexture));
    let clusterIndex = getClusterIndex(in.fragCoord, screenSize);
    let lightCount = clusterLights[clusterIndex].count;

    var totalLightContrib = vec3f(0, 0, 0);
    
    for (var i = 0u; i < lightCount; i++) {
        let lightIdx = clusterLights[clusterIndex].indices[i];
        let light = lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
    }

    var finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
