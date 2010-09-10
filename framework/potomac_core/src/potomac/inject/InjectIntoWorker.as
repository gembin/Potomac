package potomac.inject
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import potomac.bundle.Argument;
	import potomac.bundle.Extension;
	
	
	internal class InjectIntoWorker extends EventDispatcher
	{
	  
		private var _injector:Injector;
		private var _object:Object;

		private var _injectPointWorker:InjectionPointWorker;
		private var _injectionPoints:Object;
		
		public function InjectIntoWorker(injector:Injector,object:Object)
		{
			_injector = injector;
			_object = object;
		}
		
		public function start():void
		{
			_injectionPoints = new Object();
			_injector.fillInjectionPoints(getDefinitionByName(getQualifiedClassName(_object)) as Class,_injectionPoints);
			
			_injectPointWorker = new InjectionPointWorker(_injector,_injectionPoints);
			_injectPointWorker.addEventListener(Event.COMPLETE,injectPointWorker_complete);
			_injectPointWorker.start();
		}

		/**
		 * This handler is called when the InjectPointWorker is complete which means
		 * he's gathered up all the objects necessary to inject into _object.
		 * 
		 * All thats left is to loop through them and do the actual injection.
		 */
		private function injectPointWorker_complete(event:Event):void
		{
			var data:Object = _injectPointWorker.getData();
			
			for (var injPointName:String in data)
			{
				var injectionPoint:Extension = _injectionPoints[injPointName];
				if (injectionPoint.declaredOn == Extension.DECLAREDON_METHOD)
				{
					var argObjects:Array = data[injPointName];
					_object[injPointName].apply(_object,argObjects);
				}
				else
				{
					_object[injPointName] = data[injPointName];
				}
			}
			done();
		}
		
		private function done():void
		{
			
			var postEvent:InjectionEvent = new InjectionEvent(InjectionEvent.POST_INJECTION,null,null,null,_object);
			_injector.sendPostInjectionEvent(postEvent);	
	
			//dispatchevent
			var injEvent:InjectionEvent = new InjectionEvent(InjectionEvent.INJECTINTO_COMPLETE,null,null,null,_object);
			dispatchEvent(injEvent);
		}
	}
}