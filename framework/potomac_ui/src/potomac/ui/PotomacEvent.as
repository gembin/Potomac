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
package potomac.ui
{
	import flash.events.Event;
	
	/**
	 * Potomac events are dispatched when high-level UI actions occur.
	 */
	public class PotomacEvent extends Event
	{
		/**
		* The PotomacEvent.PART_SAVED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPartSaved</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>A reference to the saved part.</td></tr>
     	*     <tr><td><code>page</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType potomacPartSaved
		*/
		public static const PART_SAVED:String = "potomacPartSaved";
		/**
		* The PotomacEvent.PART_CLOSED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPartClosed</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>A reference to the closed part.</td></tr>
     	*     <tr><td><code>page</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType potomacPartClosed
		*/
		public static const PART_CLOSED:String = "potomacPartClosed";
		/**
		* The PotomacEvent.PART_SAVE_ERROR constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPartSaveError</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>A reference to the part in which the save failed.</td></tr>
     	*     <tr><td><code>page</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType potomacPartSaveError
		*/
		public static const PART_SAVE_ERROR:String = "potomacPartSaveError";
		
		/**
		* The PotomacEvent.PART_DIRTY_CHANGE constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPartDirtyChange</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>A reference to the part in which the dirty state changed.</td></tr>
     	*     <tr><td><code>page</code></td><td>The page which contains the part whose dirty state changed.</td></tr>
	 	*  </table>
		*
		* @eventType potomacPartDirtyChange
		*/
		public static const PART_DIRTY_CHANGE:String = "potomacPartDirtyChange";
		
		/**
		* The PotomacEvent.PAGE_SAVED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPageSaved</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>null</td></tr>
     	*     <tr><td><code>page</code></td><td>The page which was saved.</td></tr>
	 	*  </table>
		*
		* @eventType potomacPageSaved
		*/
		public static const PAGE_SAVED:String = "potomacPageSaved";
		/**
		* The PotomacEvent.PAGE_CLOSED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPageClosed</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>null</td></tr>
     	*     <tr><td><code>page</code></td><td>The page which was closed.</td></tr>
	 	*  </table>
		*
		* @eventType potomacPageClosed
		*/
		public static const PAGE_CLOSED:String = "potomacPageClosed";
		/**
		* The PotomacEvent.PAGE_SAVE_ERROR constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>potomacPageSaveError</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>null</td></tr>
     	*     <tr><td><code>page</code></td><td>The page in which one or more parts failed saving.</td></tr>
	 	*  </table>
		*
		* @eventType potomacPageSaveError
		*/
		public static const PAGE_SAVE_ERROR:String = "potomacPageSaveError";
		
		private var _partRef:PartReference;
		private var _page:Page;
		
		/**
		 * Callers should not construct PotomacEvents.
		 */
		public function PotomacEvent(type:String,partRef:PartReference,page:Page)
		{
			super(type);
			_partRef = partRef;
			_page = page;
		}
		
		/**
		 * The relevant part reference.
		 */
		public function get partReference():PartReference
		{
			return _partRef;
		}
		
		/**
		 * The relevant page.
		 */
		public function get page():Page
		{
			return _page;
		}

	}
}