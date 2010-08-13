/*******************************************************************************
 *  Copyright (c) 2010 ElementRiver, LLC.
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
	 * A BundleDescriptor describes an installed bundle.
	 * 
	 */
	public class BundleDescriptor
	{
		/**
		 * ID of the bundle.
		 */
		public var bundleID:String;
		
		/**
		 * The String IDs of the bundles this bundle depends upon.
		 */
		public var dependencies:Array;
		
		/**
		 * Version of the bundle as specified in the bundle.xml.
		 */
		public var version:String;
		
		/**
		 * Name of the bundle as specified in the bundle.xml.
		 */
		public var name:String;
		
		/**
		 * URL where the assets.swf was loaded from.
		 */
		public var assetsSWFURL:String;
		
		/**
		 * URL where the bundle's module swf was loaded from.  This property will be null until the bundle is loaded.
		 */
		public var moduleSWFURL:String;
		
		/**
		 * True if the bundle is loaded (i.e. the bundle's module swf has been loaded), otherwise false.
		 */
		public var loaded:Boolean;


		/**
		 * @private
		 */
		public function BundleDescriptor(bundleID:String, dependencies:Array, version:String, name:String, assetsSWFURL:String, loaded:Boolean, moduleSWFURL:String=null)
		{
			this.bundleID = bundleID;  
			this.dependencies = dependencies;  
			this.version = version;  
			this.name = name;  
			this.assetsSWFURL = assetsSWFURL;  
			this.loaded = loaded;  
			this.moduleSWFURL = moduleSWFURL;  
		}


		/**
		 * @private
		 */
		public function toString():String
		{
			return "BundleDescriptor{bundleID:\"" + bundleID + "\", dependencies:[" + dependencies + "], version:\"" + version + "\", name:\"" + name + "\", assetsSWFURL:\"" + assetsSWFURL + "\", moduleSWFURL:\"" + moduleSWFURL + "\", loaded:" + loaded + "}";
		}

	}
}