@group(0) @binding(0) var sceneTexture: texture_2d<f32>;
@group(0) @binding(1) var bloomTexture: texture_2d<f32>;

struct FragmentInput {
    @builtin(position) fragCoord: vec4f,
    @location(0) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f {
    let pixelCoord = vec2i(floor(in.fragCoord.xy));
    let sceneColor = textureLoad(sceneTexture, pixelCoord, 0).rgb;
    let bloomColor = textureLoad(bloomTexture, pixelCoord, 0).rgb;
    
    let finalColor = sceneColor + bloomColor * 0.8;
    return vec4f(finalColor, 1.0);
}
