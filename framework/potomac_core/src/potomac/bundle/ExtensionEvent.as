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
package potomac.bundle
{
	import flash.events.Event;
	
	/**
	 * ExtensionEvent is an event sent in response to changes in the extensions registry.
	 *  
	 * @author cgross
	 */	
	public class ExtensionEvent extends Event
	{
		/**
		* The ExtensionEvent.EXTENSIONS_UPDATED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>extensionsUpdated</code> event.
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
  	   	*     <tr><td><code>extensionsAdded</code></td><td>Array of Extensions added to the registry.</td></tr>
     	*     <tr><td><code>extensionsRemoved</code></td><td>Array of Extensions removed from the registry.</td></tr>
	 	*  </table>
		*
		* @eventType bundlesInstalled
		*/
		public static const EXTENSIONS_UPDATED:String = "extensionsUpdated";
	
		private var _extensionsAdded:Array;
		
		private var _extensionsRemoved:Array;

		/**
		 * Callers should not construct instances of ExtensionEvent.
		 */
		public function ExtensionEvent(type:String,extensionsAdded:Array,extensionsRemoved:Array)
		{
			super(type);
			_extensionsAdded = extensionsAdded;
			_extensionsRemoved = extensionsRemoved;
		}
		
		/**
		 * An array of <code>Extension</code>s that were added to the registry.
		 */		
		public function get extensionsAdded():Array
		{
			return _extensionsAdded;
		}

		/**
		 * An array of <code>Extension</code>s that were removed from the registry.
		 */	
		public function get extensionsRemoved():Array
		{
			return _extensionsRemoved;
		}
		
		
		override public function clone():Event
		{
			return new ExtensionEvent(type,_extensionsAdded,_extensionsRemoved);
		}

	}
}