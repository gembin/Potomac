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
	 * Argument describes a method or constructor argument associated with an extension
	 * declaration.
	 * 
	 * @author cgross 
	 */	
	public class Argument
	{
		private var _name:String;
		private var _type:String;
		private var _hasDefault:Boolean;
		private var _metadata:String;
		
		/**
		 * Callers should not construct Argument instances.  They should be retrieved via Extension. 
		 */		
		public function Argument(name:String,type:String,hasDefault:Boolean,metadata:String)
		{
			_name = name;
			_type = type;
			_hasDefault = hasDefault;
			_metadata = metadata;
		}
		
		/**
		 * The name of the argument. 
		 */		
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * The fully qualified datatype of the argument.
		 */		
		public function get type():String
		{
			return _type;
		}
		
		/**
		 * True if the argument was provided a default value in the method signature.
		 */		
		public function get hasDefault():Boolean
		{
			return _hasDefault;
		}
		
		/**
		 *  The metadata string associated with this argument.
		 */		
		public function get metadata():String
		{
			return _metadata;
		}

	}
}