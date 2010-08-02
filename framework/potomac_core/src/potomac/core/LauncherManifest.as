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
package potomac.core
{
	/**
	 * LauncherManifest is the payload of options provided to Launcher#launch.
	 * 
	 */
	public class LauncherManifest
	{
		
		/**
		 * The initial bundles of the application.  Each element in the array should be a string 
		 * containing the id of the bundle.  Bootstrapping assumes all bundles are located in 
		 * a directory named 'bundles' located within the application SWF's directory.
		 */
		public var bundles:Array = new Array();
		
		/**
		 * The id's of bundles that should be preloaded.  This array should be a subset of the 
		 * id's specified in 'bundles'.  
		 */
		public var preloads:Array = new Array();
		
		/**
		 * The URL to pull bundles from when running in AIR.
		 */
		public var airBundlesURL:String = "";
		
		/**
		 * Defaults to false.  If true, bundles will never be cached locally when running in AIR.
		 */
		public var disableAIRCaching:Boolean = false;
		
		/**
		 * Collection of flags for use with the 'enablesFor' extension attribute.  Typically used
		 * for unit testing.
		 */
		public var enablesForFlags:Array = new Array();
		
		/**
		 * The runner which provides the main application starting logic after the bootstrapping
		 * is complete.  Normal execution uses the TemplateRunner which creates the template 
		 * specified in the appManifest.xml and loads all specified parts and pages.
		 */
		public var runner:LaunchRunner;
		

	}
}