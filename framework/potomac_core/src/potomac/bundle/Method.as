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
	 * Method represents a method on which an extension was declared.
	 * 
	 * @author cgross
	 */	
	public class Method
	{
		private var _name:String;
		private var _arguments:Array = new Array();
		private var _returnType:String;
		
		/**
		 * Callers should not construct Method instances.  They are available via <code>Extension</code>.
		 */		
		public function Method(name:String,functionSignature:String,extension:Extension)
		{
			_name = name;

			_returnType = functionSignature.substr(functionSignature.lastIndexOf(":") + 1);
			
			var args:String = functionSignature.substring(1,functionSignature.indexOf(")"));
			var argsArray:Array = args.split(",");
			var varName:String;
			var varType:String;
			var hasDefault:Boolean;
			var metadata:String;

			for (var i:int = 0; i < argsArray.length; i++)
			{
				varName = "";
				varType = "";
				hasDefault = false;
				metadata = null;
				
				var arg:String = argsArray[i];
				
				varName = arg.substring(0,arg.indexOf(":"));
				varType = arg.substring(arg.indexOf(":") +1);
				if (varType.indexOf("=") > 0)
				{
					varType = varType.substring(0,varType.indexOf("="));
					hasDefault = true;
				}
				
				if (extension.hasOwnProperty(varName))
				{
					metadata = extension[varName];
				}				
				
				var argument:Argument = new Argument(varName,varType,hasDefault,metadata);
				_arguments.push(argument);	
			}
		}
		
		/**
		 * The method name.
		 */		
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * The arguments in the method signature.
		 */		
		public function get arguments():Array
		{
			return _arguments;
		}
		
		/**
		 * The fully qualified return type of the method.
		 */		
		public function get returnType():String
		{
			return _returnType;
		}	

	}
}