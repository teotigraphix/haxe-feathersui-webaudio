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
// Author: Michael Schmalle, Principal Architect
// teotigraphixllc at gmail dot com
////////////////////////////////////////////////////////////////////////////////
import feathers.controls.Application;
import feathers.controls.AssetLoader;
import feathers.controls.HSlider;
import feathers.controls.Label;
import feathers.controls.LayoutGroup;
import feathers.controls.TextCallout;
import feathers.controls.ToggleButton;
import feathers.core.FeathersControl;
import feathers.layout.HorizontalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import feathers.skins.BaseGraphicsPathSkin;
import feathers.skins.RectangleSkin;
import feathers.text.TextFormat;
import js.Browser;
import js.html.AudioElement;
import js.html.MediaElement;
import js.html.MediaStream;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import js.html.audio.MediaElementAudioSourceNode;
import js.html.audio.StereoPannerNode;
import js.html.audio.StereoPannerOptions;
import openfl.Lib;
import openfl.display.LineScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;

/**
	Translation from with love;
	@see https://mdn.github.io/webaudio-examples/audio-basics/
	@see https://github.com/mdn/webaudio-examples/tree/master/audio-basics
 */
class Main extends Application {
	//-----------------------------------------------------------------------------
	// App :: Variables
	//-----------------------------------------------------------------------------
	private var _soundEngine:SoundEngine;

	private var _soundFile:String = "/assets/audio/audio-basics_outfoxing.mp3";

	//-----------------------------------------------------------------------------
	// UI Control :: Variables
	//-----------------------------------------------------------------------------
	// Controls
	private var playControl:ToggleButton;
	private var volumeControl:HSlider;
	private var panControl:HSlider;
	private var powerControl:ToggleButton;

	private var volumeLabel:Label;
	private var panLabel:Label;

	private var speakerLeft:SpeakerComponent;
	private var eightTrack:EightTrackComponent;
	private var speakerRight:SpeakerComponent;

	// Sections
	private var handleSection:LayoutGroup;
	private var controlsSection:LayoutGroup;
	private var componentsSection:LayoutGroup;
	private var footerSection:LayoutGroup;

	//
	private var lastWidth:Float = 0;
	private var lastHeight:Float = 0;

	private var isLandscape:Bool = false;
	private var oldIslandscape:Bool = false;

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

