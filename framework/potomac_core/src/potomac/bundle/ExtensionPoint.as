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
	internal dynamic class ExtensionPoint
	{
		private var _bundleID:String;
		private var _id:String;

		
		public function ExtensionPoint(extensionPoint:XML)
		{

			this._bundleID = extensionPoint.attribute("bundle").toString();
			this._id = extensionPoint.attribute("id").toString();
			
			
			//TODO: function signature
			
			var attribs:XMLList = extensionPoint.@*;
			for (var i:int = 0; i < attribs.length(); i++)
			{ 
				var name:String = attribs[i].name();
				if (name == "bundle" ||
					name == "id")
				{
					continue;
				}
				
				this[name] = attribs[i].toString();
			} 			
		}
		
		public function get id():String
		{
			return _id;
		}

	}
}