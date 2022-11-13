package;

/*
	[audio-buffer-noise] Checked against FeathersUI v1.0.0

	Copyright 2022 Teoti Graphix, LLC. All Rights Reserved.
	Author: Michael Schmalle - https://teotigraphix.com

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */
import feathers.controls.Application;
import feathers.controls.Button;
import feathers.controls.LayoutGroup;
import feathers.events.TriggerEvent;
import feathers.layout.VerticalLayout;
import js.Browser;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioBufferSourceNode;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import js.lib.Float32Array;
import js.lib.Uint8Array;
import lime.utils.UInt8Array;
import openfl.events.Event;
import openfl.events.MouseEvent;

/**
	Translated with love;
	@see https://mdn.github.io/webaudio-examples/audio-buffer/
 */
class Main extends Application {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _soundEngine:SoundEngine;

	private var playControl:Button;
	private var canavs:LayoutGroup;
	private var poweredByFeathersUI:PoweredByFeathersUI;

	//-----------------------------------------------------------------------------
	// API :: Properties
	//-----------------------------------------------------------------------------
	//-----------------------------------
	// waveformHeightScale
	//-----------------------------------

	/**
		The waveform scale relative to the actualHeight.
	 */
	public var waveformHeightScale(default, default):Float = 0.9;

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

		// waveform visualizer
		canavs = new LayoutGroup();
		canavs.includeInLayout = false;

		// play that funky music white noise
		playControl = new Button();
		playControl.text = "PLAY NOISE";
		playControl.addEventListener(TriggerEvent.TRIGGER, playControl_changeHandler);

		poweredByFeathersUI = new PoweredByFeathersUI();
		poweredByFeathersUI.includeInLayout = false;

		addChild(canavs);
		addChild(playControl);
		addChild(poweredByFeathersUI);
	}

	override function update() {
		super.update();

		var sizeInvalid = isInvalid(SIZE);

		if (sizeInvalid) {
			var poweredByX:Float = actualWidth - poweredByFeathersUI.width - 32.0;
			var poweredByY:Float = actualHeight - poweredByFeathersUI.height - 32.0;

			poweredByFeathersUI.move(poweredByX, poweredByY);

			canavs.move(0, 0);
			canavs.setSize(actualWidth, actualHeight);
		}
	}

	//-----------------------------------------------------------------------------
	// Private :: Methods
	//-----------------------------------------------------------------------------

	private function drawWaveform():Void {
		var g = canavs.graphics;

		// TODO optimize/test how much drawing can happen in 1 frame
		// NOTE: This is not optimized whatsoever, there are many ways you can filter
		// waveform data to prune down for fast and accurate realtime rendering, not here,
		// this is just brute force rendering :)

		g.clear();

		var bufferLength = _soundEngine.frequencyBinCount;
		// TODO check MDN if this is a throw away instance
		var dataArray = new Uint8Array(bufferLength);

		// get the waveform time domain data to render on the canvas
		_soundEngine.getByteTimeDomainData(dataArray);

		g.lineStyle(8.0, 0x00FF00);

		var x = 0.0;
		var contentHeight = actualHeight * waveformHeightScale;
		var baseY = (actualHeight - contentHeight) / 2.0;

		var sliceWidth = actualWidth / bufferLength;

		for (i in 0...bufferLength) {
			var value = dataArray[i] / 128;
			var y = baseY + (value * contentHeight / 2.0);

			if (i == 0) {
				g.moveTo(x, y);
			} else {
				g.lineTo(x, y);
			}

			x += sliceWidth;
		}

		g.lineTo(actualWidth, actualHeight / 2.0);

		g.lineStyle(2.0, 0x0000FF, 0.65);

		var x = 0.0;
		for (i in 0...bufferLength) {
			var value = dataArray[i] / 128;
			var y = baseY + (value * contentHeight / 2.0);

			if (i == 0) {
				g.moveTo(x, y);
			} else {
				g.lineTo(x, y);
			}

			x += sliceWidth;
		}

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
		playControl.text = "PLAYING NOISE";

		addEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
	}

	private function soundEngine_soundComplete():Void {
		playControl.enabled = true;
		playControl.text = "PLAY NOISE";
		canavs.graphics.clear();

		removeEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
	}
}