		_soundEngine = new SoundEngine(_soundFile);
	}

	//-----------------------------------------------------------------------------
	// Overridden :: Methods
	//-----------------------------------------------------------------------------

	override function initialize() {
		super.initialize();

		var hl = new VerticalLayout();
		hl.setPadding(ComponentFactory.LARGE_PADDING);
		layout = hl;

		handleSection = createHandle();
		controlsSection = createControlsSection();
		componentsSection = createComponentsSection();
		footerSection = createFooter();

		addChild(handleSection);
		addChild(controlsSection);
		addChild(componentsSection);
		addChild(footerSection);
	}

	override function update() {
		super.update();

		var sizeInvalid = isInvalid(SIZE);
		var sizeChanged:Bool = lastWidth != stage.stageWidth || lastHeight != stage.stageHeight;

		lastWidth = stage.stageWidth;
		lastHeight = stage.stageHeight;

		if (sizeInvalid || sizeChanged) {
			relayout();
		}
	}

	//-----------------------------------------------------------------------------
	// UI Creation : Methods
	//-----------------------------------------------------------------------------

	private function createHandle():LayoutGroup {
		var group:LayoutGroup = new LayoutGroup();
		group.layoutData = new VerticalLayoutData(100);
		group.height = ComponentFactory.CONTROLS_HEIGHT;
		group.backgroundSkin = new HandleSkin();
		return group;
	}

	private function createControlsSection():LayoutGroup {
		var hl:HorizontalLayout = new HorizontalLayout();
		hl.gap = ComponentFactory.LARGE_PADDING;
		hl.verticalAlign = MIDDLE;
		hl.setPadding(ComponentFactory.LARGE_PADDING);

		var section:LayoutGroup = new LayoutGroup();
		section.height = ComponentFactory.COMPONENTS_HEIGHT;
		section.layoutData = new VerticalLayoutData(100);
		section.layout = hl;
		section.backgroundSkin = ComponentFactory.createRectangleSkin(8.0, ComponentFactory.blackColor, ComponentFactory.lightBlueColor, 16.0, 16.0);

		////////////////

		volumeLabel = ComponentFactory.createLabel("VOLUME", "Helvetica", 20, ComponentFactory.labelColor, true);
		panLabel = ComponentFactory.createLabel("PAN", "Helvetica", 20, ComponentFactory.labelColor, true);

		//////////////////
		// Create Controls
		playControl = ComponentFactory.createPlayControl();
		playControl.addEventListener(Event.CHANGE, playControl_changeHandler);

		volumeControl = ComponentFactory.createVolumeSlider();
		volumeControl.layoutData = new HorizontalLayoutData(100, 100);
		volumeControl.addEventListener(Event.CHANGE, volumeControl_changeHandler);

		panControl = ComponentFactory.createVolumeSlider();
		panControl.layoutData = new HorizontalLayoutData(100, 100);
		panControl.addEventListener(Event.CHANGE, panControl_changeHandler);

		powerControl = ComponentFactory.createPowerControl();
		powerControl.addEventListener(Event.CHANGE, powerControl_changeHandler);

		return section;
	}

	private function createComponentsSection():LayoutGroup {
		var section:LayoutGroup = new LayoutGroup();
		section.layoutData = new VerticalLayoutData(100, 100);
		section.backgroundSkin = ComponentFactory.createRectangleSkin(8.0, ComponentFactory.blackColor, ComponentFactory.darkBlueColor, 16.0, 16.0);

		speakerLeft = new SpeakerComponent();

		eightTrack = new EightTrackComponent();
		eightTrack.playControl = playControl;

		speakerRight = new SpeakerComponent();

		return section;
	}

	private function createFooter():LayoutGroup {
		var hl:HorizontalLayout = new HorizontalLayout();
		hl.horizontalAlign = RIGHT;
		hl.setPadding(16);

		var group:LayoutGroup = new LayoutGroup();
		group.layoutData = new VerticalLayoutData(100);
		group.height = 50;
		group.layout = hl;

		var poweredBy = new PoweredByFeathersUI();
		group.addChild(poweredBy);

		return group;
	}

	//-----------------------------------------------------------------------------
	// UI Layout :: Methods
	//-----------------------------------------------------------------------------

	private function relayout():Void {
		var isLandscape:Bool = actualWidth > actualHeight;
		if (oldIslandscape != isLandscape) {
			if (isLandscape) {
				layoutLandscape();
			} else {
				layoutPortrait();
			}
		}

		oldIslandscape = isLandscape;
	}

	private function layoutLandscape():Void {
		trace("layoutLandscape()");
		isLandscape = true;

		controlsSection.removeChildren();
		componentsSection.removeChildren();

		controlsSection.addChild(volumeLabel);
		controlsSection.addChild(volumeControl);
		controlsSection.addChild(panLabel);
		controlsSection.addChild(panControl);
		controlsSection.addChild(powerControl);

		componentsSection.addChild(speakerLeft);
		componentsSection.addChild(eightTrack);
		componentsSection.addChild(speakerRight);

		// Controls
		var hl:HorizontalLayout = new HorizontalLayout();
		hl.gap = 16;
		hl.setPadding(32);
		hl.verticalAlign = MIDDLE;
		controlsSection.layout = hl;

		speakerLeft.layoutData = new HorizontalLayoutData(100, 100);
		eightTrack.layoutData = new HorizontalLayoutData(100, 100);
		speakerRight.layoutData = new HorizontalLayoutData(100, 100);

		// Components
		var hl:HorizontalLayout = new HorizontalLayout();
		hl.verticalAlign = MIDDLE;

		componentsSection.layoutData = new VerticalLayoutData(100, 100);
		componentsSection.layout = hl;
	}

	private function layoutPortrait():Void {
		trace("layoutPortrait()");
		isLandscape = false;

		controlsSection.removeChildren();
		componentsSection.removeChildren();

		controlsSection.addChild(volumeLabel);
		controlsSection.addChild(volumeControl);
		controlsSection.addChild(panLabel);
		controlsSection.addChild(panControl);
		controlsSection.addChild(powerControl);

		componentsSection.addChild(eightTrack);
		componentsSection.addChild(speakerLeft);

		speakerLeft.layoutData = new VerticalLayoutData(100, 100);
		eightTrack.layoutData = new VerticalLayoutData(100, 100);

		// Controls

		// Components
		var vl:VerticalLayout = new VerticalLayout();

		componentsSection.layoutData = new VerticalLayoutData(100, 100);
		componentsSection.layout = vl;
	}

	//-----------------------------------------------------------------------------
	// Private : Methods
	//-----------------------------------------------------------------------------

	private function setPlaying(value:Bool):Void {
		trace('setPlaying + ${value}');

		if (value) {
			_soundEngine.play();
			// playControl.text = "PAUSE";
		} else {
			_soundEngine.pause();
			// playControl.text = "PLAY";
		}
	}

	/** */
	private function setPan(value:Float):Void {
		_soundEngine.pan = value;
	}

	/** */
	private function setGain(value:Float):Void {
		_soundEngine.gain = value;
	}

	//-----------------------------------------------------------------------------
	// Private :: Handlers
	//-----------------------------------------------------------------------------

	private function volumeControl_changeHandler(event:Event):Void {
		var slider = cast(event.currentTarget, HSlider);
		trace('volumeControl.value change: ${slider.value}');

		setGain(slider.value);
	}

	private function panControl_changeHandler(event:Event):Void {
		var slider = cast(event.currentTarget, HSlider);
		trace('panControl.value change: ${slider.value}');

		setPan(slider.value);
	}

	private function powerControl_changeHandler(event:Event):Void {
		var button = cast(event.currentTarget, ToggleButton);
		trace('powerControl.selected change: ${button.selected}');

		_soundEngine.powered = false;
	}

	private function playControl_changeHandler(event:Event):Void {
		var button = cast(event.currentTarget, ToggleButton);
		trace('playControl.selected change: ${button.selected}');

		setPlaying(button.selected);
	}

	private function stage_mouseDownHandler(event:MouseEvent):Void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDownHandler, true);
		_soundEngine.userInitialize();
	}
}

