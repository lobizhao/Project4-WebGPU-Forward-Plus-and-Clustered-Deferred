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
    
    // Calculate cluster bounds in screen space
    let screenWidth = 800.0;
    let screenHeight = 600.0;
    let tileWidth = screenWidth / f32(tileCountX);
    let tileHeight = screenHeight / f32(tileCountY);
    
    let minX = f32(global_id.x) * tileWidth;
    let maxX = minX + tileWidth;
    let minY = f32(global_id.y) * tileHeight;
    let maxY = minY + tileHeight;
    
    //only add lights that might affect this tile

    //This is a simplified version test
    var count = 0u;
    
    for (var i = 0u; i < lightSet.numLights && count < ${maxLightsPerCluster}u; i++) {
        let light = lightSet.lights[i];
        
        // Transform light to clip space
        let lightClip = camera.viewProjMat * vec4f(light.pos, 1.0);
        let lightNDC = lightClip.xyz / lightClip.w;
        
        let lightScreenX = (lightNDC.x * 0.5 + 0.5) * screenWidth;
        let lightScreenY = (1.0 - (lightNDC.y * 0.5 + 0.5)) * screenHeight;
        
        //may large than 600  dark block display
        let lightRadius = 800.0;
        
        // Also check if light is behind camera
        let inFrontOfCamera = lightClip.w > 0.0;
        
        if (inFrontOfCamera &&
            lightScreenX + lightRadius >= minX && lightScreenX - lightRadius <= maxX &&
            lightScreenY + lightRadius >= minY && lightScreenY - lightRadius <= maxY) {
            clusterLights[tileIndex].indices[count] = i;
            count++;
        }
    }
    
    clusterLights[tileIndex].count = count;
}
