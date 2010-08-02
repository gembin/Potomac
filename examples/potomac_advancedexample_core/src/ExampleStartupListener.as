package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getDefinitionByName;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.EffectEvent;
	
	import potomac.bundle.BundleEvent;
	import potomac.bundle.BundleInstallDescriptor;
	import potomac.bundle.IBundleService;
	import potomac.core.StartupEvent;
	
	import spark.effects.Fade;
	import spark.effects.easing.Power;
	
	[StartupListener]
	public class ExampleStartupListener extends EventDispatcher
	{
		private var bundleService:IBundleService;
		private var loginComponent:LoginComponent;

		[Inject]
		public function ExampleStartupListener(bundleService:IBundleService)
		{
			this.bundleService = bundleService; 
		}

		[Handles(event="potomacInitialized")]
		public function onInit(event:Event):void
		{
			loginComponent = new LoginComponent();
			FlexGlobals.topLevelApplication.addElement(loginComponent);
			
			loginComponent.addEventListener(Event.COMPLETE,onLoginComplete);
			FlexGlobals.topLevelApplication.addEventListener(Event.RESIZE,onResize);
			onResize(null);
		}

		private function onResize(event:Event):void
		{
			loginComponent.x = (loginComponent.stage.stageWidth - loginComponent.width)/2;
			loginComponent.y = (loginComponent.stage.stageHeight - 200 - loginComponent.height)/2;
		}

		private function onLoginComplete(event:Event):void
		{			
			//This code just statically adds the two additional bundles but real code could call a 
			//webservice to determine what bundles to load.
			
			bundleService.addEventListener(BundleEvent.BUNDLES_INSTALLED,onBundlesInstalled);
			var descriptors:Array = new Array();
			
			throw new Error("Please change the workspacePath var in code before executing this example");
			
			var workspacePath:String = "REPLACE THIS WITH THE ABSOLUTE PATH TO YOUR FLASH BUILDER WORKSPACE DIRECTORY";
			//workspacePath = "C:/Users/userid/Adobe Flash Builder 4";
			var desc1:BundleInstallDescriptor = new BundleInstallDescriptor("potomac_mailexample_mail",false,"file://"+workspacePath+"/potomac_mailexample_mail/bin");
			var desc2:BundleInstallDescriptor = new BundleInstallDescriptor("potomac_mailexample_rss",false,"file://"+workspacePath+"/potomac_mailexample_rss/bin");
			descriptors.push(desc1);
			descriptors.push(desc2);
			bundleService.install(descriptors);
		}

		private function onBundlesInstalled(event:BundleEvent):void
		{			
			var fade:Fade = new Fade();
			fade.alphaFrom = 1;
			fade.alphaTo = 0;
			fade.target = loginComponent;
			var easer:Power = new Power();
			easer.exponent =4;
			fade.easer = easer;
			fade.duration = 3000;
			fade.addEventListener(EffectEvent.EFFECT_END,onEffectEnd);
			fade.play();
			
			dispatchEvent(new StartupEvent(StartupEvent.STARTUPLISTENER_COMPLETE));
		}

		private function onEffectEnd(event:Event):void
		{
			FlexGlobals.topLevelApplication.removeEventListener(Event.RESIZE,onResize);
			FlexGlobals.topLevelApplication.removeElement(loginComponent);
		}
		
	}
}