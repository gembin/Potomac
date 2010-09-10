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
	
	import potomac.core.IPotomacPreloader;
	
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
		 * <p>
		 * This method accepts an array that may contain <code>String</code>s that contain just the simple
		 * bundle ID or <code>BundleInstallDescriptor</code>s if you need to provide a more options.
		 * </p>
		 * @param installables An array of bundle IDs as <code>String</code>s or descriptors (<code>BundleInstallDescriptor</code>s).
		 */		
		function install(installables:Array):void
        
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
		 * <p>
		 * By default, when the className parameter is specified, only extensions declared directly within
		 * the specific class are returned.  Extensions declared in the base class or super classes of the
		 * specified class are not returned.  When <code>true</code> is passed for the superClass argument,
		 * all extensions declared in the entire class hierarchy are returned.  Importantly, for Potomac to
		 * be able to inspect the class hierarchy, the class specified must be available in the Flash 
		 * ApplicationDomain.  In other words, the class's bundle must be loaded.
		 * </p>
		 * @param extensionPointID extension point id of the extensions to return.
		 * @param className name of the class in which the extensions are declared.
		 * @param superClasses if true, will return extensions declared in super classes.
		 * @return an array of <code>Extension</code>s. 
		 */			        
        function getExtensions(extensionPointID:String,className:String=null,superClasses:Boolean=false):Array
        
		/**
		 * Returns a single <code>Extension</code> with the given id for the given extension point.
		 *  
		 * @param id extension id.
		 * @param point extension point id.
		 * @return the first matching <code>Extension</code> or null if none exists. 
		 */	        
        function getExtension(id:String,point:String):Extension
			
		/**
		 * Returns an array of ExtensionPoint objects including 
		 * each extension point in all installed bundles.
		 *  
		 * @return array of ExtensionPoints 
		 */
		function getExtensionPoints():Array;
		
		/**
		 * Returns the extension point with the given point id.
		 *  
		 * @param pointID id/tag name of the extension point.
		 * 
		 * @return the ExtensionPoint
		 * 
		 */
		function getExtensionPoint(pointID:String):ExtensionPoint;
		
		/**
		 * Returns an array of BundleDescriptors for all installed bundles.
		 * <p>
		 * This method should not be called while bundles are currently installing.
		 * </p>
		 */
		function get bundleDescriptors():Array;
		
		/**
		 * Returns the BundleDescriptor of the installed bundle with the given id.
		 * <p>
		 * This method should not be called while bundles are currently installing.
		 * </p>
		 * @param bundleID Bundle ID of the bundle whose descriptor is requested.
		 * 
		 * @return BundleDescriptor or null of no bundle is found with the given id. 
		 */
		function getBundleDescriptor(bundleID:String):BundleDescriptor;
	}
}