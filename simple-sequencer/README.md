# Haxe > OpenFL > FeathersUI > WebAudio :: Simple Sequencer

_Example Credit_:
  * https://github.com/mdn/webaudio-examples/tree/master/simple-sequencer

## Live demo

A build of the [_simple-sequencer_ sample](https://teotigraphix.com/io/web-audio/simple-sequencer) is hosted on the TeotiGraphix, LLC website, and it may be viewed in any modern web browser.

![Simple Sequencer](https://github.com/teotigraphix/haxe-feathersui-webaudio/blob/main/audiobuffer-noise/docs/screenshots/webaudio-simple-sequencer.png)
  
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

  * Creates a simple sequence using wav files.
  * Play/Stop the sequencer.
  * Set BPM of the sequencer.
  * Sequence the sequencer triggers.
  
