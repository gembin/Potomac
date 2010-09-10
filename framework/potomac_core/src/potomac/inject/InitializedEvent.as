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
package potomac.inject
{
	import flash.events.Event;
	
	/**
	 * An InitializedEvent is dispatched by an [Injectable] which requires asynchronous initialization
	 * to inform the Potomac injection system that it's initialization is complete. 
	 */
	public class InitializedEvent extends Event
	{
		/**
		 * The InitializedEvent.INJECTABLE_INITIALIZED constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>injectableInitialized</code> event.
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
		 *  </table>
		 *
		 * @eventType injectableInitialized
		 */
		public static const INJECTABLE_INITIALIZED:String = "injectableInitialized";
		
		/**
		 * Constructs an InitializedEvent.
		 */
		public function InitializedEvent(type:String)
		{
			super(type);
		}
	}
}