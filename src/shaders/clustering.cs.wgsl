@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterLights: array<ClusterLights>;

const tileCountX = ${tileCountX}u;
const tileCountY = ${tileCountY}u;
const tileCountZ = ${tileCountZ}u;

@compute @workgroup_size(4, 2, 4)
fn main(@builtin(global_invocation_id) global_id: vec3u) {
    if (global_id.x >= tileCountX || global_id.y >= tileCountY || global_id.z >= tileCountZ) {
        return;
    }

    let tileIndex = global_id.x + global_id.y * tileCountX + global_id.z * tileCountX * tileCountY;
    
    var count = 0u;
    
    for (var i = 0u; i < lightSet.numLights && count < ${maxLightsPerCluster}u; i++) {
        let light = lightSet.lights[i];
        let lightClip = camera.viewProjMat * vec4f(light.pos, 1.0);
        if (lightClip.w <= 0.0) {
            continue;
        }
        
        let lightNDC = lightClip.xyz / lightClip.w;
        let lightScreenX = (lightNDC.x * 0.5 + 0.5);
        let lightScreenY = (1.0 - (lightNDC.y * 0.5 + 0.5));
        
        let tileMinX = f32(global_id.x) / f32(tileCountX);
        let tileMaxX = f32(global_id.x + 1u) / f32(tileCountX);
        let tileMinY = f32(global_id.y) / f32(tileCountY);
        let tileMaxY = f32(global_id.y + 1u) / f32(tileCountY);
        
        let screenRadiusNDC = 0.5;
        
        if (lightScreenX + screenRadiusNDC >= tileMinX && lightScreenX - screenRadiusNDC <= tileMaxX &&
            lightScreenY + screenRadiusNDC >= tileMinY && lightScreenY - screenRadiusNDC <= tileMaxY) {
            clusterLights[tileIndex].indices[count] = i;
            count++;
        }
    }
    clusterLights[tileIndex].count = count;
}
