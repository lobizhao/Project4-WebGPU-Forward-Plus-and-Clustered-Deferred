WebGL Forward+ and Clustered Deferred Shading
======================
[![](img/headImg.png)](https://lobizhao.github.io/Project4-WebGPU-Forward-Plus-and-Clustered-Deferred/)

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 4**

* Jiangman Zhao
* [Lobi Zhao - LinkedIn](https://www.linkedin.com/in/lobizhao/), [Lobi Zhao - personal website](https://lobizhao.github.io/).
* Tested on: **Google Chrome Version 141.0.7390.65**  on
  Windows 11 Pro, i5-10600KF @ 4.10GHz 32GB, RTX 3080 10GB

### Live Demo
- [Live Demo](https://lobizhao.github.io/Project4-WebGPU-Forward-Plus-and-Clustered-Deferred/)
### Demo Video/GIF

<div style="text-align: center;">
  <video controls width="900">
    <source src="img/headPage.mp4" type="video/mp4">
  </video>
  Demo Video
</div>

### Features
#### Naive
Baseline forward rendering with no optimizations. Tests every light against every fragment, resulting in poor performance with many lights but simple implementation.

Workflow:
- Single render pass with brute-force lighting
- Test ALL lights against EVERY fragment
- **Complexity**: O(fragments × lights)

#### Forward Plus
Optimized forward rendering using light clustering. Divides screen into tiles and assigns lights to tiles, dramatically reducing per-fragment light tests while maintaining forward rendering benefits.

Workflow:
- Compute Pass: Assign lights to screen-space tiles (16×9 grid)
- Render Pass: For each fragment, determine tile and test only relevant lights

#### Clustered Deferred
Most efficient approach combining deferred shading with light clustering. Decouples geometry processing from lighting calculations, ideal for complex scenes with high light counts and overdraw.

Workflow:
- Compute Pass: Assign lights to screen-space tiles
- Buffer Pass: Render geometry data to textures (position, normal, albedo)
- Fullscreen Pass: Read G-Buffer, determine tile, calculate lighting only for visible pixels
- Advantage: Geometry processed once, lighting calculated only for visible pixels

#### Bloom
<div align="center">
  <img src="img/BloomShowCase0.gif" alt="Memory Usage">
  <br>
  Bloom - base on Box blur
</div>
Post-processing effect that creates realistic glow around bright light sources, enhancing visual quality and realism.

Workflow:
- Extract Pass: Isolate pixels brighter than threshold
- Blur Pass: Apply 11×11 box blur to bright areas
- Composite Pass: Blend blurred bloom with original scene

Implementation Files:
- `bloom_extract.fs.wgsl` - Extracts bright pixels above threshold using luminance calculation
- `bloom_blur.fs.wgsl` - Applies 11×11 box blur kernel for smooth glow effect
- `bloom_composite.fs.wgsl` - Combines original scene with blurred bloom (80% intensity)

### Analysis

<div align="center">
  <img src="img/lightNum.png" alt="Performance vs Light Count">
  <br>
  Performance Comparison: Frame Time vs Number of Lights
</div>

<div align="center">
  <img src="img/Memory.png" alt="Memory Usage">
  <br>
  Memory Usage Comparison
</div>


### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
