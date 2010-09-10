/*******************************************************************************
 *  Copyright (c) 2010 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package potomac.core
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.System;
	import flash.utils.Dictionary;
	
	import potomac.inject.Injector;

	[Injectable(singleton="true")]
	/**
	 * The PotomacDispatcher along with the <code>[Handles]</code> tag is the backbone 
	 * of the Potomac messaging system.  
	 * <p>
	 * PotomacDispatcher manages two types of messaging.  The first is the standard event
	 * dispatching available in Flash/Flex (and comes through via the EventDispatcher base class).
	 * The second is a leaner messaging system that doesn't require event classes.  This system is
	 * available via the #addListener and #dispatch methods.  The PotomacDispatcher calls the 
	 * listeners with the arguments passed to the #dispatch.  Therefore it is expected that the
	 * signature of the listener method match the arguments passed to #dispatch.  It is important
	 * to note that this requirement means that adding a new field to the message requires an update to the 
	 * function signature of the listener method (where as with the event-based pattern new fields 
	 * can be added to the event without impacting the listener methods).  Thus this technique creates a 
	 * slightly more brittle API.
	 * </p><p>
	 * Clients may inject the PotomacDispatcher and call methods on it directly.  Alternatively, if a 
	 * class is only required to listen for an event it may use the <code>[Handles]</code> tag with the
	 * attribute <code>global="true"</code> and Potomac will wire the event listener automatically. 
	 * </p><p>
	 * The PotomacDispatcher only uses weak references.
	 * </p>
	 */
	public class PotomacDispatcher extends EventDispatcher
	{
		
		/**
		 * Returns the global PotomacDispatcher instance.  
		 * <p>
		 * This method goes against the design of dependency injection itself but is made available for
		 * pragmatic reasons.  Internally, this method calls the global Injector to get the global 
		 * PotomacDispatcher instance and so this method is not considered harmful.
		 * </p> 
		 */
		public static function getInstance():PotomacDispatcher
		{
			return Injector.getInstance().getInstanceImmediate(PotomacDispatcher) as PotomacDispatcher;
		}
		

		
		//URRRRGGGG: https://bugs.adobe.com/jira/browse/FP-840
		
		//important to have weak keys
		/**
		 * listening objects => Object with keys as method names => Object with keys as event names => priority
		 * 
		 * The keys in the dictionary are the listening objects.
		 * The values are Objects (associative arrays) with keys
		 * of the names of the listener methods and the values of 
		 * those keys being an array of types of events that method is listening to. 
		 * UPDATE:  the string in the array is now appended with the priority ("*" + priority)
		 */
		private var listeners:Dictionary = new Dictionary(true);

		/**
		 * PotomacDispatcher should not be instantiated by clients.  It is available for 
		 * injection instead. 
		 */
		public function PotomacDispatcher()
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			//force weak references
			super.addEventListener(type,listener,useCapture,priority,true);
		}
		
		/**
		 * Dispatches a message of the given type to all listeners, passing the given arguments.
		 * 
		 * @param type message type.
		 * @param args arguments to pass to the listener methods.
		 */
		public function dispatch(type:String, ... args):void
		{
			if (type == null)
				throw new ArgumentError("type must not be null.");
			
			if (args.length == 1 && args[0] is Event)
				throw new ArgumentError("Call dispatchEvent() when using Flash events.");
			
			var toDispatch:Array = new Array();
			for (var listenerObject:Object in listeners)
			{
				var data:Object = listeners[listenerObject];
				for (var methodName:String in data)
				{
					var types:Object = data[methodName];
					if (types[type] != undefined)
					{
						toDispatch.push({'listenerObject':listenerObject,'method':listenerObject[methodName],'priority': types[type] });
						
					}
				}
			}
			
			toDispatch.sortOn('priority',Array.DESCENDING | Array.NUMERIC);
			for (var i:int = 0; i < toDispatch.length; i++)
			{
				toDispatch[i].method.apply(toDispatch[i].listenerObject,args);
			}
		}

		/**
		 * Adds a message listener listening to messages of the given type.
		 * <p>
		 * Due to a bug in the Flash Player (https://bugs.adobe.com/jira/browse/FP-840),
		 * Potomac is unable to provide a method signature similar to #addEventListener.
		 * PotomacDispatcher uses weak references only by design.  This particular bug 
		 * prevents any Actionscript code from maintaining a weak reference to any 
		 * Function.  In order to provide the same functionality and maintain only a 
		 * weak reference (an absolute requirement), Potomac requires a reference to the 
		 * listening method's parent object and the name of the listening method.  
		 * (Basically we're saying this weird API isn't our fault ;)
		 * </p>
		 * @param type message type to listen for.
		 * @param listenerObject Object containing the message listening function.
		 * @param listenerName Name of the message listening function.
		 * 
		 */
		public function addListener(type:String,listenerObject:Object,listenerName:String,priority:int=0):void
		{	
			if (type == null)
				throw new ArgumentError("type must not be null.");
			if (listenerObject == null)
				throw new ArgumentError("listenerObject must not be null.");
			if (listenerName == null || listenerName.length == 0)
				throw new ArgumentError("listenerName must not be null.");
			
			
			var data:Object;
			if (listeners[listenerObject] != undefined)
			{
				data = listeners[listenerObject];
			}
			else
			{
				data = new Object();
				listeners[listenerObject] = data;
			}
			
			var types:Object;
			if (data[listenerName] != undefined)
			{
				types = data[listenerName];
			}
			else
			{
				types = new Object();
				data[listenerName] = types;
			}
			
			types[type] = priority;
		}
		
		/**
		 * Removes the given message listener.  
		 * 
		 * @param type message type.
		 * @param listenerObject Object containing the message listening function.
		 * @param listenerName Name of the message listening function.
		 * 
		 */
		public function removeListener(type:String,listenerObject:Object,listenerName:String):void
		{
			if (type == null)
				throw new ArgumentError("type must not be null.");
			if (listenerObject == null)
				throw new ArgumentError("listenerObject must not be null.");
			if (listenerName == null || listenerName.length == 0)
				throw new ArgumentError("listenerName must not be null.");
			
			
			if (listeners[listenerObject] != undefined)
			{
				var data:Object = listeners[listenerObject];
				if (data[listenerName] != undefined)
				{
					var types:Object = data[listenerName];
					if (types[type])
					{
						delete types[type];
						var count:int = 0;
						for (var i:String in types)
						{
							count ++;
						}
						if (count == 0)
						{
							delete data[listenerName];
							for (i in data)
							{
								count ++;
							}
							if (count == 0)
								delete listeners[listenerObject];
						}
						
					}
				}
			}
		}


		//overriding these just so they'll appear more obviously in the asdoc
		
		override public function dispatchEvent(event:Event):Boolean
		{
			//TODO Auto-generated method stub
			return super.dispatchEvent(event);
		}

		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			//TODO Auto-generated method stub
			super.removeEventListener(type,listener,useCapture);
		}

		
	}
}