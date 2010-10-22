/*******************************************************************************
 *  Copyright (c) 2009 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 *
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package potomac.ui.restricted
{
	import flash.display.DisplayObject;

	import mx.containers.Canvas;
	import mx.core.UIComponent;

	/**
	 * @private
	 */
	public dynamic class BusyCanvas extends Canvas
	{
		private var _busy:Boolean=false;
		private var _overlay:BusyOverlay=new BusyOverlay();

		public function BusyCanvas()
		{
		}

		override public function addChild(child:DisplayObject):DisplayObject
		{
			if (child is UIComponent)
				UIComponent(child).setStyle("disabledOverlayAlpha", 0);
			return super.addChild(child);
		}

		public function get busy():Boolean
		{
			return _busy;
		}

		public function set busy(flag:Boolean):void
		{
			if (_busy == flag)
				return;

			_busy=flag;
			if (flag)
			{
				setKidsEnable(false);
				addChild(_overlay);
				_overlay.start();
			}
			else
			{
				removeChild(_overlay);
				setKidsEnable(true);
				_overlay.stop();
			}

			invalidateDisplayList();
		}

		public function set busyText(busyText:String):void
		{
			_overlay.busyText=busyText;
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			_overlay.x=0;
			_overlay.y=0;
			_overlay.width=unscaledWidth;
			_overlay.height=unscaledHeight;

		}

		private function setKidsEnable(flag:Boolean):void
		{
			var kids:Array=getChildren();
			for (var i:int=0; i < kids.length; i++)
			{
				if (kids[i] is UIComponent)
					UIComponent(kids[i]).enabled=flag;
			}
		}

	}
}