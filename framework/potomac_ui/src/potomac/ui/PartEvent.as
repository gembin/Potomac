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
	
	import mx.core.Container;

	/**
	 * PartEvents are the main mechanism of communication between Parts and the Potomac User Interface.  Some 
	 * part events are sent from Potomac to parts and some are sent from parts to Potomac.  In both cases, the PartEvents
	 * are dispatched on the parts themselves.  
	 * <p>
	 * Part developers may construct PartEvent instances or use one of the convenient static send* methods.
	 */
	public class PartEvent extends Event
	{
		/**
		* The PartEvent.INITIALIZE constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partInitialize</code> event.
		* <p>
		* Initialize events are dispatched on parts to give them a chance to 
		* inspect their input and retrieve data.
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
  	   	*     <tr><td><code>input</code></td><td>The part input or null if no input was given.</td></tr>
     	*     <tr><td><code>folder</code></td><td>The part's parent folder.</td></tr>
     	*    <tr><td><code>page</code></td><td>The part's parent page.</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>The part's parent page's input.</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partInitialize
		*/
		public static const INITIALIZE:String = "partInitialize";
		/**
		* The PartEvent.DIRTY constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partDirty</code> event.
		 * <p>
		 * Dirty events are dispatched by parts to tell Potomac that the part
		 * has unsaved changes.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partDirty
		*/
		public static const DIRTY:String = "partDirty";
		/**
		* The PartEvent.CLEAN constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partClean</code> event.
		 * <p>
		 * Clean events are dispatched by parts to tell Potomac that the part no longer
		 * has unsaved changes.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partClean
		*/
		public static const CLEAN:String = "partClean";
		/**
		* The PartEvent.BUSY constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partBusy</code> event.
		 * <p>
		 * Busy events are dispatched by parts to tell Potomac that the part is performing a long running activity,
		 * typically awaiting the results of a service call.  Potomac will disable the part and show an animation.  
		 * Parts can affect the text shown during this animation with the busyText property.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>The text to be shown on the busy animation.</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partBusy
		*/
		public static const BUSY:String = "partBusy"
		/**
		* The PartEvent.IDLE constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partIdle</code> event.
		 * <p>
		 * Idle events are dispatched by parts to tell Potomac that the part is no longer
		 * performing a long running activity.  If the part was busy, the busy animation 
		 * will be stopped and the part will be re-enabled.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partIdle
		*/
		public static const IDLE:String = "partIdle";
		/**
		* The PartEvent.SELECTION_CHANGED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partSelectionChangeIncoming</code> event.
		 * <p>
		 * Selection changed events are dispatched by parts to inform Potomac that the
		 * selection in this part has changed.  Potomac will in turn dispatch a SelectionEvent.SELECTION_CHANGED 
		 * event to all parts.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>An array of objects representing the new selection in the part.</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partSelectionChangeIncoming
		*/
		public static const SELECTION_CHANGED:String = "partSelectionChangeIncoming";
		/**
		* The PartEvent.BROADCAST_TO_PARTS constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partBroadcastToParts</code> event.
		 * <p>
		 * A broadcast event is a mechanism by which parts can have an event dispatched on 
		 * all currently open parts.  This is a useful inter-part communication mechanism.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>The event that will be broadcast to all parts.</td></tr>
	 	*  </table>
		*
		* @eventType partBroadcastToParts
		*/
		public static const BROADCAST_TO_PARTS:String = "partBroadcastToParts";
		
		/**
		* The PartEvent.DO_SAVE constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partDoSave</code> event.
		*<p>
		 * Do Save events are dispatched by Potomac to parts when the user has requested the 
		 * part's data be saved.  Parts are expected to initiate (asynchronous) save logic and send back a 
		 * PartEvent.SAVE_COMPLETE or PartEvent.SAVE_ERROR event.
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partDoSave
		*/
		public static const DO_SAVE:String = "partDoSave";
		/**
		* The PartEvent.SAVE_COMPLETE constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partSaveComplete</code> event.
		*<p>
		 * Save complete events are dispatched by parts to inform Potomac that an
		 * asynchronous save was successful.  
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partSaveComplete
		*/
		public static const SAVE_COMPLETE:String = "partSaveComplete";
		/**
		* The PartEvent.SAVE_ERROR constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partSaveError</code> event.
		* <p>
		 * Save error events are dispatched by parts to Potomac when asynchronous 
		 * save logic failed.  Parts are expected to show the necessary UI to communicate
		 * the error to the user.  
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
  	   	*     <tr><td><code>input</code></td><td>null</td></tr>
     	*     <tr><td><code>folder</code></td><td>null</td></tr>
     	*    <tr><td><code>page</code></td><td>null</td></tr>
   		*    <tr><td><code>pageInput</code></td><td>null</td></tr>
     	*    <tr><td><code>selection</code></td><td>null</td></tr>
     	*    <tr><td><code>busyText</code></td><td>null</td></tr>
     	*    <tr><td><code>eventToBroadcast</code></td><td>null</td></tr>
	 	*  </table>
		*
		* @eventType partSaveError
		*/
		public static const SAVE_ERROR:String = "partSaveError";
		
		//only populated on initialize
		private var _input:PartInput;
		private var _folder:Folder;
		private var _page:Page;
		private var _pageInput:PageInput
		
		//only populated on selection changed
		private var _selection:Array;
		
		//only for busy event
		private var _busyText:String;
	
		//only for broadcast event		
		private var _eventToBroadcast:Event;
	
				
		/**
		 * Parts are encouraged to use one of the static send* methods rather than constructing the event manually.
		 * 
		 * @param type event type.
		 * @param selection new selection for a SELECTION_CHANGED event.
		 * @param input input for an INITIALIZE event.
		 * @param folder folder for an INITIALIZE event.
		 * @param page page for an INITIALIZE event.
		 * @param pageInput pageInput for an INITIALIZE event.
		 * 
		 */
		public function PartEvent(type:String,selection:Array=null,input:PartInput=null,folder:Folder=null,page:Page=null,pageInput:PageInput=null)
		{
			super(type);
			_input=input;
			_folder=folder;
			_selection = selection
			_page = page;
			_pageInput = pageInput;
			_busyText = busyText;
		}
		
		/**
		 * Sends an event to inform Potomac that the part is busy.  Potomac will disable the part and show an 
		 * animation with the given text.
		 * 
		 * @param part part to mark busy.
		 * @param busyText text to show in busy animation.
		 * 
		 */
		public static function sendBusy(part:Container,busyText:String):void
		{
			var e:PartEvent = new PartEvent(BUSY);
			e.busyText = busyText;
			part.dispatchEvent(e);			
		}
		
		/**
		 * Sends an event to inform Potomac that the part is no longer busy.  If the part was busy, it will be re-enabled
		 * and the animation will be stopped.
		 * 
		 * @param part part to mark idle.
		 * 
		 */
		public static function sendIdle(part:Container):void
		{
			part.dispatchEvent(new PartEvent(IDLE));
		}
		
		/**
		 * Sends an event to inform Potomac to in turn dispatch the given event on all parts. 
		 * 
		 * @param part part doing the broadcasting.
		 * @param eventToBroadcast event to broadcast to all parts.
		 * 
		 */
		public static function sendBroadcast(part:Container,eventToBroadcast:Event):void
		{
			var e:PartEvent = new PartEvent(BROADCAST_TO_PARTS);
			e.eventToBroadcast = eventToBroadcast;
			part.dispatchEvent(e);
		}
		
		/**
		 * Sends an event informing Potomac that the given part is now dirty.
		 * 
		 * @param part part to mark dirty.
		 * 
		 */
		public static function sendDirty(part:Container):void
		{
			part.dispatchEvent(new PartEvent(DIRTY));
		}
		
		/**
		 * Sends an event informing Potomac that the given part is now clean.
		 * 
		 * @param part part to mark clean.
		 * 
		 */
		public static function sendClean(part:Container):void
		{
			part.dispatchEvent(new PartEvent(CLEAN));
		}
		
		/**
		 * Sends an event informing Potomac that the selection of the given part has changed.  Potomac will
		 * then dispatch a SelectionEvent.SELECTION_CHANGED event on all parts.
		 * 
		 * @param part part whose selection has changed.
		 * @param newSelection the new selection.
		 * 
		 */
		public static function sendSelectionChanged(part:Container,newSelection:Array):void
		{
			part.dispatchEvent(new PartEvent(SELECTION_CHANGED,newSelection));
		}
		
		/**
		 * Sends an event informing Potomac that the save on the given part was successful.
		 * 
		 * @param part part which saved successfully.
		 * 
		 */
		public static function sendSaveComplete(part:Container):void
		{
			part.dispatchEvent(new PartEvent(SAVE_COMPLETE));
		}
		
		/**
		 * Sends an event informing Potomac that the save on the given part did not complete as it 
		 * encountered an error.  Parts are expected to display the error themselves.
		 * 
		 * @param part part for which the save failed.
		 * 
		 */
		public static function sendSaveError(part:Container):void
		{
			part.dispatchEvent(new PartEvent(SAVE_ERROR));
		}
		
		/**
		 * The text to be shown on the busy animation.
		 */
		public function get busyText():String
		{
			return _busyText;
		}
		
		public function set busyText(busyText:String):void
		{
			_busyText = busyText;
		}

		/**
		 * The parent folder of the part.
		 */
		public function get folder():Folder
		{
			return _folder;
		}
		/**
		 * The part's input.
		 */
		public function get input():PartInput
		{
			return _input;
		}
		/**
		 * The new selection on a SELECTION_CHANGED event.
		 */
		public function get selection():Array
		{
			return _selection;
		}
		
		/**
		 * The part's parent page.
		 */
		public function get page():Page
		{
			return _page;
		}
		
		/**
		 * The part's parent page's input.
		 */
		public function get pageInput():PageInput
		{
			return _pageInput;
		}
		
		/**
		 * The event to broadcast for a BROADCAST_TO_PARTS event.
		 */
		public function get eventToBroadcast():Event
		{
			return _eventToBroadcast;
		}
		
		public function set eventToBroadcast(event:Event):void
		{
			_eventToBroadcast = event;
		}
		
		override public function clone():Event
		{
			var e:PartEvent = new PartEvent(type,_selection,_input,_folder,_page,_pageInput);
			e.busyText = _busyText;
			e.eventToBroadcast = _eventToBroadcast;
			return e;
		}
	}
}