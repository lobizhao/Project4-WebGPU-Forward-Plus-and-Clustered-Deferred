@group(0) @binding(0) var inputTexture: texture_2d<f32>;
@group(0) @binding(1) var<uniform> bloomThreshold: f32;

struct FragmentInput {
    @builtin(position) fragCoord: vec4f,
    @location(0) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f {
    let color = textureLoad(inputTexture, vec2i(floor(in.fragCoord.xy)), 0).rgb;
    let brightness = dot(color, vec3f(0.2126, 0.7152, 0.0722));
    
    if (brightness > bloomThreshold) {
        //slider value control
        return vec4f(color * max(brightness - bloomThreshold, 0.0) * 2.0, 1.0);
    }
    return vec4f(0.0, 0.0, 0.0, 1.0);
}
