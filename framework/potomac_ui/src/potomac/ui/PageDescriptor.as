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
	import potomac.bundle.Extension;
	

	/**
	 * A structure containing descriptive information about a Page.
	 */
	public class PageDescriptor
	{
		private var _id:String;
		private var _title:String;
		private var _icon:Class;
		private var _type:String;
		private var _extension:Extension
		
		/**
		 * Callers should not construct PageDescriptors.
		 */
		public function PageDescriptor(id:String,title:String,icon:Class,type:String,extension:Extension)
		{
			_id = id;
			_title = title;
			_icon = icon;
			_type = type;
			_extension = extension;
		}
		
		/**
		 * ID of the page.
		 */
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * The title of the page.
		 */
		public function get title():String
		{
			return _title;
		}
		
		/**
		 * The icon of the page.
		 */
		public function get icon():Class
		{
			return _icon;
		}
		
		/**
		 * The type of the page.
		 */
		public function get type():String
		{
			return _type;
		}
		
		/**
		 * The extension that declared this page.
		 */
		public function get extension():Extension
		{
			return _extension;
		}


	}
}