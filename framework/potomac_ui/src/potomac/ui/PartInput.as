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
	/**
	 * A PartInput is a lightweight argument passed to a part.  For most parts, the 
	 * input is typically null, but when multiple instances of a given part are required
	 * an input should be used.  Inputs differentiate the different instances.  For example,
	 * if a part works on an 'Employee' object, the input might contain the employee ID.  
	 * <p>
	 * Inputs should not contain full model elements.  Instead they should maintain as little
	 * information as possible to allow the model to be retrieved.  This typically means the input
	 * should contain primary key information only.  Inputs will be serialized and stored between
	 * application sessions.  They will be deserialized and recreated in order to the user to shown
	 * the same parts that were shown during his last application session.</p>
	 * <p>
	 * PartInput is a dynamic object.  Developers are encouraged to write their own subclasses of 
	 * PartInput but it isn't required.  Dynamic properties can be attached to a PartInput.  Integer and String
	 * dynamic properties will be automatically serialized and checked during #equals.  Subclasses must 
	 * re-implement #equals().
	 * </p>
	 * @author cgross
	 */	
	public dynamic class PartInput
	{
		private var _title:String;
		private var _icon:Class;
		
		/**
		 * Creates an empty part input.
		 * 
		 */
		public function PartInput()
		{
		}

		/**
		 * Returns true if the given input matches this input.  This method is used to prevent duplicate parts in the same folder
		 * from opening.  If a part with same id and matching input is already open, an attempt to open a the new page will result
		 * in the existing part being made visible (ex. its tab will be selected).
		 *  
		 * @param otherInput input to check for equality.
		 * @return true if the inputs are matching.
		 * 
		 */
		public function equals(otherInput:PartInput):Boolean
		{
			if (otherInput == null)
				return false;
			for (var prop:Object in this)
			{
			    if (this[prop] != otherInput[prop])
			    {
			    	return false;
			    }
			}
			return true;
		}
		
		/**
		 * The title of the input.  Setting this title will override the title set in the part's declared extension.  This is useful when you
		 * have multiple instances of a part and need to allow the user to differentiate between them. 
		 */
		public function get title():String
		{
			return _title;
		}
		
		/**
		 * The icon of the input. Setting this icon will override the icon set in the part's declared extension.
		 */
		public function get icon():Class
		{
			return _icon;
		}

		public function set title(title:String):void
		{
			_title = title;
		}
		
		public function set icon(icon:Class):void
		{
			_icon = icon;
		}
	}
}