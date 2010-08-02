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
	[ExtensionPoint(id="ExtensionPointDetails",declaredOn="classes",idRequired="true",
				  	attribute="string",description="*string",order="integer",common="boolean",defaultValue="string")]
	[ExtensionPointDetails(id="ExtensionPointDetails",description="Provides extension point documentation used by SourceMate(tm)")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="id",description="The id of the extension point being documented",order="0")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="attribute",description="Attribute to document",order="1")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="description",description="Point or attribute description",order="2")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="order",description="Provides for attribute ordering",order="3")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="common",description="When false, SourceMate will not automatically insert the attribute.",order="4",common="false")]
	[ExtensionPointDetails(id="ExtensionPointDetails",attribute="defaultValue",description="Default value of the attribute",order="5",common="false")]
	/**
	 * @private
	 * 
	 */
	public dynamic class ExtensionPoint
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