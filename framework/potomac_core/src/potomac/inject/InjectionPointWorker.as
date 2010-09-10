package potomac.inject
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.FlexGlobals;
	
	import potomac.bundle.Extension;
	
	/**
	 * This class takes a set of injection points (i.e. [Inject] extensions)
	 * and gathers up all the instances necessary to satisfy that
	 * injection.
	 * 
	 * Just sort of an internal helper class.
	 */
	internal class InjectionPointWorker extends EventDispatcher
	{
		//This is a hashmap of injection points (the string name)
		//to either an Array (when the extensions are on methods)
		//or to objects (when the extensions are on variables)
		//The value is either an array of objects to match the method
		//args or just one object for hte value of the var
		private var data:Object = new Object();
		
		private var _injectionPoints:Object;
		private var _injector:Injector;
		
		private var _counter:int = 0;
		
		public function InjectionPointWorker(injector:Injector,injectionPoints:Object)
		{
			super();
			
			_injector = injector;
			_injectionPoints = injectionPoints;
		}
		
		public function start():void
		{			
			for (var injPointName:String in _injectionPoints)
			{
				if (_injectionPoints[injPointName].declaredOn == Extension.DECLAREDON_METHOD)
				{
					var argInstances:Array = new Array();
					data[injPointName] = argInstances;
					for (var j:int = 0; j < _injectionPoints[injPointName].method.arguments.length; j++)
					{
						argInstances.push(new Object()); //take up space
						
						var request:InjectionRequest = _injector.getInstance(_injectionPoints[injPointName].method.arguments[j].type,_injectionPoints[injPointName].method.arguments[j].metadata);
						request.injectionPoint = _injectionPoints[injPointName];
						request.argumentOrder = j;
						request.addEventListener(InjectionEvent.INSTANCE_READY,onInstanceReady);
						_counter++;
						FlexGlobals.topLevelApplication.callLater(request.start);
					}					
				}
				else if (_injectionPoints[injPointName].declaredOn == Extension.DECLAREDON_CONSTRUCTOR)
				{
					var argInstances:Array = new Array();
					data[injPointName] = argInstances;
					for (var j:int = 0; j < _injectionPoints[injPointName].constructor.arguments.length; j++)
					{
						argInstances.push(new Object()); //take up space
						
						var request:InjectionRequest = _injector.getInstance(_injectionPoints[injPointName].constructor.arguments[j].type,_injectionPoints[injPointName].constructor.arguments[j].metadata);
						request.injectionPoint = _injectionPoints[injPointName];
						request.injectionPointName = injPointName;
						request.argumentOrder = j;
						request.addEventListener(InjectionEvent.INSTANCE_READY,onInstanceReady);
						_counter++;
						FlexGlobals.topLevelApplication.callLater(request.start);
					}
				}
				else
				{
					data[injPointName] = new Object(); //just make it empty

					request = _injector.getInstance(_injectionPoints[injPointName].variable.type,_injectionPoints[injPointName].variable.metadata);
					request.injectionPoint = _injectionPoints[injPointName];
					request.addEventListener(InjectionEvent.INSTANCE_READY,onInstanceReady);
					_counter++;
					FlexGlobals.topLevelApplication.callLater(request.start);
				}
			}
			
			if (_counter == 0)
				dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function onInstanceReady(event:InjectionEvent):void
		{			
			var injectionPoint:Extension = event.currentTarget.injectionPoint as Extension;
			
			if (injectionPoint.declaredOn == Extension.DECLAREDON_METHOD)
			{
				var argInstances:Array = data[injectionPoint.method.name];
				argInstances.splice(event.currentTarget.argumentOrder,1,event.instance); //add instance to array
			}
			else if (injectionPoint.declaredOn == Extension.DECLAREDON_CONSTRUCTOR)
			{
				var argInstances:Array = data[event.currentTarget.injectionPointName];
				argInstances.splice(event.currentTarget.argumentOrder,1,event.instance); //add instance to array				
			}
			else
			{
				data[injectionPoint.variable.name] = event.instance;
			}
			
			
			_counter --;
			if (_counter == 0)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		public function getData():Object
		{
			return data;
		}
	}
}