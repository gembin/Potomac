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
	 * Constructor describes a constructor method where an extension was declared.
	 * 
	 * @author cgross
	 */	
	public class Constructor
	{
		private var _arguments:Array = new Array();
		
		/**
		 * Callers should not construct Constructors.  Instances should be retrieved via <code>Extension</code>s.
		 */		
		public function Constructor(functionSignature:String,extension:Extension)
		{
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
				
				if (arg == "")
				{
					continue;
				}
				
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
		 * The arguments of the constructor.
		 */		
		public function get arguments():Array
		{
			return _arguments;
		}

	}
}