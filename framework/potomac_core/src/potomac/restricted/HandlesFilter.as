package potomac.restricted
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import potomac.bundle.IBundleService;
	import potomac.inject.InjectionEvent;
	
	
	[ExtensionPoint(id="Handles",declaredOn="methods",access="public",
					source="string",event="*string")]
	[ExtensionPointDetails(id="Handles",description="Wires the tagged method as a listener of the specified event")]
	[ExtensionPointDetails(id="Handles",attribute="source",description="Source event dispatcher (parent class assumed if not specified)",order="0",common="false")]
	[ExtensionPointDetails(id="Handles",attribute="event",description="Event name to listen for",order="1")]
	
	[InjectionListener]
	/**
	 * @private
	 */	
	public class HandlesFilter extends EventDispatcher
	{
		private var _bundleService:IBundleService;
		
		[Inject]
		public function HandlesFilter(bundleSrv:IBundleService)
		{
			_bundleService = bundleSrv;
			addEventListener(InjectionEvent.POST_INJECTION,onInstanceReady);
		}
		
		public function onInstanceReady(event:InjectionEvent):void
		{
			hookListeners(event.instance,false);
		}
		
		private function hookListeners(injectee:Object,afterInitialize:Boolean):void
		{
			var className:String = getQualifiedClassName(injectee);
			while (className != null && className != "Object")
			{
				hookForClassName(injectee,afterInitialize,className);
				className = getQualifiedSuperclassName(getDefinitionByName(className));
			}
			
		}
		
		private function hookForClassName(injectee:Object, afterInitialize:Boolean, className:String):void
		{
			var handles:Array = _bundleService.getExtensions("Handles",className);
			for (var i:int = 0; i < handles.length; i++)
			{
				if (handles[i].source)
				{
					if (!injectee.hasOwnProperty(handles[i].source))
					{
						throw new Error("Handles extension cannot add listener because source: '" + handles[i].source + "' doesn't exist or is inaccessible (make sure its public).");
					}
					
					var source:Object = injectee[handles[i].source];
					
					if (source == null)
					{
						if (!afterInitialize && injectee is UIComponent)
						{
							injectee.addEventListener(FlexEvent.INITIALIZE,onInitialize,false,0,true);
						}
						else
						{
							throw new Error("Handles extension cannot add listener for '" + handles[i].source + "' because it is null after creation (and initialization in the case of UIComponents).");
						}
					}
					else
					{
						if (!(source is IEventDispatcher))
						{
							throw new Error("Handles extension cannot add listener because '" + handles[i].source + "' is not an IEventDispatcher.");
						}
						IEventDispatcher(source).addEventListener(handles[i].event,injectee[handles[i].method.name],false,0,true);
					}
				}
				else
				{
					if (!(injectee is IEventDispatcher))
					{
						throw new Error("Handles extension cannot add listener because " + className + " is not an IEventDispatcher.");
					}
					
					IEventDispatcher(injectee).addEventListener(handles[i].event,injectee[handles[i].method.name],false,0,true);
				}
			}
			
		}
		
		
		private function onInitialize(event:FlexEvent):void
		{
			var injectee:Object = event.target;
			injectee.removeEventListener(FlexEvent.INITIALIZE,onInitialize);
			hookListeners(injectee,true);			
		}
		
	}
}