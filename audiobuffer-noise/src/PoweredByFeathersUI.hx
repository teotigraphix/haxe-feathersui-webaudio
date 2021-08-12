package;

import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.net.URLRequest;
import feathers.controls.TextCallout;
import feathers.controls.AssetLoader;
import feathers.controls.Label;
import feathers.layout.HorizontalLayout;
import feathers.controls.LayoutGroup;

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
		icon.width = 150.0;
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
