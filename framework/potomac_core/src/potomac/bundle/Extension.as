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
	import flash.utils.getDefinitionByName;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	/**
	 * Extension describes an instance of a metadata extension declared within a 
	 * class.  Extension is a dynamic class and contains dynamic properties that map
	 * to the attributes of the extension.  For example, if the extension declaration 
	 * contains a <code>name</code> property, then the matching Extension instance will
	 * contain a dynamic property <code>name</code>.  The datatype of the dynamic properties
	 * is either boolean, integer, or string as declared by the extension point.  For 
	 * attributes marked as <code>asset</code> types, the property's datatype is either 
	 * <code>Class</code> (which contains the embeded resource) or, in cases where the bundle 
	 * wasn't known during compilation, the property will be a string containing the full
	 * URL to the resource.
	 * 
	 * @author cgross
	 */	
	public dynamic class Extension
	{
		public static var DECLAREDON_CLASS:int = 1;
		public static var DECLAREDON_CONSTRUCTOR:int = 2;
		public static var DECLAREDON_METHOD:int = 3;
		public static var DECLAREDON_VARIABLE:int = 4;
		
		private var _id:String;
		private var _className:String;
		private var _functionName:String;
		private var _variableName:String;
		private var _bundleID:String;
		private var _pointID:String;
		private var _functionSignature:String;
		private var _variableType:String;
		
		private var _method:Method = null;
		private var _constructor:Constructor = null;
		private var _variable:Variable = null;
		
		private static var logger:ILogger = Log.getLogger("potomac.bundle.Extension");
		
		/**
		 * Callers should not construct instances of Extension.  Extensions can be retrieved via <code>BundleService</code>.
		 */		
		public function Extension(extension:XML,extensionPoint:ExtensionPoint,baseURL:String)
		{
			this._bundleID = extension.attribute("bundle").toString();
			this._className = extension.attribute("class").toString();
			this._pointID = extension.attribute("point").toString();
			
			if (extension.hasOwnProperty("@function"))
			{
				_functionName = extension.attribute("function").toString();
				_functionSignature = extension.attribute("functionSignature").toString();
			}
			if (extension.hasOwnProperty("@variable"))
			{
				_variableName = extension.attribute("variable").toString();
				_variableType = extension.attribute("variableType").toString();
			}
			
			if (extension.hasOwnProperty("@id"))
			{
				_id = extension.attribute("id").toString();
			}

			var extensionAssets:Object;
			
			var attribs:XMLList = extension.@*;
			for (var i:int = 0; i < attribs.length(); i++)
			{ 
				var name:String = attribs[i].name();
				if (name == "id" || 
					name == "bundle" ||
					name == "point" ||
					name == "class" ||
					name == "function" ||
					name == "variable" ||
					name == "variableType" ||
					name == "functionSignature")
				{
					continue;
				}
				
				if (extensionPoint.hasOwnProperty(name))
				{
					var type:String = extensionPoint[name];
					if (type.charAt(0) == "*")
					{
						type = type.substring(1);
					}
					if (type.toLowerCase() == "boolean")
					{
						var val:Boolean = (attribs[i].toString().toLowerCase() == "true");
						this[name] = val;
					}
					else if (type.toLowerCase() == "integer")
					{
						this[name] = int(attribs[i].toString());
					}
					else if (type.indexOf("asset") == 0)
					{
						if (extensionAssets == null)
						{
							extensionAssets = new (Class(getDefinitionByName("PotomacAssets_" + _bundleID)))();
						}
						
						//get asset from ExtensionAssets
						var assetVariable:String = attribs[i].toString();
						assetVariable = assetVariable.replace("/","_");
						assetVariable = assetVariable.replace("\\","_"); 
						assetVariable = assetVariable.replace(" ","_"); 
						assetVariable = assetVariable.replace(".","_");		
						
						if (extensionAssets.hasOwnProperty(assetVariable))
						{
							this[name] = extensionAssets[assetVariable];
						}
						else
						{ 
							logger.warn("Unable to find extension asset '" + attribs[i].toString() + "' as specified in " + name + " of ["+_pointID+"] in "+_className+".");
							trace("Unable to find extension asset '" + attribs[i].toString() + "' as specified in " + name + " of ["+_pointID+"] in "+_className+".");
							this[name] = baseURL + "bundles/" + _bundleID + "/extensionAssets/" + attribs[i].toString(); 
						}
					}
					else
					{
						this[name] = attribs[i].toString();		
					}
				}
				else
				{
					this[name] = attribs[i].toString();
				}
			} 
		}
		
		/**
		 * The name of the class which declared the extension.
		 */		
		public function get className():String
		{
			return _className;
		}
		
		/**
		 * The name of the bundle where the extension is declared.
		 */		
		public function get bundleID():String
		{
			return _bundleID;
		}
		
		/**
		 * The id of the extension point of the extension.
		 */		
		public function get pointID():String
		{
			return _pointID;
		}
		
		/**
		 * The id of the extension or null if an id wasn't provided.
		 */		
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * Returns one of the <code>DECLAREDON_</code> constants describing where this
		 * extension was declared.
		 */		
		public function get declaredOn():int
		{
			if (_variableName != null)
			{
				return DECLAREDON_VARIABLE;
			}
			if (_functionName != null)
			{
				var unqualClass:String = _className.substr(_className.lastIndexOf(".") + 1);
				if (unqualClass == _functionName)
				{
					return DECLAREDON_CONSTRUCTOR;
				}
				else
				{
					return DECLAREDON_METHOD;
				}
			}
				
			return DECLAREDON_CLASS;
		}
		
		/**
		 * The constructor where this extension was declared or 
		 * null if it wasn't declared on a constructor.
		 */		
		public function get constructor():Constructor
		{
			if (_constructor == null)
			{
				if (declaredOn == DECLAREDON_CONSTRUCTOR)
				{
					_constructor = new Constructor(_functionSignature,this);
				}	
			}
			return _constructor;
		}
		
		/**
		 * The method where this extension was declared or null if
		 * it wasn't declared on a method.
		 */		
		public function get method():Method
		{
			if (_method == null)
			{
				if (declaredOn == DECLAREDON_METHOD)
				{
					_method = new Method(_functionName,_functionSignature,this);
				}
			}			
			return _method;
		}
		
		/**
		 * The variable where this extension was declared or null if
		 * it wasn't declared on a variable.
		 */		
		public function get variable():Variable
		{
			if (_variable == null)
			{
				if (declaredOn == DECLAREDON_VARIABLE)
				{
					var meta:String = null;
					if (hasOwnProperty(_variableName))
					{
						meta = this[_variableName];
					}
					_variable = new Variable(_variableName,_variableType,meta);					
				}	
			}
			return _variable;
		}
		
		public function toString():String
		{
			if (id != null)
				return _pointID + ":" + _id;
				
			if (_variableName != null)
				return _pointID + ":" + _className + "#" + _variableName;
				
			if (_functionName != null)
			 	return _pointID + ":" + _className + "#" + _functionName;
			 	
			return _pointID + ":" + _className;
		}

	}
}