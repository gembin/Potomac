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
package potomac.inject
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getQualifiedClassName;
	
	internal class Injectable extends EventDispatcher
	{
		private const SINGLETON_NOT_CREATED:int = 0;
		private const SINGLETON_CREATING:int = 1;
		private const SINGLETON_CREATED:int = 2;		
		
		private var _boundTo:String;
		private var _implementedBy:String;
		private var _named:String;
		private var _providedBy:String;
		private var _providerInstance:IProvider;
		private var _singleton:Boolean;
		private var _asyncInit:Boolean;
		
		private var _bundle:String;
		
		private var _singleInstance:Object = null;
		//tells the injector not to re-inject into singleton instances
		private var _needsInjection:Boolean = true;
		
		private var _asyncCompleteQueue:Array = new Array();
		private var _singletonState:int = SINGLETON_NOT_CREATED;
		
		public function Injectable(bundle:String,boundTo:String,implementedBy:String=null,named:String=null,singleton:Boolean=false,providedBy:String=null,asyncInit:Boolean=false)
		{
			_bundle = bundle;
			_boundTo = boundTo;
			_implementedBy = implementedBy;
			_named = named;
			_singleton = singleton;
			_providedBy = providedBy;	
			_asyncInit = asyncInit;
		}
		
		public function get boundTo():String
		{
			return _boundTo;
		}
		
		public function get named():String
		{
			return _named;
		}
		
		public function get bundle():String
		{
			return _bundle;
		}
		
		public function get implementedBy():String
		{
			return _implementedBy;
		}
		
		public function set implementedBy(val:String):void
		{
			_implementedBy = val;
		}
		
		public function set named(val:String):void
		{
			_named = val;
		}
		
		public function set providedBy(val:String):void
		{
			_providedBy = val;
		}
		public function set providerInstance(val:IProvider):void
		{
			_providerInstance = val;
		}
		
		public function get asyncInit():Boolean
		{
			return _asyncInit;
		}

		public function set instance(val:Object):void
		{
			_singleton = true;
			_singleInstance = val;
			_singletonState = SINGLETON_CREATED;
		}
		
		public function set asSingleton(val:Boolean):void
		{
			_singleton = val;
		}
		
		internal function matches(className:String,isNamed:String):Boolean
		{
			if (_boundTo != className)
				return false;
				
			if (isNamed == null && _named == null)
				return true;
				
			return isNamed == _named;
		}
		
		internal function needsInjection():Boolean
		{
			return _needsInjection;
		}
		
		
		internal function requestAysncInstance(injector:Injector):void
		{
			var o:Object = null;
			
			if (_singleton && _singletonState == SINGLETON_CREATING)
			{
				return;
			}
			else if (_singleton && _singletonState == SINGLETON_CREATED)
			{
				_needsInjection = false;
				o = _singleton;
				asyncDone(o);
			}
			else
			{
				if (_singleton)
					_singletonState = SINGLETON_CREATING;
				
				var createWorker:CreationWorker = null;
				
				if (_providedBy != null)
				{
					var provider:IProvider = _providerInstance;
					if (provider == null)
					{
						injector.getInstance(_providedBy,null,providerCreated);
						return;
					}
					o = provider.getInstance();	
					doInitialization(o);
					return;
				}
				else if (_implementedBy != null)
				{
					createWorker = new CreationWorker(injector,_implementedBy);
				} 
				else
				{
					createWorker = new CreationWorker(injector,_boundTo);			
				}
				
				createWorker.addEventListener(Event.COMPLETE,createWorker_complete);
				createWorker.start();
			}
			
		}

		private function providerCreated(event:InjectionEvent):void
		{
			_providerInstance = event.instance as IProvider;
			var o:Object = _providerInstance.getInstance();
			doInitialization(o);
		}			
		
		private function createWorker_complete(event:Event):void
		{
			var o:Object = event.currentTarget.instance;
			doInitialization(o);
		}
		
		private function doInitialization(o:Object):void
		{
			if (_singleton)  //save singleton object
			{
				if (_singleInstance !== null)
				{
					throw new Error("Un expected condition!  Singleton injectable instance already set.");
				}
				_singleInstance = o;
			}
			
			if (asyncInit)
			{
				if (!(o is IEventDispatcher))
					throw new Error("[Injectable]s with asynchronous initialization must extend/implement IEventDispatcher.  Class '" + getQualifiedClassName(o) + "' does not.");
				
				var dispatcher:IEventDispatcher = o as IEventDispatcher;			
				dispatcher.addEventListener(InitializedEvent.INJECTABLE_INITIALIZED,injectableInitialized);				
			}
			else
			{
				asyncDone(o);
			}			
		}

		
		
		private function injectableInitialized(event:InitializedEvent):void
		{
			var o:Object = event.target;
			
			asyncDone(o);
		}
		
		private function asyncDone(o:Object):void
		{
			_singletonState = SINGLETON_CREATED;  //just always set this (doesn't matter if its not a singleton just wont be read)
				
			if (!_singleton)
				_asyncCompleteQueue.push(o);
			
			//we're reusing this event here cause it's not really necessary to create another one just for our internal
			dispatchEvent(new InitializedEvent(InitializedEvent.INJECTABLE_INITIALIZED));
		}
		
		
		/**
		 * Returns an instance that was asynchronously initialized or null if no instance is available.
		 */
		internal function getAsyncInstance():Object
		{
			if (!_singleton)
			{
				if (_asyncCompleteQueue.length == 0)
					return null;
				
				var o:Object = _asyncCompleteQueue[0];
				_asyncCompleteQueue.splice(0,1);
				return o;
			}
			else
			{
				if (_singletonState == SINGLETON_CREATED)
					return _singleInstance;
				
				return null;
			}
		}
		

		
		//assumes all necessary bundles are loaded
		internal function getInstanceSync(injector:Injector):Object
		{
			if (_singleton && _singleInstance != null)
			{
				_needsInjection = false;
				return _singleInstance;
			}
			
			var obj:Object;
			
			if (_providedBy != null)
			{
				var provider:IProvider = _providerInstance;
				if (provider == null)
				{
					provider = injector.doCreationSync(_providedBy) as IProvider;
					injector.injectInto(provider);
				}
				obj = provider.getInstance();			
			}
			else if (_implementedBy != null)
			{
				obj = injector.doCreationSync(_implementedBy);
			} 
			else
			{
				obj = injector.doCreationSync(_boundTo);				
			}
			
			if (_singleton)
			{
				_singleInstance = obj;
			}
			
			return obj;
		}

		
		internal function getImplementingClassName():String
		{
			if (_implementedBy != null)
				return _implementedBy;
			
			if (_singleInstance != null)
				return getQualifiedClassName(_singleInstance);
			
			return null;
		}
	}
}