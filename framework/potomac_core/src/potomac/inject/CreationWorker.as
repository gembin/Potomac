package potomac.inject
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.getClassByAlias;
	import flash.utils.getDefinitionByName;
	
	import potomac.bundle.Extension;
	
	internal class CreationWorker extends EventDispatcher
	{
		private var _injector:Injector;
		private var _className:String;
		private var _unQualifiedClassName:String;
		private var _instance:Object;
		
		public function CreationWorker(injector:Injector, className:String)
		{
			this._injector = injector;  
			this._className = className;  
			
			var className:String = _className;
			if (className.indexOf(".") > -1)
				className = className.substring(className.lastIndexOf(".")+1);
			if (className.indexOf(":") > -1)
				className = className.substring(className.lastIndexOf(":")+1);
			_unQualifiedClassName = className;
			
			super();
		}
		
		public function start():void
		{
			try{
				var clazz:Class = getDefinitionByName(_className) as Class;
			} catch (e:ReferenceError)
			{
				throw new Error("Unable to load " + _className + ".  Ensure the class is included in the project's build path.");
			}
			
			var constructorExt:Extension = _injector.getConstructorInjectionPoint(_className);
			
			if (constructorExt != null)
			{
				var injPoints:Object = new Object();
				injPoints[_unQualifiedClassName] = constructorExt;
				var injectPointWorker:InjectionPointWorker = new InjectionPointWorker(_injector,injPoints);
				injectPointWorker.addEventListener(Event.COMPLETE,injectPointWorker_complete);
				injectPointWorker.start();
			}
			else
			{
				_instance = new clazz();
				//todo: catch here throw better error
				
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}

		private function injectPointWorker_complete(event:Event):void
		{
			var clazz:Class = getDefinitionByName(_className) as Class;
			
			var data:Object = event.currentTarget.getData();
			var args:Array = data[_unQualifiedClassName];
			
			_instance = _injector.doBigNasty(clazz,args);
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		
		public function get instance():Object
		{
			return _instance;
		}


	}
}