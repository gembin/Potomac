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
	import mx.core.Container;
	
	/**
	 * A reference to a part in a folder.  The part may or may not be created and its bundle may not yet be loaded.  Potomac will attempt to 
	 * load bundles and create parts only when required.  Thus a part can be open (for example, you can see the part's tab) but the part
	 * itself, and potentially its bundle, have yet to be loaded.  When the user selects the part's tab (or whatever folder UI mechanism is being
	 * used), Potomac will load any necessary bundles and create the part control.
	 */
	public class PartReference
	{
		private var _id:String;
		private var _input:PartInput;
		private var _control:Container;
		
		//warn that public shouldnt create these
		/**
		 * Callers should not construct PartReference instances.  PartReferences should be 
		 * retreived via Folders.
		 */
		public function PartReference(id:String,input:PartInput,control:Container)
		{
			_id = id;
			_input = input;
			_control = control;
		}
		
		/**
		 * The id of the part.
		 */
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * The part's input (potentially null).
		 */
		public function get input():PartInput
		{
			return _input;
		}
		
		/**
		 * The part's control or null if the part is not yet created.
		 */
		public function get control():Container
		{
			return _control;
		}
		
		public function set control(control:Container):void
		{
			_control = control;
		}
		
		/**
		 * Returns true if the given reference matches this one.
		 * 
		 * @param otherRef other reference to match.
		 * @return true if they match, false otherwise.
		 * 
		 */
		public function equals(otherRef:PartReference):Boolean
		{
			if (_control != null)
			{
				return (_control == otherRef.control);
			}
			
			if (_id == otherRef.id)
			{
				if (_input == null)
				{
					return (otherRef.input == null);
				}
				else
				{
					return _input.equals(otherRef.input);
				}
			}
			return false;
		}

	}
}