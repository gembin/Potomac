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
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	
	import mx.utils.ArrayUtil;
	
	import potomac.bundle.BundleEvent;
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	
	/**
	* Dispatched when the injection request is complete.
	*
	* @eventType potomac.inject.InjectionEvent.INJECTION_READY
	*/
	[Event(name="instanceReady", type="potomac.inject.InjectionEvent")]

	
	/**
	 * An injection request represent the asynchronous process necessary for the 
	 * creation and injection of objects in the Potomac bundle system.
	 */
	public dynamic class InjectionRequest extends EventDispatcher
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
		
		private var _listeners:Array = new Array();
				
		/**
		 * Callers should not construct InjectionRequests.  InjectionRequests are handed out by the Injector.
		 */
		public function InjectionRequest(bundleSrv:IBundleService,injector:Injector,className:String,named:String,extension:Extension)
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
			doGetReferencesAndLoad(_injectable.implementedBy);
		}
		
		private function afterReferencedBundlesLoaded():void
		{
			var className:String = _className;
			if (_extension != null)
			{
				className = _extension.className;
			}
			_bundleSrv.removeEventListener(BundleEvent.BUNDLE_READY,bundleLoaded);
						
			var obj:Object = _injector.getInstanceImmediateByName(className,_named);
			
			var injEvent:InjectionEvent = new InjectionEvent(InjectionEvent.INSTANCE_READY,className,_named,_extension,obj);
			dispatchEvent(injEvent);
			
			removeAllListeners();
		}
		
		/**
		 * @private
		 */
		override public function addEventListener(type:String,listener:Function,useCapture:Boolean=false,priority:int=0,useWeakReference:Boolean=false):void
		{			
			super.addEventListener(type,listener,useCapture,priority,useWeakReference);
			_listeners.push(listener);
		}
		
		/**
		 * @private
		 */
		override public function removeEventListener(type:String,listener:Function,useCapture:Boolean = false):void
		{
			super.removeEventListener(type,listener,useCapture);
			_listeners.splice(_listeners.indexOf(listener),1);
		}
		
		private function removeAllListeners():void
		{
			var toRemove:Array = new Array().concat(_listeners);
			for (var i:int = 0; i < toRemove.length; i ++)
			{
				removeEventListener(InjectionEvent.INSTANCE_READY,toRemove[i]);
			}
		}
	}
}