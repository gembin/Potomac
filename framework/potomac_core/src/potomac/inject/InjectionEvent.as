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
	
	import potomac.bundle.Extension;

	/**
	 * An event sent in response to an injection request.
	 */
	public class InjectionEvent extends Event
	{		
		/**
		* The InjectionEvent.POST_INJECTION constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>postInjection</code> event.
		*
		*  <p>The properties of the event object have the following values:</p>
	 	*  <table class="innertable">
		*     <tr><th>Property</th><th>Value</th></tr>
  	  	*     <tr><td><code>bubbles</code></td><td>false</td></tr>
     	*     <tr><td><code>cancelable</code></td><td>false</td></tr>
     	*     <tr><td><code>currentTarget</code></td><td>The Object that defines the 
  	   	*       event listener that handles the event. For example, if you use 
     	*       <code>myButton.addEventListener()</code> to register an event listener, 
     	*       myButton is the value of the <code>currentTarget</code>. </td></tr>
  	   	*     <tr><td><code>className</code></td><td>null</td></tr>
     	*     <tr><td><code>named</code></td><td>null</td></tr>
     	*     <tr><td><code>extension</code></td><td>null</td></tr>
     	*     <tr><td><code>instance</code></td><td>The object instance that was just injected into.</td></tr>
	 	*  </table>
		*
		* @eventType postInjection
		*/
		public static const POST_INJECTION:String = "postInjection";		
		
		/**
		* The InjectionEvent.INSTANCE_READY constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>instanceReady</code> event.
		*
		*  <p>The properties of the event object have the following values:</p>
	 	*  <table class="innertable">
		*     <tr><th>Property</th><th>Value</th></tr>
  	  	*     <tr><td><code>bubbles</code></td><td>false</td></tr>
     	*     <tr><td><code>cancelable</code></td><td>false</td></tr>
     	*     <tr><td><code>currentTarget</code></td><td>The Object that defines the 
  	   	*       event listener that handles the event. For example, if you use 
     	*       <code>myButton.addEventListener()</code> to register an event listener, 
     	*       myButton is the value of the <code>currentTarget</code>. </td></tr>
  	   	*     <tr><td><code>className</code></td><td>The className attribute of the injection binding.</td></tr>
     	*     <tr><td><code>named</code></td><td>The name attribute of the injection binding.</td></tr>
     	*     <tr><td><code>extension</code></td><td>The <code>Extension</code> instance from which this instance (only populated when Injector#getInstanceOfExtension is called).</td></tr>
     	*     <tr><td><code>instance</code></td><td>The object instance that was just created.</td></tr>
	 	*  </table>
		*
		* @eventType instanceReady
		*/
		public static const INSTANCE_READY:String = "instanceReady";
		
		/**
		 * The InjectionEvent.INJECTINTO_COMPLETE constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>injectIntoComplete</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the 
		 *       event listener that handles the event. For example, if you use 
		 *       <code>myButton.addEventListener()</code> to register an event listener, 
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>instance</code></td><td>The object whose injections were satisfied.</td></tr>
		 *  </table>
		 *
		 * @eventType injectIntoComplete
		 */
		public static const INJECTINTO_COMPLETE:String = "injectIntoComplete";
		
		private var _className:String;
		private var _named:String;
		private var _extension:Extension;
		private var _instance:Object;
		
		/**
		 * Callers should not create InjectionEvents.
		 */
		public function InjectionEvent(type:String,className:String,named:String,extension:Extension,instance:Object)
		{
			super(type);
			_instance = instance;
			_className = className;
			_extension = extension;
			_named = named;
		}
		
		/**
		 * The instance just created and/or injected into.
		 */
		public function get instance():Object
		{
			return _instance;
		}
		
		/**
		 * The class name (or interface name) of the injection binding.
		 */
		public function get className():String
		{
			return _className;
		}
		
		/**
		 * The named attribute of the extension binding.
		 */
		public function get named():String
		{
			return _named;
		}
		
		/**
		 * The extension instance used to create this instance (only populated when Injector#getInstanceOfExtension is called).
		 */
		public function get extension():Extension
		{
			return _extension;
		}
		
		override public function clone():Event
		{
			return new InjectionEvent(type,_className,_named,_extension,_instance);
		}
	}
}