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
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/**
	 * BundleEvent represents events in response to bundle activities on the <code>BundleService</code>.
	 * 
	 * @author cgross
	 */	
	public class BundleEvent extends Event
	{
		/**
		 * The BundleEvent.BUNDLES_INSTALLING constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>bundlesInstalling</code> event.
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
		 *     <tr><td><code>url</code></td><td>null</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
		 *  </table>
		 *
		 * @eventType bundlesInstalling
		 */
		public static const BUNDLES_INSTALLING:String = "bundlesInstalling";

		/**
		 * The BundleEvent.BUNDLES_PRELOADING constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>bundlesPreloading</code> event.
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
		 *     <tr><td><code>url</code></td><td>null</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
		 *  </table>
		 *
		 * @eventType bundlesPreloading
		 */
		public static const BUNDLES_PRELOADING:String = "bundlesPreloading";
		
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
		*     <tr><td><code>url</code></td><td>null</td></tr>
		*     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		*     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		*     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
	 	*  </table>
		*
		* @eventType bundlesInstalled
		*/
		public static const BUNDLES_INSTALLED:String = "bundlesInstalled";
		
		/**
		* The BundleEvent.BUNDLE_READY constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>bundleReady</code> event.
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
		*     <tr><td><code>url</code></td><td>null</td></tr>
		*     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		*     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		*     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
	 	*  </table>
		*
		* @eventType bundleReady
		*/
		public static const BUNDLE_READY:String = "bundleReady";
	
		/**
		 * The BundleEvent.BUNDLE_PROGRESS constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>bundleProgress</code> event.
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
		 *     <tr><td><code>bundleID</code></td><td>The id of the bundle this progress event is associated with.</td></tr>
		 *     <tr><td><code>isRepeat</code></td><td>false</td></tr>
		 *     <tr><td><code>url</code></td><td>URL of the asset or SWF being downloaded.</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>The current bytes loaded.</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>Total bytes of downloading asset or SWF.</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
		 *  </table>
		 *
		 * @eventType bundleProgress
		 */
		public static const BUNDLE_PROGRESS:String = "bundleProgress";
		
		/**
		 * The BundleEvent.BUNDLE_LOADING constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>bundleLoading</code> event.
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
		 *     <tr><td><code>bundleID</code></td><td>The id of the bundle that is now loading.</td></tr>
		 *     <tr><td><code>isRepeat</code></td><td>false</td></tr>
		 *     <tr><td><code>url</code></td><td>URL of the bundle SWF.</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
		 *  </table>
		 *
		 * @eventType bundleLoading
		 */
		public static const BUNDLE_LOADING:String = "bundleLoading";
		
		/**
		 * The BundleEvent.BUNDLE_ERROR constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>bundleError</code> event.
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
		 *     <tr><td><code>bundleID</code></td><td>The id of the bundle this error event is associated with.</td></tr>
		 *     <tr><td><code>isRepeat</code></td><td>false</td></tr>
		 *     <tr><td><code>url</code></td><td>null</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>The error message.</td></tr>
		 *     <tr><td><code>loader</code></td><td>null</td></tr>
		 *     <tr><td><code>request</code></td><td>null</td></tr> 
		 *  </table>
		 *
		 * @eventType bundleError
		 */
		public static const BUNDLE_ERROR:String = "bundleError";
		
		/**
		 * The BundleEvent.PREDOWNLOAD constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>predownload</code> event.
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
		 *     <tr><td><code>bundleID</code></td><td>The id of the bundle who's file is being downloaded.</td></tr>
		 *     <tr><td><code>isRepeat</code></td><td>false</td></tr>
		 *     <tr><td><code>url</code></td><td>URL of the file being downloaded.</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>URLLoader of the download.</td></tr>
		 *     <tr><td><code>request</code></td><td>Populated URLRequest of the download.</td></tr> 
		 *  </table>
		 *
		 * @eventType predownload
		 */
		public static const PREDOWNLOAD:String = "predownload";
		
		/**
		 * The BundleEvent.POSTDOWNLOAD constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>postdownload</code> event.
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
		 *     <tr><td><code>bundleID</code></td><td>The id of the bundle who's file is being downloaded.</td></tr>
		 *     <tr><td><code>isRepeat</code></td><td>false</td></tr>
		 *     <tr><td><code>url</code></td><td>URL of the file being downloaded.</td></tr>
		 *     <tr><td><code>bytesLoaded</code></td><td>0</td></tr>
		 *     <tr><td><code>bytesTotal</code></td><td>0</td></tr>
		 *     <tr><td><code>message</code></td><td>null</td></tr>
		 *     <tr><td><code>loader</code></td><td>URLLoader of the download.</td></tr>
		 *     <tr><td><code>request</code></td><td>Populated URLRequest of the download.</td></tr> 
		 *  </table>
		 *
		 * @eventType postdownload
		 */
		public static const POSTDOWNLOAD:String = "postdownload";
		
		private var _bundleID:String;
		private var _repeat:Boolean; //means the event is a repeat
		private var _url:String;//url only for progress event
		private var _bytesLoaded:uint;
		private var _bytesTotal:uint;
		private var _message:String;
		private var _loader:URLLoader;
		private var _request:URLRequest;
		
		
		/**
		 * Callers should not construct instances of BundleEvent.
		 */		
		public function BundleEvent(type:String,bundleID:String=null,repeat:Boolean=false,url:String=null,bytesLoaded:uint=0,bytesTotal:uint=0,message:String=null,loader:URLLoader=null,request:URLRequest=null)
		{
			super(type);
			_bundleID=bundleID;
			_repeat = repeat;
			_url = url;
			_bytesLoaded = bytesLoaded;
			_bytesTotal = bytesTotal;
			_message = message;
			_loader = loader;
			_request = request;
		}
		

		/**
		 * The URL being downloaded during a progress event. 
		 */
		public function get url():String
		{
			return _url;
		}

		/**
		 * The number of bytes currently loaded during a progress event.
		 */
		public function get bytesLoaded():uint
		{
			return _bytesLoaded;
		}

		/**
		 * The total bytes in the downloading file during a progress event.
		 */
		public function get bytesTotal():uint
		{
			return _bytesTotal;
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
		 * The message associated with an error event or null.
		 */
		public function get message():String 
		{
			return _message;
		}

		/**
		 * The URLLoader associated with a download event.
		 */
		public function get loader():URLLoader
		{
			return _loader;
		}
		
		/**
		 * The URLRequest associated with a download event.
		 */
		public function get request():URLRequest
		{
			return _request;
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Event
		{
			return new BundleEvent(type,_bundleID,_repeat,_url,_bytesLoaded,_bytesTotal,_message);
		}





	}
}