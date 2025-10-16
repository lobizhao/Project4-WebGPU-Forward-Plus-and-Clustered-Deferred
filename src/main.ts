import Stats from 'stats.js';
import { GUI } from 'dat.gui';

import { initWebGPU, Renderer } from './renderer';
import { NaiveRenderer } from './renderers/naive';
import { ForwardPlusRenderer } from './renderers/forward_plus';
import { ClusteredDeferredRenderer } from './renderers/clustered_deferred';

import { setupLoaders, Scene } from './stage/scene';
import { Lights } from './stage/lights';
import { Camera } from './stage/camera';
import { Stage } from './stage/stage';

await initWebGPU();
setupLoaders();

let scene = new Scene();
await scene.loadGltf('./scenes/sponza/Sponza.gltf');

const camera = new Camera();
const lights = new Lights(camera);

const stats = new Stats();
stats.showPanel(0);
document.body.appendChild(stats.dom);

const gui = new GUI();
gui.add(lights, 'numLights').min(1).max(Lights.maxNumLights).step(1).onChange(() => {
    lights.updateLightSetUniformNumLights();
});

const stage = new Stage(scene, lights, camera, stats);

var renderer: Renderer | undefined;

function setRenderer(mode: string) {
    renderer?.stop();

    switch (mode) {
        case renderModes.naive:
            renderer = new NaiveRenderer(stage);
            break;
        case renderModes.forwardPlus:
            renderer = new ForwardPlusRenderer(stage);
            break;
        case renderModes.clusteredDeferred:
            renderer = new ClusteredDeferredRenderer(stage);
            break;
    }
    
    if (renderer) {
        renderer.setBloomEnabled(bloomSettings.enabled);
        if ('setBloomThreshold' in renderer) {
            (renderer as any).setBloomThreshold(bloomSettings.threshold);
        }
    }
}

const renderModes = { naive: 'naive', forwardPlus: 'forward+', clusteredDeferred: 'clustered deferred' };
let renderModeController = gui.add({ mode: renderModes.naive }, 'mode', renderModes);
renderModeController.onChange(setRenderer);
//Bloom set Gui part
const bloomSettings = { enabled: false, threshold: 0.3 };
gui.add(bloomSettings, 'enabled').name('Bloom').onChange((value: boolean) => {
    if (renderer) {
        renderer.setBloomEnabled(value);
    }
});
gui.add(bloomSettings, 'threshold').min(0.0).max(1.0).step(0.05).name('Bloom Threshold').onChange((value: number) => {
    if (renderer && 'setBloomThreshold' in renderer) {
        //set threshold value
        (renderer as any).setBloomThreshold(value);
    }
});
setRenderer(renderModeController.getValue());