class ComponentFactory {
	public static var PADDING:Float = 8;
	public static var LARGE_PADDING:Float = PADDING * 4.0;
	public static var MEDIUM_PADDING:Float = PADDING * 2.0;
	public static var CONTROLS_HEIGHT:Float = 100.0;
	public static var COMPONENTS_HEIGHT:Float = 200.0;

	public static var orangeColor:Int = 0xFF8800;
	public static var lightBlueColor:Int = 0x1CC4FD;
	public static var darkBlueColor:Int = 0x1481F5;
	public static var blackColor:Int = 0x000000;
	public static var backgroundColor:Int = 0xFFFFFF;
	public static var labelColor:Int = 0x000000;

	public static function createPlayControl() {
		var button:ToggleButton = new ToggleButton();

		var skin = new PlayButtonSkin();
		skin.border = SolidColor(12, ComponentFactory.blackColor, 1, false, LineScaleMode.NORMAL, ROUND);
		skin.fill = SolidColor(ComponentFactory.blackColor);

		var selectedSkin = new PlayButtonSkin();
		selectedSkin.border = SolidColor(12, ComponentFactory.orangeColor, 1, false, LineScaleMode.NORMAL, ROUND);
		selectedSkin.fill = SolidColor(ComponentFactory.orangeColor, 1.0);

		button.backgroundSkin = skin;
		button.selectedBackgroundSkin = selectedSkin;

		return button;
	}

	public static function createVolumeSlider():HSlider {
		var slider:HSlider = ComponentFactory.createHSlider(0.0, 2.0, 1.0, 0.01);
		return slider;
	}

	public static function createPanSlider():HSlider {
		var slider:HSlider = ComponentFactory.createHSlider(-1.0, 1.0, 0.0, 0.01);
		return slider;
	}

	public static function createPowerControl():ToggleButton {
		var button:ToggleButton = new ToggleButton();
		button.backgroundSkin = new PowerButtonSkin();
		return button;
	}

