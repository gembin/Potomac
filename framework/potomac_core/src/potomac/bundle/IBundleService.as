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
	import flash.events.IEventDispatcher;
	
	/**
	 * The IBundleService is responsible for loading and managing bundles.  It is also the source for 
	 * all bundle metadata extensions. 
	 * 
	 * @author cgross
	 */
	public interface IBundleService extends IEventDispatcher
	{
		/**
		 * Triggers the installation of one or more bundles.  This method is asynchronous.  When the 
		 * installation is complete a <code>bundlesInstalled</code> event will be dispatched.
		 * 
		 * @param installDescriptors An array of <code>BundleInstallDescriptor</code>s.
		 */		
		function install(installDescriptors:Array):void
        
		/**
		 * Triggers the retrieval and load of the given bundle.  This method is asynchronous.  A 
		 * <code>bundleReady</code> event will be dispatched when the bundle is loaded.
		 * 
		 * @param id id of bundle to load. 
		 */	        
        function loadBundle(bundleID:String):void
        
		/**
		 * Returns true if the given bundle is loaded.
		 *  
		 * @param bundleID bundle id to check if loaded.
		 * @return true if the bundle is loaded, otherwise false. 
		 */	        
        function isBundleLoaded(bundleID:String):Boolean
        
		/**
		 * Returns an array of <code>Extension</code>s of the specified extension point.  If the
		 * className parameter is passed, it will return only those extensions declared within that
		 * class.
		 * 
		 * @param extensionPointID extension point id of the extensions to return.
		 * @param className name of the class in which the extensions are declared.
		 * @return an array of <code>Extension</code>s. 
		 */		        
        function getExtensions(extensionPointID:String,className:String=null):Array
        
		/**
		 * Returns a single <code>Extension</code> with the given id for the given extension point.
		 *  
		 * @param id extension id.
		 * @param point extension point id.
		 * @return the first matching <code>Extension</code> or null if none exists. 
		 */	        
        function getExtension(id:String,point:String):Extension
	}
}