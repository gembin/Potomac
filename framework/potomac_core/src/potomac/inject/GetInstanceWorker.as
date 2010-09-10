package potomac.inject
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.ArrayUtil;
	
	import potomac.bundle.BundleEvent;
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;

	internal class GetInstanceWorker extends EventDispatcher
	{
		private var _className:String;
		private var _named:String;
		private var _injector:Injector;
		private var _bundleSrv:IBundleService;
		private var _injectable:Injectable;
		
		private var _waitingForBundles:Array = new Array();
		
		private var PHASE_START:int = 0;
		private var PHASE_INJECTABLEBUNDLELOADING:int = 1;
		private var PHASE_REFERENCEDBUNDLESLOADING:int = 2;
		private var PHASE_EXTENSIONBUNDLELOADING:int = 3;
		
		private var _phase:int = PHASE_START;
		
		private var _extension:Extension;

		private var _obj:Object;

		public function GetInstanceWorker(bundleSrv:IBundleService,injector:Injector,className:String,named:String,extension:Extension)
		{
			_className = className;
			_named = named;
			_injector = injector;
			_bundleSrv = bundleSrv;
			_extension = extension;
		}
		
		/**
		 * Starts the injection process.   
		 */
		public function start():void
		{	
			_bundleSrv.addEventListener(BundleEvent.BUNDLE_READY,bundleLoaded);
			
			if (_extension == null)
			{	
				//find injectable
				_injectable = _injector.getInjectable(_className,_named);
				
				if (_injectable != null)
				{
					if (_injectable.bundle != null && !_bundleSrv.isBundleLoaded(_injectable.bundle))
					{
						_phase = PHASE_INJECTABLEBUNDLELOADING;
						_waitingForBundles.push(_injectable.bundle);
						_bundleSrv.loadBundle(_injectable.bundle);
					}
					else
					{
						afterInjectableBundleLoaded();
					}
				}
				else
				{
					//if we find no injectable we must create it w/o it
					//but this only works if the class is currently in the classloader
					doGetReferencesAndLoad(_className);			
				}
			}
			else
			{
				_phase = PHASE_EXTENSIONBUNDLELOADING;
				_waitingForBundles.push(_extension.bundleID);
				_bundleSrv.loadBundle(_extension.bundleID);
			}
		}
		
		private function bundleLoaded(e:BundleEvent):void
		{
			var index:int = ArrayUtil.getItemIndex(e.bundleID,_waitingForBundles);
			if (index != -1)
			{
				_waitingForBundles.splice(index,1);
				
				if (_waitingForBundles.length == 0)
				{
					if (_phase == PHASE_INJECTABLEBUNDLELOADING)
					{
						afterInjectableBundleLoaded();
					}
					else if (_phase == PHASE_REFERENCEDBUNDLESLOADING)
					{
						afterReferencedBundlesLoaded();
					}
					else if (_phase == PHASE_EXTENSIONBUNDLELOADING)
					{
						afterExtensionBundleLoaded();
					}
				}
			}
		}
		
		private function doGetReferencesAndLoad(className:String):void
		{
			try{
				var clazz:Class = getDefinitionByName(className) as Class;
			} catch (e:ReferenceError)
			{
				throw new Error("Unable to load " + className + ".  Either the class is mispelled, a required bundle is not yet loaded, or the class is an interface class and the injector found no injectables to satisfy it.");
			}				
			
			_injector.fillReferencedBundles(clazz,_waitingForBundles);
			_phase = PHASE_REFERENCEDBUNDLESLOADING;
			
			var loading:Boolean = false;
			
			for (var i:int = 0; i < _waitingForBundles.length; i++)
			{
				if (!_bundleSrv.isBundleLoaded(_waitingForBundles[i]))
				{
					loading = true;
					_bundleSrv.loadBundle(_waitingForBundles[i]);
				}
				else
				{
					//this else statement should fix the 'bundle never loads'
					//problem when injecting an injectable from a bundle thats
					//not already loaded
					_waitingForBundles.splice(i,1);
					i--;
				}
			}
			if (!loading)
			{
				afterReferencedBundlesLoaded();
			}
		}
		
		private function afterExtensionBundleLoaded():void
		{
			doGetReferencesAndLoad(_extension.className);
		}
		
		private function afterInjectableBundleLoaded():void
		{
			var className:String = _injectable.getImplementingClassName();
			if (className == null)
				throw new Error("Unexpected null when retrieving implementing class name from '" + _injectable.boundTo + "' injectable.");
			doGetReferencesAndLoad(className);
		}
		
		private function afterReferencedBundlesLoaded():void
		{
			if (_extension != null)
			{
				_className = _extension.className;
			}
			_bundleSrv.removeEventListener(BundleEvent.BUNDLE_READY,bundleLoaded);
			
						
			var obj:Object;
			if (_injectable != null)
			{
				_injectable.addEventListener(InitializedEvent.INJECTABLE_INITIALIZED,injectableCreated);
				_injectable.requestAysncInstance(_injector);

			}
			else
			{
				var createWorker:CreationWorker = new CreationWorker(_injector,_className);
				createWorker.addEventListener(Event.COMPLETE,createWorker_complete);
				createWorker.start();
			}	
		}

		private function createWorker_complete(event:Event):void
		{
			CreationWorker(event.currentTarget).removeEventListener(Event.COMPLETE,createWorker_complete);
			_obj = event.currentTarget.instance;
			doInjectInto();
		}


		private function injectableCreated(event:InitializedEvent):void
		{
			_obj = _injectable.getAsyncInstance();
			if (_obj == null)
				return;  //this means someone else took the instance before us, we need to wait in line for the next instance
			
			_injectable.removeEventListener(InitializedEvent.INJECTABLE_INITIALIZED,injectableCreated);
			doInjectInto();
		}
		
		private function doInjectInto():void
		{
			if (_injectable == null || (_injectable != null && _injectable.needsInjection()))
			{
				_injector.injectIntoAsync(_obj,injectIntoComplete);
			}
			else
			{
				var injEvent:InjectionEvent = new InjectionEvent(InjectionEvent.INSTANCE_READY,_className,_named,_extension,_obj);
				dispatchEvent(injEvent);
			}	
		}
			
		private function injectIntoComplete(event:InjectionEvent):void
		{			
			var injEvent:InjectionEvent = new InjectionEvent(InjectionEvent.INSTANCE_READY,_className,_named,_extension,event.instance);
			dispatchEvent(injEvent);
		}
	}
}