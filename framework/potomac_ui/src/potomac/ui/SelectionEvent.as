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
	 * SelectionEvents are dispatched in response to selection changes in parts.  Selection tracking is 
	 * used when parts change their content based on the selection in other parts.  
	 */
	public class SelectionEvent extends Event
	{
		/**
		* The SelectionEvent.SELECTION_CHANGED constant defines the value of the 
		* <code>type</code> property of the event object 
		* for a <code>partSelectionChanged</code> event.
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
  	   	*     <tr><td><code>partReference</code></td><td>The reference of the part whose changed.</td></tr>
     	*     <tr><td><code>selection</code></td><td>The part's new selection.</td></tr>
	 	*  </table>
		*
		* @eventType partSelectionChanged
		*/
		public static const SELECTION_CHANGED:String = "partSelectionChanged";
	
		private var _partRef:PartReference;
		private var _selection:Array;
		
		/**
		 * Callers should not create SelectionEvent instances.
		 */
		public function SelectionEvent(type:String, partRef:PartReference,selection:Array)
		{
			super(type);
			_selection = selection;
			_partRef = partRef;
		}
		
		/**
		 * The reference to the part whose selection changed.
		 */
		public function get partReference():PartReference
		{
			return _partRef;
		}
		
		/**
		 * The new selection.  Potomac ensures the selection is never null.  If the 
		 * selection is empty, or if the part set its selection to null, Potomac 
		 * will set the selection to an empty array.
		 */
		public function get selection():Array
		{
			return _selection;
		}
		
		override public function clone():Event
		{
			return new SelectionEvent(type,_partRef,_selection);
		}
		
	}
}