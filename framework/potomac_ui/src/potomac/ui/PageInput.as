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
	 * A PageInput is a lightweight argument passed to a Page.  For most pages, the 
	 * input is typically null, but when multiple instances of a given page are required
	 * an input should be used.  Inputs differentiate the different instances.  For example,
	 * if a page works on an 'Employee' object, the input might contain the employee ID.  
	 * <p>
	 * Inputs should not contain full model elements.  Instead they should maintain as little
	 * information as possible to allow the model to be retrieved.  This typically means the input
	 * should contain primary key information only.  Inputs will be serialized and stored between
	 * application sessions.  They will be deserialized and recreated in order to the user to shown
	 * the same pages that were shown during his last application session.
	 * <p>
	 * PageInput is a dynamic object.  Developers are encouraged to write their own subclasses of 
	 * PageInput but it isn't required.  Dynamic properties can be attached to a PageInput.  Integer and String
	 * dynamic properties will be automatically serialized and checked during #equals.  Subclasses must 
	 * re-implement #equals().
	 * 
	 * @author cgross
	 */
	public dynamic class PageInput
	{
		private var _title:String;
		private var _icon:Class;
		
		
		/**
		 * Creates an empty input. 
		 * 
		 */
		public function PageInput()
		{
		}

		/**
		 * Returns true if the given input matches this input.  This method is used to prevent duplicate pages from opening.  If
		 * a page with same id and matching input is already open, an attempt to open a the new page will result in the existing page
		 * receiving focus.
		 *  
		 * @param otherInput input to check for equality.
		 * @return true if the inputs are matching.
		 * 
		 */
		public function equals(otherInput:PageInput):Boolean
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
		 * The title of the input.  Setting this title will override the title set in the page's declared extension.  This is useful when you
		 * have multiple instances of a page and need to allow the user to differentiate between them. 
		 */
		public function get title():String
		{
			return _title;
		}
		
		/**
		 * The icon of the input. Setting this icon will override the icon set in the page's declared extension.
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