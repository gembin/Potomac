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
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.controls.Label;
	import mx.core.UIComponent;
	
	/**
	 * @private
	 */
	public class BusyOverlay extends UIComponent
	{
		private var _timer:Timer;
		private var _currentImage:int = 0;
		private var _label:Label;
		
		public function BusyOverlay()
		{
			_timer = new Timer(50);
			_timer.addEventListener(TimerEvent.TIMER,timer);
		}
		
		private function timer(e:TimerEvent):void
		{
			_currentImage ++;
			if (_currentImage >= 24)
				_currentImage = 0;
			invalidateDisplayList();
		}
		
		public function start():void
		{
			if(!_timer.running)
			{
				_currentImage = 0;
				invalidateDisplayList();
				_timer.start();
			}
		}
		
		public function stop():void
		{
			if (_timer.running)
			{
				_timer.stop();
				if (numChildren > 1)
					removeChildAt(1);
			}
		}
		
		override protected function createChildren():void
		{
			_label = new Label();		
			addChild(_label);
			_label.setStyle("fontWeight","bold");
			_label.setStyle("textAlign","center");
		}
		
		public function set busyText(busyText:String):void
		{
			_label.text = busyText;
			_label.validateSize();
			_label.width = _label.measuredWidth;
			_label.height = _label.measuredHeight;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			graphics.clear();			
			graphics.beginFill(0xFFFFFF,0.6);
			graphics.drawRect(0,0,width,height);
			graphics.endFill();
			
			if (_timer.running)
			{
				if (numChildren > 1)
					removeChildAt(1);
					
				var child:DisplayObject = addChild(new BusyImages.images[_currentImage]());
				child.x = (width - child.width)/2;
				child.y = (height - (child.height+5+_label.height))/2;
				
				_label.x = 0;
				_label.width = width;
				_label.y = child.y + child.height +5; 
				validateNow();				
			}
			
			
		}

	}
}