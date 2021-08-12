# Haxe > OpenFL > FeathersUI > WebAudio :: Audio Analyser

_Example Credit_:
  * https://mdn.github.io/webaudio-examples/audiobuffer-noise/

## Live demo

A build of the [_audiobuffer-noise_ sample](https://teotigraphix.com/io/web-audio/audiobuffer-noise) is hosted on the TeotiGraphix, LLC website, and it may be viewed in any modern web browser.

![AudioBuffer Noise](https://github.com/teotigraphix/haxe-feathersui-webaudio/blob/main/docs/screenshots/webaudio-audiobuffer-noise.png)
  
## Run locally

This project includes an project.xml file that configures all options for OpenFL. This file makes it easy to build from the command line, and many IDEs can parse this file to configure a Haxe project to use OpenFL.

## Prerequisites

- [Install Haxe 4.0.0 or newer](https://haxe.org/download/).
- [Install Feathers UI from Haxelib](https://feathersui.com/learn/haxe-openfl/installation/)

### Command Line

Run the [**openfl**](https://www.openfl.org/learn/haxelib/docs/tools/) tool in your terminal:

```sh
haxelib run openfl test html5
```

WebAudio means `html5` target only.

### Editors and IDEs

Check out the following tutorials for creating Feathers UI projects in popular development environments:

- [HaxeDevelop](https://feathersui.com/learn/haxe-openfl/haxedevelop/)
- [Moonshine IDE](https://feathersui.com/learn/haxe-openfl/moonshine-ide/)
- [Visual Studio Code](https://feathersui.com/learn/haxe-openfl/visual-studio-code/)


The sample app demonstrates the following;

  * Uses the AudioBuffer and AnalyserNode to draw a waveform of random sample noise.