	public static function createHSlider(minimum:Float, maximum:Float, value:Float, step:Float):HSlider {
		var slider = new HSlider();
		slider.minimum = minimum;
		slider.maximum = maximum;
		slider.value = value;
		slider.step = step;

		var thumbSkin = ComponentFactory.createRectangleSkin(4.0, ComponentFactory.blackColor, ComponentFactory.darkBlueColor, 48.0, 48.0);
		slider.thumbSkin = thumbSkin;

		var trackSkin = ComponentFactory.createRectangleSkin(1.0, ComponentFactory.blackColor, ComponentFactory.blackColor, 60.0, 16.0);
		slider.trackSkin = trackSkin;

		var secondaryTrackSkin = ComponentFactory.createRectangleSkin(1.0, ComponentFactory.blackColor, ComponentFactory.blackColor, 60.0, 16.0);
		slider.secondaryTrackSkin = secondaryTrackSkin;

		return slider;
	}

	public static function createLabel(text:String, font:String = "Helvetica", size:Int = 20, color:Int = 0x000000, bold:Bool = false):Label {
		var label:Label = new Label();
		label.text = text;
		label.textFormat = new TextFormat(font, size, color, bold);
		return label;
	}

	public static function createRectangleSkin(strokeThickness:Float, strokeColor:Int, fillColor:Int, width:Float = 0.0, height:Float = 0.0):RectangleSkin {
		var skin = new RectangleSkin();
		skin.border = SolidColor(strokeThickness, strokeColor);
		skin.fill = SolidColor(fillColor);
		if (width != 0)
			skin.width = width;
		if (height != 0)
			skin.height = height;
		return skin;
	}
}

//-----------------------------------------------------------------------------
// Private :: Methods
//-----------------------------------------------------------------------------

class SpeakerComponent extends FeathersControl {
	public function new() {
		super();
	}

	override function initialize() {
		super.initialize();
	}

	override function update() {
		super.update();

		graphics.clear();

		var padding:Float = 42;
		var padding2:Float = padding * 2;
		var radius:Float = actualWidth > actualHeight ? actualHeight : actualWidth;
		radius -= padding;

		var centerX:Float = radius / 2;
		var centerY:Float = radius / 2;

		centerX = ((actualWidth) / 2);
		centerY = ((actualHeight) / 2);

		// centerY = Min(centerY, )
		graphics.lineStyle(10, ComponentFactory.blackColor, 1);
		graphics.beginFill(ComponentFactory.darkBlueColor, 1.0);
		graphics.drawRect(0, 0, actualWidth, actualHeight);
		graphics.endFill();

		// Circle 1
		graphics.lineStyle(10, ComponentFactory.blackColor, 1);
		graphics.beginFill(ComponentFactory.lightBlueColor, 1.0);
		graphics.drawCircle(centerX, centerY, (radius - 20) / 2);
		graphics.endFill();

		// Circle 2
		graphics.lineStyle(4, ComponentFactory.blackColor, 1);
		graphics.beginFill(ComponentFactory.lightBlueColor, 1.0);
		graphics.drawCircle(centerX, centerY, (radius - 100) / 2);
		graphics.endFill();

		// Circle 3
		graphics.lineStyle(10, ComponentFactory.blackColor, 1);
		graphics.beginFill(ComponentFactory.darkBlueColor, 1.0);
		graphics.drawCircle(centerX, centerY, 80 / 2);
		graphics.endFill();
	}
}

class EightTrackComponent extends FeathersControl {
	//-----------------------------------
	// playControl
	//-----------------------------------
	private var _playControl:ToggleButton;

	/**
		Doc `playControl`.
	 */
	public var playControl(get, set):ToggleButton;

	private function get_playControl():ToggleButton {
		return _playControl;
	}

	private function set_playControl(value:ToggleButton):ToggleButton {
		if (_playControl == value)
			return _playControl;
		if (_playControl != null) {
			removeChild(_playControl);
		}
		_playControl = value;
		if (_playControl != null) {
			addChild(_playControl);
		}
		return _playControl;
	}

	public function new() {
		super();
	}

	override function initialize() {
		super.initialize();
	}

