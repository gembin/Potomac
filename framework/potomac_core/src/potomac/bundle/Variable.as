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
	/**
	 * Variable represents a variable on which an extension was declared.
	 * 
	 * @author cgross
	 */	
	public class Variable
	{
		private var _name:String;
		private var _type:String;
		private var _metadata:String;
		
		/**
		 * Callers should not construct Variable instances.  They are available via <code>Extension</code>.
		 */		
		public function Variable(name:String,type:String,metadata:String)
		{
			_name = name;
			_type = type;
			_metadata = metadata;
		}
		
		/**
		 * The name of the variable.
		 */		
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * The fully qualified datatype of the variable.
		 */		
		public function get type():String
		{
			return _type;
		}
		
		/**
		 * The metadata string associated with the variable.
		 */		
		public function get metadata():String
		{
			return _metadata;
		}

	}
}