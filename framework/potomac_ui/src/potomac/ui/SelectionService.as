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
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	[Injectable(singleton="true")]
	/**
	 * The SelectionService allows parts to retrieve the selection for a given part.  For as-they-happen updates to 
	 * part selection, parts should listen to SelectionEvent.SELECTION_CHANGED.  All parts receive all 
	 * SelectionEvent.SELECTION_CHANGED events as they happen.  
	 */
	public class SelectionService extends EventDispatcher
	{
		//parts to arrays
		private var _selections:Dictionary = new Dictionary(true);
		
		/**
		 * Callers should not construct SelectionService instances.  SelectionService is available for injection.
		 */
		public function SelectionService()
		{
		}
		

		/**
		 * Returns the selection for the given part.  Potomac will ensure the
		 * selection is never null.  In cases where the selection was set to null, 
		 * Potomac will reset the selection to an empty array.
		 * 
		 * @param partRef part to get the selection for.
		 * @return the part's selection.
		 * 
		 */
		public function getSelection(partRef:PartReference):Array
		{
			if (!_selections[partRef]) 
				return new Array();
			return _selections[partRef];
		}
		
		/**
		 * @private
		 */
		public function setSelection(partRef:PartReference,selection:Array):SelectionEvent
		{
			_selections[partRef] = selection;
			var event:SelectionEvent = new SelectionEvent(SelectionEvent.SELECTION_CHANGED,partRef,selection);
			dispatchEvent(event);
			return event;
		}

	}
}