	override function update() {
		super.update();

		if (_playControl != null) {
			_playControl.validateNow();
			_playControl.move((actualWidth - _playControl.width) / 2, actualHeight - _playControl.height - 20);
		}

		graphics.clear();

		graphics.lineStyle(10, 0x000000);
		graphics.beginFill(0x1481F5, 1.0);
		graphics.drawRect(0, 0, actualWidth, actualHeight);
		graphics.endFill();

		var padding:Float = 40;
		var rectWidth:Float = actualWidth - (padding * 2);
		var rectHeight:Float = actualHeight / 3;

		var radius = rectHeight; // / 2;
		graphics.lineStyle(14, 0x000000);
		graphics.beginFill(0xFF8800, 1.0);
		graphics.drawRoundRect(padding, rectHeight, rectWidth, rectHeight, radius);
		graphics.endFill();

		var radius = rectHeight / 4;
		// Circle Left
		graphics.lineStyle(8, 0x000000);
		graphics.beginFill(0x1481F5, 1.0);
		graphics.drawCircle(padding + padding + radius, rectHeight + (rectHeight / 2), radius);
		graphics.endFill();

		// Circle Right
		graphics.lineStyle(8, 0x000000);
		graphics.beginFill(0x1481F5, 1.0);
		graphics.drawCircle(actualWidth - (padding + padding + radius), rectHeight + (rectHeight / 2), radius);
		graphics.endFill();
	}
}

class PowerButtonSkin extends BaseGraphicsPathSkin {
	public function new() {
		super();

		width = 75;
		height = 75;
	}

	override function update() {
		super.update();

		graphics.clear();

		var centerX = actualWidth / 2;
		var centerY = actualHeight / 2;
		var radius = actualHeight / 2;

		// Outer Circle
		graphics.lineStyle(8, 0x000000, 1);
		graphics.beginFill(ComponentFactory.orangeColor, 1.0);
		graphics.drawCircle(centerX, centerY, radius);
		graphics.endFill();

		// Inner Circle
		graphics.lineStyle(6, 0x000000, 1);
		graphics.beginFill(ComponentFactory.orangeColor, 1.0);
		graphics.drawCircle(centerX, centerY, radius - 20);
		graphics.endFill();

		// Vertical back ink
		graphics.lineStyle(12, ComponentFactory.orangeColor, 1, false, LineScaleMode.NORMAL, ROUND);
		graphics.moveTo(centerX, centerY);
		graphics.lineTo(centerX, 16);

		// Vertical ink
		graphics.lineStyle(8, 0x000000, 1, false, LineScaleMode.NORMAL, ROUND);
		graphics.moveTo(centerX, centerY);
		graphics.lineTo(centerX, 16);
	}
}

class PlayButtonSkin extends BaseGraphicsPathSkin {
	public function new() {
		super();

		width = 42.0;
		height = 42.0;
	}

	override function drawPath() {
		super.drawPath();

		// graphics.beginFill(fill, 1);
		// graphics.lineStyle(12, 0x000000, 1, false, LineScaleMode.NORMAL, ROUND);
		graphics.moveTo(0, 0);
		graphics.lineTo(actualWidth, actualHeight / 2);
		graphics.lineTo(0, actualHeight);
	}
}

class HandleSkin extends BaseGraphicsPathSkin {
	public function new() {
		super();
	}

	override function update() {
		super.update();

		graphics.clear();

		var padding:Float = 50;
		var halfHeight:Float = actualHeight / 2;
		var contentWidth:Float = (actualWidth - (padding * 2));

		graphics.lineStyle(10, 1);
		graphics.beginFill(ComponentFactory.orangeColor, 1);
		graphics.drawRect(padding, 0, contentWidth, halfHeight);
		graphics.endFill();

		graphics.lineStyle(10, 1);
		graphics.beginFill(ComponentFactory.backgroundColor, 1);
		graphics.drawRect(padding, halfHeight, contentWidth, halfHeight);
		graphics.endFill();
	}
}

class SoundEngine {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	// The AudioContext interface represents an audio-processing graph built from audio
	// modules linked together, each represented by an AudioNode.
	private var _audioContext:AudioContext;

	// The HTMLAudioElement interface provides access to the properties of audio elements, as
	// well as methods to manipulate them. It derives from the HTMLMediaElement interface.
	private var _audioElement:AudioElement;
	// The MediaStream interface represents a stream of media content. A stream consists of
	// several tracks such as video or audio tracks. Each track is specified as an instance
	// of MediaStreamTrack.
	private var _mediaStream:MediaStream;

	// The GainNode interface represents a change in volume.
	private var _gainNode:GainNode;
	// The pan property takes a unitless value between -1 (full left pan) and 1 (full right pan).
	private var _panNode:StereoPannerNode;

