package potomac.restricted
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.core.PotomacDispatcher;
	import potomac.inject.InjectionEvent;
	
	
	[ExtensionPoint(id="Handles",declaredOn="methods",access="public",
					source="string",event="*string",global="boolean",
					priority="integer")]
	[ExtensionPointDetails(id="Handles",description="Wires the tagged method as a listener of the specified event")]
	[ExtensionPointDetails(id="Handles",attribute="source",description="Source event dispatcher (parent class assumed if not specified)",order="0",common="false")]
	[ExtensionPointDetails(id="Handles",attribute="event",description="Event name to listen for",order="1")]
	[ExtensionPointDetails(id="Handles",attribute="priority",description="Priority level of the handler method",order="2",defaultValue="0")]
	[ExtensionPointDetails(id="Handles",attribute="global",description="If true, attaches a listener to the global PotomacDispatcher",order="3",defaultValue="false")]
	
	[InjectionListener]
	/**
	 * @private
	 */	
	public class HandlesFilter extends EventDispatcher
	{
		private var _bundleService:IBundleService;
		private var _potomacDispatcher:PotomacDispatcher;
		private var _awaitingInitialization:Dictionary = new Dictionary();
		
		[Inject]
		public function HandlesFilter(bundleSrv:IBundleService,potomacDispatcher:PotomacDispatcher)
		{
			_bundleService = bundleSrv;
			_potomacDispatcher = potomacDispatcher;
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
				var priority:int = 0;
				if (handles[i].priority != undefined)
					priority = handles[i].priority;
				
				if (handles[i].global != undefined && handles[i].global == true)
				{
					var isEventHandler:Boolean = false;
					if (Extension(handles[i]).method.arguments.length == 1)
					{
						var argType:String = Extension(handles[i]).method.arguments[0].type;
						var argClz:Class = getDefinitionByName(argType) as Class;
						isEventHandler = (argClz is Event);
					}
					
					
					
					if (isEventHandler)
					{
						var listener:Function = injectee[handles[i].method.name] as Function;
						_potomacDispatcher.addEventListener(handles[i].event,listener,false,priority,true);
					}
					else
					{
						_potomacDispatcher.addListener(handles[i].event,injectee,handles[i].method.name,priority);	
					}
				}
				else
				{
					if (handles[i].source != undefined)
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
								var handlesExts:Array;
								if (_awaitingInitialization[injectee] != undefined)
								{
									handlesExts = _awaitingInitialization[injectee];	
								}
								else
								{
									handlesExts = new Array();
									_awaitingInitialization[injectee] = handlesExts
								}
								handlesExts.push(handles[i]);
								injectee.addEventListener(FlexEvent.INITIALIZE,onInitialize,false,priority,true);
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
							IEventDispatcher(source).addEventListener(handles[i].event,injectee[handles[i].method.name],false,priority,true);
						}
					}
					else
					{
						if (!(injectee is IEventDispatcher))
						{
							throw new Error("Handles extension cannot add listener because " + className + " is not an IEventDispatcher.");
						}
						
						IEventDispatcher(injectee).addEventListener(handles[i].event,injectee[handles[i].method.name],false,priority,true);
					}
				}
			}
			
		}
		
		
		private function onInitialize(event:FlexEvent):void
		{
			var injectee:IEventDispatcher = event.target as IEventDispatcher;
			
			injectee.removeEventListener(FlexEvent.INITIALIZE,onInitialize,false);
			
			var handles:Array = _awaitingInitialization[injectee];
			
			for (var i:int = 0; i < handles.length; i++)
			{
				var source:Object = injectee[handles[i].source];
				
				var priority:int = 0;
				if (handles[i].priority != undefined)
					priority = handles[i].priority;
				
				IEventDispatcher(source).addEventListener(handles[i].event,injectee[handles[i].method.name],false,priority,true);
			}
			
			delete _awaitingInitialization[injectee];
		}
		
	}
}