import * as renderer from '../renderer';
import * as shaders from '../shaders/shaders';
import { Stage } from '../stage/stage';

export class ClusteredDeferredRenderer extends renderer.Renderer {
    // TODO-3: add layouts, pipelines, textures, etc. needed for Forward+ here
    // you may need extra uniforms such as the camera view matrix and the canvas resolution
    sceneUniformsBindGroupLayout: GPUBindGroupLayout;
    sceneUniformsBindGroup: GPUBindGroup;

    gBufferPositionTexture: GPUTexture;
    gBufferNormalTexture: GPUTexture;
    gBufferAlbedoTexture: GPUTexture;
    depthTexture: GPUTexture;

    gBufferPipeline: GPURenderPipeline;
    fullscreenPipeline: GPURenderPipeline;

    fullscreenBindGroupLayout: GPUBindGroupLayout;
    fullscreenBindGroup: GPUBindGroup;

    constructor(stage: Stage) {
        super(stage);
        // TODO-3: initialize layouts, pipelines, textures, etc. needed for Forward+ here
        // you'll need two pipelines: one for the G-buffer pass and one for the fullscreen pass
        const textureDesc: GPUTextureDescriptor = {
            size: [renderer.canvas.width, renderer.canvas.height],
            format: 'rgba16float',
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING
        };

        this.gBufferPositionTexture = renderer.device.createTexture(textureDesc);
        this.gBufferNormalTexture = renderer.device.createTexture(textureDesc);
        this.gBufferAlbedoTexture = renderer.device.createTexture(textureDesc);

        this.depthTexture = renderer.device.createTexture({
            size: [renderer.canvas.width, renderer.canvas.height],
            format: 'depth24plus',
            usage: GPUTextureUsage.RENDER_ATTACHMENT
        });

        this.sceneUniformsBindGroupLayout = renderer.device.createBindGroupLayout({
            entries: [
                { binding: 0, visibility: GPUShaderStage.VERTEX, buffer: { type: 'uniform' } }
            ]
        });

        this.sceneUniformsBindGroup = renderer.device.createBindGroup({
            layout: this.sceneUniformsBindGroupLayout,
            entries: [
                { binding: 0, resource: { buffer: this.camera.uniformsBuffer } }
            ]
        });

        this.gBufferPipeline = renderer.device.createRenderPipeline({
            layout: renderer.device.createPipelineLayout({
                bindGroupLayouts: [
                    this.sceneUniformsBindGroupLayout,
                    renderer.modelBindGroupLayout,
                    renderer.materialBindGroupLayout
                ]
            }),
            depthStencil: {
                depthWriteEnabled: true,
                depthCompare: 'less',
                format: 'depth24plus'
            },
            vertex: {
                module: renderer.device.createShaderModule({
                    code: shaders.naiveVertSrc
                }),
                buffers: [renderer.vertexBufferLayout]
            },
            fragment: {
                module: renderer.device.createShaderModule({
                    code: shaders.clusteredDeferredFragSrc
                }),
                targets: [
                    { format: 'rgba16float' },
                    { format: 'rgba16float' },
                    { format: 'rgba16float' }
                ]
            }
        });

        this.fullscreenBindGroupLayout = renderer.device.createBindGroupLayout({
            entries: [
                { binding: 0, visibility: GPUShaderStage.FRAGMENT, texture: {} },
                { binding: 1, visibility: GPUShaderStage.FRAGMENT, texture: {} },
                { binding: 2, visibility: GPUShaderStage.FRAGMENT, texture: {} },
                { binding: 3, visibility: GPUShaderStage.FRAGMENT, buffer: { type: 'read-only-storage' } },
                { binding: 4, visibility: GPUShaderStage.FRAGMENT, buffer: { type: 'read-only-storage' } }
            ]
        });

        this.fullscreenBindGroup = renderer.device.createBindGroup({
            layout: this.fullscreenBindGroupLayout,
            entries: [
                { binding: 0, resource: this.gBufferPositionTexture.createView() },
                { binding: 1, resource: this.gBufferNormalTexture.createView() },
                { binding: 2, resource: this.gBufferAlbedoTexture.createView() },
                { binding: 3, resource: { buffer: this.lights.lightSetStorageBuffer } },
                { binding: 4, resource: { buffer: this.lights.clusterLightsBuffer } }
            ]
        });

        this.fullscreenPipeline = renderer.device.createRenderPipeline({
            layout: renderer.device.createPipelineLayout({
                bindGroupLayouts: [this.fullscreenBindGroupLayout]
            }),
            vertex: {
                module: renderer.device.createShaderModule({
                    code: shaders.clusteredDeferredFullscreenVertSrc
                })
            },
            fragment: {
                module: renderer.device.createShaderModule({
                    code: shaders.clusteredDeferredFullscreenFragSrc
                }),
                targets: [{ format: renderer.canvasFormat }]
            }
        });
    }

    override draw() {
        // TODO-3: run the Forward+ rendering pass:
        // - run the clustering compute shader
        // - run the G-buffer pass, outputting position, albedo, and normals
        // - run the fullscreen pass, which reads from the G-buffer and performs lighting calculations
        const encoder = renderer.device.createCommandEncoder();
        
        this.lights.doLightClustering(encoder);

        const gBufferPass = encoder.beginRenderPass({
            colorAttachments: [
                {
                    view: this.gBufferPositionTexture.createView(),
                    clearValue: [0, 0, 0, 0],
                    loadOp: 'clear',
                    storeOp: 'store'
                },
                {
                    view: this.gBufferNormalTexture.createView(),
                    clearValue: [0, 0, 0, 0],
                    loadOp: 'clear',
                    storeOp: 'store'
                },
                {
                    view: this.gBufferAlbedoTexture.createView(),
                    clearValue: [0, 0, 0, 0],
                    loadOp: 'clear',
                    storeOp: 'store'
                }
            ],
            depthStencilAttachment: {
                view: this.depthTexture.createView(),
                depthClearValue: 1.0,
                depthLoadOp: 'clear',
                depthStoreOp: 'store'
            }
        });

        gBufferPass.setPipeline(this.gBufferPipeline);
        gBufferPass.setBindGroup(shaders.constants.bindGroup_scene, this.sceneUniformsBindGroup);

        this.scene.iterate(node => {
            gBufferPass.setBindGroup(shaders.constants.bindGroup_model, node.modelBindGroup);
        }, material => {
            gBufferPass.setBindGroup(shaders.constants.bindGroup_material, material.materialBindGroup);
        }, primitive => {
            gBufferPass.setVertexBuffer(0, primitive.vertexBuffer);
            gBufferPass.setIndexBuffer(primitive.indexBuffer, 'uint32');
            gBufferPass.drawIndexed(primitive.numIndices);
        });

        gBufferPass.end();

        const canvasTextureView = renderer.context.getCurrentTexture().createView();
        const fullscreenPass = encoder.beginRenderPass({
            colorAttachments: [
                {
                    view: canvasTextureView,
                    clearValue: [0, 0, 0, 0],
                    loadOp: 'clear',
                    storeOp: 'store'
                }
            ]
        });

        fullscreenPass.setPipeline(this.fullscreenPipeline);
        fullscreenPass.setBindGroup(shaders.constants.bindGroup_scene, this.fullscreenBindGroup);
        fullscreenPass.draw(6);

        fullscreenPass.end();

        renderer.device.queue.submit([encoder.finish()]);
    }
}
