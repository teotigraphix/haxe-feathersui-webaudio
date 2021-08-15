package;

////////////////////////////////////////////////////////////////////////////////
// Copyright 2021 Michael Schmalle - Teoti Graphix, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License
//
// Author: Michael Schmalle - https://teotigraphix.com
// teotigraphixllc at gmail dot com
////////////////////////////////////////////////////////////////////////////////
import feathers.skins.RectangleSkin;
import feathers.controls.Application;
import feathers.controls.Button;
import feathers.controls.LayoutGroup;
import feathers.events.TriggerEvent;
import feathers.layout.VerticalLayout;
import js.Browser;
import js.html.AudioElement;
import js.html.MediaElement;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import js.html.audio.MediaElementAudioSourceNode;
import js.lib.Uint8Array;
import openfl.events.Event;
import openfl.events.MouseEvent;

// TODO Need a simple dynamic loop so BG animates from 0..1 alpha
// TODO Play control stop, stops and resets audio
class Main extends Application {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _soundEngine:SoundEngine;

	private var playControl:Button;
	private var canavs:LayoutGroup;
	private var background:RectangleSkin;
	private var poweredBy:PoweredByFeathersUI;

	//-----------------------------------------------------------------------------
	// Constructor
	//-----------------------------------------------------------------------------

	/**
		Creates the application!
	 */
	public function new() {
		super();

		Browser.console.clear();

		trace("Main.new()");

		stage.addEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDownHandler, true);

		_soundEngine = new SoundEngine(soundEngine_soundComplete);
	}

	//-----------------------------------------------------------------------------
	// Overridden :: Methods
	//-----------------------------------------------------------------------------

	override function initialize() {
		super.initialize();

		var vl = new VerticalLayout();
		vl.horizontalAlign = CENTER;
		vl.setPadding(32.0);
		layout = vl;

		background = new RectangleSkin();
		background.fill = SolidColor(0xFFCC00);
		background.alpha = 0.0;

		backgroundSkin = background;

		canavs = new LayoutGroup();
		canavs.includeInLayout = false;

		playControl = new Button();
		playControl.text = "PLAY MP3";
		playControl.addEventListener(TriggerEvent.TRIGGER, playControl_changeHandler);

		poweredBy = new PoweredByFeathersUI();
		poweredBy.includeInLayout = false;

		addChild(canavs);
		addChild(playControl);
		addChild(poweredBy);
	}

	override function update() {
		super.update();

		var sizeInvalid = isInvalid(SIZE);

		if (sizeInvalid) {
			var poweredByX:Float = actualWidth - poweredBy.width - 32.0;
			var poweredByY:Float = actualHeight - poweredBy.height - 32.0;

			poweredBy.move(poweredByX, poweredByY);

			canavs.move(0.0, 0.0);
			canavs.setSize(actualWidth, actualHeight);
		}
	}

	//-----------------------------------------------------------------------------
	// Private :: MMethods
	//-----------------------------------------------------------------------------
	private var dataArray:Uint8Array;

	private function drawWaveform():Void {
		var g = canavs.graphics;
		g.clear();

		if (playControl.enabled)
			return;

		var bufferLength = _soundEngine.analyser.frequencyBinCount;
		dataArray = new Uint8Array(bufferLength);

		_soundEngine.analyser.getByteTimeDomainData(dataArray);

		g.lineStyle(16.0, 0x00FF00);

		var x = 0.0;
		var heightScale = 1.0;
		var signalSum = 0.0;
		var contentHeight = actualHeight * heightScale;

		var sliceWidth = actualWidth / bufferLength;

		for (i in 0...bufferLength) {
			var value = dataArray[i] / 128;
			signalSum += value;

			var y = (value * contentHeight / 2.0);

			if (i == 0) {
				g.moveTo(x, y);
			} else {
				g.lineTo(x, y);
			}

			x += sliceWidth;
		}

		background.alpha = (signalSum / bufferLength) * 0.5;

		g.lineTo(actualWidth, actualHeight / 2.0);
	}

	//-----------------------------------------------------------------------------
	// Private :: Handlers
	//-----------------------------------------------------------------------------

	private function stage_mouseDownHandler(event:MouseEvent):Void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDownHandler, true);
		_soundEngine.userInitialize();
	}

	private function main_enterFrameHandler(event:Event):Void {
		drawWaveform();
	}

	private function playControl_changeHandler(event:Event):Void {
		_soundEngine.play();
		playControl.enabled = false;
		playControl.text = "PLAYING MP3";
		addEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
	}

	private function soundEngine_soundComplete():Void {
		playControl.enabled = true;
		playControl.text = "PLAY MP3";
		removeEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
		canavs.graphics.clear();
	}
}

class SoundEngine {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _audioContext:AudioContext;

	//
	public var analyser(default, default):AnalyserNode;

	//
	private var _channels:Int = 2;

	private var _soundComplete:() -> Void;

	//-----------------------------------------------------------------------------
	// Constructor
	//-----------------------------------------------------------------------------

	/** */
	public function new(soundComplete:() -> Void) {
		_soundComplete = soundComplete;
	}

	//-----------------------------------------------------------------------------
	// API :: Methods
	//-----------------------------------------------------------------------------

	/** */
	public function userInitialize():Void {
		trace("SoundEngine.userInitialize()");
		_audioContext = new AudioContext();
		_audioElement = createAudioElement(_soundFile);
	}

	private var _soundFile:String = "assets/audio/audio-basics_outfoxing.mp3";
	// The HTMLAudioElement interface provides access to the properties of audio elements, as
	// well as methods to manipulate them. It derives from the HTMLMediaElement interface.
	private var _audioElement:AudioElement;
	// The GainNode interface represents a change in volume.
	private var _gainNode:GainNode;
	// The mp3 audio source
	private var _mediaAudioSource:MediaElementAudioSourceNode;

	/** */
	public function play():Void {
		// The analyzer node gives time domain data for the waveform render
		analyser = _audioContext.createAnalyser();
		analyser.fftSize = 1024;
		// The media audio source loads, you guessed it, mp3 as well
		_mediaAudioSource = _audioContext.createMediaElementSource(cast(_audioElement, MediaElement));
		// A master volume
		_gainNode = _audioContext.createGain();

		// mp3 samples to volume
		_mediaAudioSource.connect(_gainNode);
		// volume to analyser
		_gainNode.connect(analyser);
		// analyser to out
		analyser.connect(_audioContext.destination);

		// Play the mp3 samples
		_audioElement.play();

		// When the mp3 is finished, the soundComplete() callback is fired
		_audioElement.onended = () -> {
			Browser.console.log('MP3 finished');
			if (_soundComplete != null) {
				_soundComplete();
			}
		}
	}

	//-----------------------------------------------------------------------------
	// Private :: Methods
	//-----------------------------------------------------------------------------

	private function createAudioElement(soundFile:String):AudioElement {
		var element = Browser.document.createAudioElement();
		element.setAttribute("src", soundFile);
		element.setAttribute("crossorigin", "anonymous");
		return element;
	}
}