class SoundEngine {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _audioContext:AudioContext;

	// The AudioBufferSourceNode interface is an AudioScheduledSourceNode which represents
	// an audio source consisting of in-memory audio data, stored in an AudioBuffer.
	private var _bufferAudioSource:AudioBufferSourceNode;

	// The GainNode interface represents a change in volume.
	private var _gainNode:GainNode;

	// The AnalyserNode interface represents a node able to provide real-time frequency
	// and time-domain analysis information.
	private var _analyser:AnalyserNode;

	// left/right
	private var channels:Int = 2;

	// complete handler for buffer completion
	private var _soundComplete:() -> Void;

	//-----------------------------------------------------------------------------
	// API :: Properties
	//-----------------------------------------------------------------------------
	//-----------------------------------
	// frequencyBinCount
	//-----------------------------------

	/**
		An `unsigned long` value half that of the FFT size. 2048 -> (`1024` values)
	 */
	public var frequencyBinCount(get, null):Int;

	private function get_frequencyBinCount():Int {
		return _analyser.frequencyBinCount;
	}

	//-----------------------------------------------------------------------------
	// Constructor
	//-----------------------------------------------------------------------------

	/**
		@param soundComplete the complete callback.
	 */
	public function new(soundComplete:() -> Void) {
		_soundComplete = soundComplete;
	}

	//-----------------------------------------------------------------------------
	// API :: Methods
	//-----------------------------------------------------------------------------

	/** 
		Call on first user gesture.
	 */
	public function userInitialize():Void {
		trace("SoundEngine.userInitialize()");

		_audioContext = new AudioContext();
	}

	/**
		Copies the current waveform, or time-domain, data into a Uint8Array 
		(unsigned byte array) passed into it.

		@param dataArray The reference array that is filled with domain data.
	 */
	public function getByteTimeDomainData(dataArray:UInt8Array):Void {
		_analyser.getByteTimeDomainData(dataArray);
	}

	/** */
	public function play():Void {
		// enough frames for 2 channels audio samples for 2 second
		//    (sample rate is samples per second eg 44100/48000/etc 44100 * 2)
		var numFrames = cast(_audioContext.sampleRate * 2.0, Int);

		// create the raw audio buffer, this will be passed to the audio source
		var audioBuffer:AudioBuffer = _audioContext.createBuffer(channels, numFrames, _audioContext.sampleRate);

		// for each channel,
		for (channel in 0...channels) {
			var channelArrayBuffer:Float32Array = audioBuffer.getChannelData(channel);
			for (frame in 0...numFrames) {
				// and each sample, grab a random value then shift between -1 and 1 for the noise sample value
				channelArrayBuffer[frame] = Math.random() * 2.0 - 1.0;
			}
		}

		// creates an audio source that uses a custom buffer for the audio samples
		_bufferAudioSource = _audioContext.createBufferSource();
		// the audio source needs the buffer of new samples(Floats) to play
		_bufferAudioSource.buffer = audioBuffer;

		// ear safety check with volume
		_gainNode = _audioContext.createGain();
		// bring the gain way down so ears are not blown, white noise is not the ocean
		_gainNode.gain.value = 0.1;

		// we use this analyZer for the FFT (Fast Fourier Transform)
		_analyser = _audioContext.createAnalyser();
		// used to determine the frequency domain
		_analyser.fftSize = 2048;

		// source to analyser
		_bufferAudioSource.connect(_analyser);
		// analyser to gain
		_analyser.connect(_gainNode);
		// gain to out
		_gainNode.connect(_audioContext.destination);

		// Used to schedule playback of the audio data contained in the buffer, or to begin playback immediately.
		_bufferAudioSource.start();

		// callback for playing finished
		_bufferAudioSource.onended = () -> {
			Browser.console.log('White noise finished');
			if (_soundComplete != null) {
				_soundComplete();
			}
		}
	}
}
