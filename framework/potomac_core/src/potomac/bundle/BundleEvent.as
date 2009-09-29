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
	 * BundleEvent represents events in response to bundle activities on the <code>BundleService</code>.
	 * 
	 * @author cgross
	 */	
	public class BundleEvent extends Event
	{
		/**
		* The BundleEvent.BUNDLES_INSTALLED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>bundlesInstalled</code> event.
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
  	   	*     <tr><td><code>bundleID</code></td><td>null</td></tr>
     	*     <tr><td><code>isRepeat</code></td><td>false</td></tr>
	 	*  </table>
		*
		* @eventType bundlesInstalled
		*/
		public static const BUNDLES_INSTALLED:String = "bundlesInstalled";
		
		/**
		* The BundleEvent.BUNDLE_READY constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>bundlesInstalled</code> event.
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
  	   	*     <tr><td><code>bundleID</code></td><td>The id of the loaded bundle.</td></tr>
     	*     <tr><td><code>isRepeat</code></td><td>True if this is a repeated ready event.</td></tr>
	 	*  </table>
		*
		* @eventType bundleReady
		*/
		public static const BUNDLE_READY:String = "bundleReady";
	
		private var _bundleID:String;
		private var _repeat:Boolean; //means the event is a repeat
		
		/**
		 * Callers should not construct instances of BundleEvent.
		 */		
		public function BundleEvent(type:String,bundleID:String=null,repeat:Boolean=false)
		{
			super(type);
			_bundleID=bundleID;
			_repeat = repeat;
		}
		
		/**
		 * The bundle ID relevant to the event.
		 */		
		public function get bundleID():String
		{
			return _bundleID;
		}
		
		/**
		 * True if this event is a repeat event.  The BundleService dispatches a <code>bundleReady</code>
		 * whenever a bundle load is requested, even when the bundle is already loaded.  This allows callers
		 * to code one logic path in both cases where the bundle is loaded or not.  This property will be set
		 * to true if the bundle has already been loaded. 
		 */		
		public function get isRepeat():Boolean
		{
			return _repeat;
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Event
		{
			return new BundleEvent(type,_bundleID,_repeat);
		}

	}
}