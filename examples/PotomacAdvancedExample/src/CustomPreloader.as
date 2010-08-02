package
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.core.UIComponent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.events.RSLEvent;
	import mx.managers.SystemManager;
	import mx.preloaders.IPreloaderDisplay;
	
	import potomac.bundle.BundleEvent;
	import potomac.core.IPotomacPreloader;
	import potomac.core.StartupEvent;
	
	import spark.effects.Fade;
	import spark.effects.easing.IEaser;
	import spark.effects.easing.Linear;
	import spark.effects.easing.Power;
	
	public class CustomPreloader extends Sprite implements IPreloaderDisplay,IPotomacPreloader
	{
		
		private var _backgroundColor:uint = 0x464646;
		private var _stageHeight:Number = 1;
		private var _stageWidth:Number = 1;
		
		private var _appTitle:TextField;
		private var _progressTitle:TextField;
		private var _subTitle:TextField;
		private var _progressText:TextField;
		private var onRSLs:Boolean = false;
		
		public function CustomPreloader():void
		{		
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE,onRemovedFromStage);
		}
		
		
		public function set backgroundAlpha(alpha:Number):void{}
		public function get backgroundAlpha():Number { return 1; }
		
		public function set backgroundColor(color:uint):void { _backgroundColor = color; }
		public function get backgroundColor():uint { return _backgroundColor; }
		
		public function set backgroundImage(image:Object):void {}
		public function get backgroundImage():Object { return null; }
		
		public function set backgroundSize(size:String):void {}
		public function get backgroundSize():String { return "auto"; }
		
		public function set stageHeight(height:Number):void { _stageHeight = height; }
		public function get stageHeight():Number { return _stageHeight; }
		
		public function set stageWidth(width:Number):void { _stageWidth = width; }
		public function get stageWidth():Number { return _stageWidth; }
		
		
		public function initialize():void
		{
		}
		
		private function onAddedToStage(event:Event):void
		{
			//IPotomacPreloaders are actually added to the stage twice (added, removed, then added again)
			//therefore we only want to create the UI widgets once
			if (_progressText == null)
			{
				graphics.beginFill(_backgroundColor,1);
				graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
				graphics.endFill();
				
				_appTitle = new TextField();
				addChild(_appTitle);
				
				_appTitle.textColor = 0xFFFFFF;
				var textFormat:TextFormat = new TextFormat();
				textFormat.size = 42;
				_appTitle.defaultTextFormat = textFormat;
				_appTitle.text = "Potomac Advanced Example";
				
				
				_subTitle = new TextField();
				addChild(_subTitle);
				_subTitle.textColor = 0xFFFFFF;
				textFormat = new TextFormat();
				textFormat.size = 14;
				_subTitle.defaultTextFormat = textFormat;
				_subTitle.text = "This example preloader is designed to give you an overview of the capabilites and \nevents associated with IPotomacPreloader and [StartupListener], but it's not very pretty.";				
				
				
				_progressText = new TextField();
				addChild(_progressText);
				
				_progressText.textColor = 0x000000;
				textFormat = new TextFormat();
				textFormat.size = 12;
				_progressText.defaultTextFormat = textFormat;
				_progressText.border = true;	
				
				addText("Loading...");
				
				
				_progressTitle = new TextField();
				addChild(_progressTitle);
				
				_progressTitle.textColor = 0x000000;
				textFormat = new TextFormat();
				textFormat.size = 12;
				_progressTitle.defaultTextFormat = textFormat;
				_progressTitle.text = "Preloader and Bundle Progress Events: (use mouse wheel to scroll)";
				
				doLayout(null);
				
			}
			
			stage.addEventListener(Event.RESIZE,doLayout);
		}
		
		private function doLayout(event:Event):void
		{
			graphics.clear();
			graphics.beginFill(_backgroundColor,1);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			graphics.endFill();
			
			_appTitle.x = 10;
			_appTitle.y = 10;
			_appTitle.width = stage.stageWidth - 20;
			_appTitle.height = 50;
			
			_subTitle.x = 10;
			_subTitle.y = 55;
			_subTitle.width = stage.stageWidth - 20;
			_subTitle.height = 50;
			
			_progressText.x = 10;
			_progressText.y = stage.stageHeight - 200;
			_progressText.height = 170;
			_progressText.width = stage.stageWidth - 20;  
			
			_progressTitle.x = 10;
			_progressTitle.y = stage.stageHeight - 220;
			_progressTitle.width = stage.stageWidth - 20;
			_progressTitle.height = 20;
		}
		
		private function onRemovedFromStage(event:Event):void
		{
			stage.removeEventListener(Event.RESIZE,doLayout);	
		}
		
		
		public function set preloader(preloader:Sprite):void
		{		
			preloader.addEventListener(ProgressEvent.PROGRESS, onSWFDownloadProgress);
			preloader.addEventListener(Event.COMPLETE, onSWFDownloadComplete);
			preloader.addEventListener(FlexEvent.INIT_PROGRESS, onFlexInitProgress);
			preloader.addEventListener(FlexEvent.INIT_COMPLETE, onFlexInitComplete);	
			preloader.addEventListener(RSLEvent.RSL_PROGRESS, onRslProgress);
			preloader.addEventListener(RSLEvent.RSL_COMPLETE, rslCompleteHandler);
			preloader.addEventListener(RSLEvent.RSL_ERROR, rslErrorHandler);	
			
			addEventListener(BundleEvent.BUNDLE_PROGRESS,onBundleProgress);
			addEventListener(BundleEvent.BUNDLES_INSTALLING,onBundlesInstalling);
			addEventListener(BundleEvent.BUNDLES_PRELOADING,onPreloadsLoading);
			addEventListener(StartupEvent.PRELOADER_CLOSE_START,onPreloaderCloseStart);
		}
		
		
		private function onPreloaderCloseStart(event:StartupEvent):void
		{
			addText("PRELOADER DONE... PAUSING TO GIVE YOU A CHANCE TO READ THESE MESSAGES");
			addText("CLICK IN THIS FIELD AND USE YOUR MOUSEWHEEL TO SCROLL");
			addText("DOUBLE CLICK ANYWHERE ELSE TO UNPAUSE");
			
			doubleClickEnabled = true;
			addEventListener(MouseEvent.DOUBLE_CLICK,onDoubleClick);
		}
		
		private function onDoubleClick(event:MouseEvent):void
		{
			removeEventListener(MouseEvent.DOUBLE_CLICK,onDoubleClick);
			proceedWithClose();
		}
		
		private function proceedWithClose():void
		{
			//fade out
			var fade:Fade = new Fade();
			fade.alphaFrom = 1;
			fade.alphaTo = 0;
			fade.target = this;
			var easer:Power = new Power();
			easer.exponent =4;
			fade.easer = easer;
			fade.duration = 1000;
			fade.addEventListener(EffectEvent.EFFECT_END,onEffectEnd);
			fade.play();
		}
		
		private function onEffectEnd(event:EffectEvent):void
		{
			dispatchEvent(new Event(StartupEvent.PRELOADER_CLOSE_COMPLETE));
		}
		
		private function onPreloadsLoading(event:Event):void
		{
			addText("-------- Loading Bundle Preloads ----------");
		}
		
		private function onBundlesInstalling(event:Event):void
		{
			addText("----------- Installing Bundles (downloading assets.swf's) ---------");
		}
		
		private function onBundleProgress(event:BundleEvent):void
		{
			addText(Math.ceil((event.bytesLoaded / event.bytesTotal) * 100) + "%" + ": " + event.url);
		}
		
		
		private function rslErrorHandler(event:RSLEvent):void
		{
			addText("ERROR: " + event.errorText);
		}
		
		private function rslCompleteHandler(event:RSLEvent):void
		{
		}
		
		private function onRslProgress(event:RSLEvent):void
		{
			if (!onRSLs)
			{
				onRSLs = true;
				addText("---------- RSLs ------------");
			}
			addText(getPercent(event) + ": " + event.url.url);
		}	
			
		private function onSWFDownloadProgress(event:ProgressEvent):void
		{
			//This reports all progress of all SWFs and you can't tell which
			//before the RSLs start this is the main SWF
			if (!onRSLs)
				addText(getPercent(event) + ": main SWF");
		}
		
		private function onSWFDownloadComplete(event:Event):void
		{
		}
		
		private function onFlexInitProgress(event:FlexEvent):void
		{
		}
		
		private function onFlexInitComplete(event:FlexEvent):void
		{
			//Let the normal Flex preloading code remove this from the stage
			//Potomac will add it back for us and continue with Potomac events
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function getPercent(event:ProgressEvent):String
		{
			return Math.ceil((event.bytesLoaded / event.bytesTotal) * 100) + "%";
		}
		
		private function addText(text:String):void
		{
			_progressText.appendText(text +"\n");
			_progressText.scrollV = _progressText.maxScrollV;
		}
		
	}
}