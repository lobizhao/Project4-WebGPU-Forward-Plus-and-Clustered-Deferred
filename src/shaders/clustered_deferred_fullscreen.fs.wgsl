// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.
@group(${bindGroup_scene}) @binding(0) var gBufferPosition: texture_2d<f32>;
@group(${bindGroup_scene}) @binding(1) var gBufferNormal: texture_2d<f32>;
@group(${bindGroup_scene}) @binding(2) var gBufferAlbedo: texture_2d<f32>;
@group(${bindGroup_scene}) @binding(3) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(4) var<storage, read> clusterLights: array<ClusterLights>;

struct FragmentInput {
    @builtin(position) fragCoord: vec4f,
    @location(0) uv: vec2f
}

fn getClusterIndex(fragCoord: vec4f, screenSize: vec2f) -> u32 {
    let tileX = u32((fragCoord.x / screenSize.x) * f32(${tileCountX}));
    let tileY = u32((fragCoord.y / screenSize.y) * f32(${tileCountY}));
    let tileZ = 0u;
    
    return min(tileX + tileY * ${tileCountX}u + tileZ * ${tileCountX}u * ${tileCountY}u, 
               ${tileCountX}u * ${tileCountY}u * ${tileCountZ}u - 1u);
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f {
    let pixelCoord = vec2i(floor(in.fragCoord.xy));
    
    let position = textureLoad(gBufferPosition, pixelCoord, 0).xyz;
    let normal = textureLoad(gBufferNormal, pixelCoord, 0).xyz;
    let albedo = textureLoad(gBufferAlbedo, pixelCoord, 0);

    if (albedo.a < 0.5f) {
        discard;
    }

    let screenSize = vec2f(textureDimensions(gBufferAlbedo));
    let clusterIndex = getClusterIndex(in.fragCoord, screenSize);
    let lightCount = clusterLights[clusterIndex].count;

    var totalLightContrib = vec3f(0, 0, 0);
    
    for (var i = 0u; i < lightCount; i++) {
        let lightIdx = clusterLights[clusterIndex].indices[i];
        let light = lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(light, position, normalize(normal));
    }

    var finalColor = albedo.rgb * totalLightContrib;
    return vec4f(finalColor, 1.0);
}
