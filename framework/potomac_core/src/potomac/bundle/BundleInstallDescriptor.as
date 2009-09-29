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
	 * BundleInstallDescriptor describes a bundle to the BundleService. 
	 * 
	 * @author cgross
	 */	
	public class BundleInstallDescriptor
	{
		private var _bundleID:String;
		private var _isRSL:Boolean = false;
		private var _bundleXML:XML;
		
		/**
		 * Constructs a BundleInstallDescriptor.
		 * 
		 * @param bundleID The ID of the bundle to be installed.
		 * @param bundleXML The xml manifest for the bundle.  The 
		 * XML manifest is only required when the installed bundle should be loaded as an RSL.
		 */		
		public function BundleInstallDescriptor(bundleID:String,bundleXML:XML=null)
		{
			_bundleID = bundleID;
			_isRSL = (bundleXML != null);
			_bundleXML = bundleXML;
		}
		
		/**
		 * The bundle ID.
		 */		
		public function get bundleID():String
		{
			return _bundleID;
		}
		
		/**
		 * True if this bundle should be loaded as an RSL.  This is true if 
		 * the xml manifest was passed into the constructor.
		 */		
		public function get isRSL():Boolean
		{
			return _isRSL;
		}
		
		/**
		 * The xml manifest of the bundle.  Only required for RSL bundles.
		 */		
		public function get bundleXML():XML
		{
			return _bundleXML;
		}

	}
}