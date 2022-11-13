package;

/*
	[simple-sequencer] Checked against FeathersUI v1.0.0

	Copyright 2022 Teoti Graphix, LLC. All Rights Reserved.
	Author: Michael Schmalle - https://teotigraphix.com

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */
import feathers.controls.Application;
import feathers.layout.VerticalLayout;
import js.Browser;
import js.html.audio.AudioContext;
import openfl.events.Event;
import openfl.events.MouseEvent;

// [simple-sequencer]
// Checked against FeathersUI v1.0.0

class Main extends Application {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _soundEngine:SoundEngine;

	private var poweredByFeathersUI:PoweredByFeathersUI;

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

		_soundEngine = new SoundEngine();
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

		poweredByFeathersUI = new PoweredByFeathersUI();
		poweredByFeathersUI.includeInLayout = false;

		addChild(poweredByFeathersUI);
	}

	override function update() {
		super.update();

		var sizeInvalid = isInvalid(SIZE);

		if (sizeInvalid) {
			var poweredByX:Float = actualWidth - poweredByFeathersUI.width - 32.0;
			var poweredByY:Float = actualHeight - poweredByFeathersUI.height - 32.0;

			poweredByFeathersUI.move(poweredByX, poweredByY);
		}
	}

	//-----------------------------------------------------------------------------
	// Private :: Handlers
	//-----------------------------------------------------------------------------

	private function stage_mouseDownHandler(event:MouseEvent):Void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, stage_mouseDownHandler, true);
		_soundEngine.userInitialize();
	}

	private function main_enterFrameHandler(event:Event):Void {}

	private function playControl_changeHandler(event:Event):Void {
		addEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
	}

	private function soundEngine_soundComplete():Void {
		removeEventListener(Event.ENTER_FRAME, main_enterFrameHandler);
	}
}

class SoundEngine {
	//-----------------------------------------------------------------------------
	// Private :: Variables
	//-----------------------------------------------------------------------------
	private var _audioContext:AudioContext;

	//-----------------------------------------------------------------------------
	// Constructor
	//-----------------------------------------------------------------------------

	public function new() {}

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
}