	//
	private var _soundFile:String;

	//-----------------------------------------------------------------------------
	// API :: Properties
	//-----------------------------------------------------------------------------
	//-----------------------------------
	// powered
	//-----------------------------------
	private var _powered:Bool;

	/**
		Doc `powered`.
	 */
	public var powered(get, set):Bool;

	private function get_powered():Bool {
		return _powered;
	}

	private function set_powered(value:Bool):Bool {
		if (_powered == value)
			return _powered;
		_powered = value;
		_audioElement.muted = !_powered;
		return _powered;
	}

	//-----------------------------------
	// gain
	//-----------------------------------
	private var _gain:Float = 1.0;

	/**
		Sets the `GainNode`'s `gain` value.
	 */
	public var gain(get, set):Float;

	private function get_gain():Float {
		return _gain;
	}

	private function set_gain(value:Float):Float {
		if (_gain == value)
			return _gain;
		_gain = value;
		_gainNode.gain.value = _gain;
		return _gain;
	}

	//-----------------------------------
	// pan
	//-----------------------------------
	private var _pan:Float = 0.0;

	/**
		Sets the `StereoPannerNode`'s `pan` value.
	 */
	public var pan(get, set):Float;

	private function get_pan():Float {
		return _pan;
	}

	private function set_pan(value:Float):Float {
		if (_pan == value)
			return _pan;
		_pan = value;
		_panNode.pan.value = value;
		return _pan;
	}

	//-----------------------------------------------------------------------------
	// Constructor
	//-----------------------------------------------------------------------------

	/** */
	public function new(soundFile:String) {
		_soundFile = soundFile;
	}

	//-----------------------------------------------------------------------------
	// API :: Methods
	//-----------------------------------------------------------------------------

	/** */
	public function userInitialize():Void {
		_audioContext = new AudioContext();
		_audioElement = createAudioElement(_soundFile);

		var audioSource:MediaElementAudioSourceNode = _audioContext.createMediaElementSource(cast(_audioElement, MediaElement));

		var pannerOptions:StereoPannerOptions = {pan: 0};

		_gainNode = _audioContext.createGain();
		_panNode = new StereoPannerNode(_audioContext, pannerOptions);

		// connect our graph
		audioSource.connect(_gainNode).connect(_panNode).connect(_audioContext.destination);
	}

	/** */
	public function play():Void {
		_audioElement.play();
	}

	/** */
	public function pause():Void {
		_audioElement.pause();
	}

	//-----------------------------------------------------------------------------
	// Private :: Methods
	//-----------------------------------------------------------------------------

	private function createAudioElement(soundFile:String):AudioElement {
		// audioElement = Browser.document.querySelector('audio');
		// <audio src="outfoxing.mp3" crossorigin="anonymous" ></audio>
		var element = Browser.document.createAudioElement();
		element.setAttribute("src", soundFile);
		element.setAttribute("crossorigin", "anonymous");
		return element;
	}
}

/**
	Displays the Feathers UI logo and links to feathersui.com
**/
class PoweredByFeathersUI extends LayoutGroup {
	public function new() {
		super();

		var hl = new HorizontalLayout();
		hl.verticalAlign = MIDDLE;
		layout = hl;

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		var label = new Label();
		label.text = "Powered by ";
		addChild(label);

		var icon = new AssetLoader();
		// <assets id="feathersui-logo" path="assets/img/feathersui-logo.png" embed="false"/>
		icon.source = "feathersui-logo";
		icon.height = 16.0;
		addChild(icon);

		addEventListener(MouseEvent.ROLL_OVER, poweredBy_rollOverHandler);
		addEventListener(MouseEvent.ROLL_OUT, poweredBy_rollOutHandler);
		addEventListener(MouseEvent.CLICK, poweredBy_clickHandler);
	}

	private var callout:TextCallout;

	private function poweredBy_rollOverHandler(event:MouseEvent):Void {
		callout = TextCallout.show("Learn more at feathersui.com", this, null, false);
	}

	private function poweredBy_rollOutHandler(event:MouseEvent):Void {
		if (callout != null) {
			callout.close();
		}
	}

	private function poweredBy_clickHandler(event:MouseEvent):Void {
		Lib.navigateToURL(new URLRequest("https://feathersui.com/"), "_blank");
	}
}