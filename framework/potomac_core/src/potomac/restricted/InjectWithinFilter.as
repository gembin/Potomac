package potomac.restricted
{
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.inject.InjectionEvent;
	import potomac.inject.Injector;
	
	
	[ExtensionPoint(id="InjectWithin",declaredOn="classes",access="public",target="*string")]
	[ExtensionPointDetails(id="InjectWithin",description="Executes dependency injection on the target component")]
	[ExtensionPointDetails(id="InjectWithin",attribute="target",description="Component to inspect and satisfy inner injections",order="1")]
	
	[InjectionListener]
	/**
	 * @private
	 */	
	public class InjectWithinFilter extends EventDispatcher
	{
		private var _bundleService:IBundleService;
		private var _injector:Injector;
		
		[Inject]
		public function InjectWithinFilter(bundleSrv:IBundleService,injector:Injector)
		{
			_bundleService = bundleSrv;
			_injector = injector;
			addEventListener(InjectionEvent.POST_INJECTION,onInstanceReady);
		}
		
		public function onInstanceReady(event:InjectionEvent):void
		{
			doInnerInjection(event.instance,false);
		}
		
		private function doInnerInjection(injectee:Object,afterInitialize:Boolean):void
		{
			if (!afterInitialize && injectee is UIComponent)
			{
				injectee.addEventListener(FlexEvent.INITIALIZE,onInitialize,false,0,true);
				return;
			}
			
			var className:String = getQualifiedClassName(injectee);
			while (className != null && className != "Object")
			{
				injectForClassName(injectee,afterInitialize,className);
				className = getQualifiedSuperclassName(getDefinitionByName(className));
			}
			
		}
		
		private function injectForClassName(injectee:Object, afterInitialize:Boolean, className:String):void
		{
			var injectWithins:Array = _bundleService.getExtensions("InjectWithin",className);
			for (var i:int = 0; i < injectWithins.length; i++)
			{
				var ext:Extension = injectWithins[i] as Extension;
				if (!(ext.target in injectee))
					throw new Error("InjectWithin target '" + ext.target + "' not found within " + ext.className);
				_injector.injectInto(injectee[ext.target]);
			}			
		}
		
		
		private function onInitialize(event:FlexEvent):void
		{
			var injectee:Object = event.target;
			injectee.removeEventListener(FlexEvent.INITIALIZE,onInitialize);
			doInnerInjection(injectee,true);			
		}
		
	}
}