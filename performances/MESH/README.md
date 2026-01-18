# Simple Visual Synth

> This patch has been used for the MESH festival 2024 performance

Simple Processing sketch that converts image into FFT information to filter white noise.

On the processing side images are analyzed pixel by pixel applying an edge detection filter super imposed to a brightness threshold filter.

The pixel information is than sent to Supercollider via `OSC` and used as FFT filter over white noise.

## Setup

1. Get SuperCollider [here](https://supercollider.github.io/)
2. In SuperCollider install all [quarks, extensions](https://github.com/supercollider-quarks/quarks) and [plugins](https://supercollider.github.io/sc3-plugins/) specially the PV library for FFT analysis
3. Get Processing [here](https://processing.org/download)
4. In Processing install additional libraries: video, sound, openCV, and oscP5

## How to

1. run the processing sketch `processing/processing_visual_spectrum_video/processing_visual_spectrum_video.pde`
2. At the moment the processing sketch is set to recognize the `SandbergCapture` HDMI to usb-c virtual camera. You can change this in `line 70`, to the virtual or not camera that you need to use.
3. If no error messages appear it might already output a BW video stream
4. Run the supercollider patch `supercollider/visual-synth/visual-synth-fft-to-LIVE.scd`