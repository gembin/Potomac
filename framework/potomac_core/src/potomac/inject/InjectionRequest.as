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
	* Dispatched when the injection creation request is complete.
	*
	* @eventType potomac.inject.InjectionEvent.INJECTION_READY
	*/
	[Event(name="instanceReady", type="potomac.inject.InjectionEvent")]

	/**
	 * Dispatched when a injection into request is complete.
	 * 
	 * @eventType potomac.inject.InjectionEvent.INJECTINTO_COMPLETE
	 */	
	[Event(name="injectIntoComplete",type="potomac.inject.InjectionEvent")]
	
	/**
	 * An injection request represent the asynchronous process necessary for the 
	 * creation and injection of objects in the Potomac bundle system.
	 * <p>
	 * When the request is complete, one of either InjectionEvent.INSTANCE_READY 
	 * or InjectionEvent.INJECTINTO_COMPLETE will be dispatched appropriate to the 
	 * request.
	 * </p>
	 */
	public dynamic class InjectionRequest extends EventDispatcher
	{
		private var _injector:Injector;
		
		private var _getInstanceWorker:GetInstanceWorker;
		private var _injectIntoWorker:InjectIntoWorker;
		
		private var _listeners:Array = new Array();
				
		/**
		 * Callers should not construct InjectionRequests.  InjectionRequests are handed out by the Injector.
		 */
		public function InjectionRequest(injector:Injector,getInstanceWorker:GetInstanceWorker,injectIntoWorker:InjectIntoWorker)
		{		
			_injector = injector;
			//we only expect one of these at a time
			_getInstanceWorker = getInstanceWorker;
			_injectIntoWorker = injectIntoWorker;
		}
		
		
		/**
		 * @private
		 */
		internal static function requestGetInstance(bundleSrv:IBundleService,injector:Injector,className:String,named:String,extension:Extension):InjectionRequest
		{
			var worker:GetInstanceWorker = new GetInstanceWorker(bundleSrv,injector,className,named,extension);
			var request:InjectionRequest = new InjectionRequest(injector,worker,null);
			
			return request;
		}
		
		/**
		 * @private
		 */
		internal static function requestInjectInto(injector:Injector,object:Object):InjectionRequest
		{
			var worker:InjectIntoWorker = new InjectIntoWorker(injector,object);
			var request:InjectionRequest = new InjectionRequest(injector,null,worker);
			
			return request;
		}

		
		/**
		 * Starts the injection process (either instance creation and injection or injection only).   
		 */
		public function start():void
		{	
			if (_getInstanceWorker != null)
			{
				_getInstanceWorker.addEventListener(InjectionEvent.INSTANCE_READY,instanceReady);
				_getInstanceWorker.start();
			}
			else if (_injectIntoWorker != null)
			{
				_injectIntoWorker.addEventListener(InjectionEvent.INJECTINTO_COMPLETE,injectIntoComplete);
				_injectIntoWorker.start();
			}

		}

		private function injectIntoComplete(event:InjectionEvent):void
		{	
			_injectIntoWorker.removeEventListener(InjectionEvent.INJECTINTO_COMPLETE,injectIntoComplete);
			
			var postInjectEvent:InjectionEvent = new InjectionEvent(InjectionEvent.POST_INJECTION,null,null,null,event.instance);
			_injector.sendPostInjectionEvent(postInjectEvent);
			
			dispatchEvent(event.clone());
			removeAllListeners();
		}

		private function instanceReady(event:InjectionEvent):void
		{
			_getInstanceWorker.removeEventListener(InjectionEvent.INSTANCE_READY,instanceReady);
			dispatchEvent(event.clone());
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
		
		/**
		 * @private
		 */
		internal function removeAllListeners():void
		{
			var toRemove:Array = new Array().concat(_listeners);
			for (var i:int = 0; i < toRemove.length; i ++)
			{
				removeEventListener(InjectionEvent.INSTANCE_READY,toRemove[i]);
			}
		}
	}
}