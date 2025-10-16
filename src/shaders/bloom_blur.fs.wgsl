@group(0) @binding(0) var inputTexture: texture_2d<f32>;

struct FragmentInput {
    @builtin(position) fragCoord: vec4f,
    @location(0) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f {
    let pixelCoord = vec2i(floor(in.fragCoord.xy));
    var color = vec3f(0.0);
    
    let radius = 5;
    var count = 0.0;
    
    for (var x = -radius; x <= radius; x++) {
        for (var y = -radius; y <= radius; y++) {
            color += textureLoad(inputTexture, pixelCoord + vec2i(x, y), 0).rgb;
            count += 1.0;
        }
    }
    
    return vec4f(color / count, 1.0);
}
