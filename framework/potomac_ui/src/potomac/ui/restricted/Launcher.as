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
package potomac.ui.restricted
{
	import mx.core.Application;
	import mx.core.Container;
	
	import potomac.bundle.BundleEvent;
	import potomac.bundle.BundleInstallDescriptor;
	import potomac.bundle.BundleService;
	import potomac.bundle.Extension;
	import potomac.inject.InjectionEvent;
	import potomac.inject.Injector;
	import potomac.ui.PotomacUI;
	
	/**
	 * @private
	 */
	public class Launcher
	{
				
		private static var bundleService:BundleService;
		private static var injector:Injector;
		
		private static var _templateID:String;
		private static var _templateData:Object;

		public static function launch(appCargo:XML,templateID:String,templateData:Object,enablesForFlags:Array,airBundlesURL:String,airDisableCaching:Boolean):void
		{
			_templateID = templateID;
			_templateData = templateData;
			bundleService = new BundleService();
			bundleService.enablesForFlags = enablesForFlags;
			bundleService.airBundlesURL = airBundlesURL;
			bundleService.airDisableCaching = airDisableCaching;		
			injector = new Injector(bundleService);			
			bundleService.injector = injector;
							
			var installDescs:Array = new Array();
			
			for each (var bundle:XML in appCargo.bundles.bundle)
            {
            	var id:String = bundle;
            	var bundlexml:XML = null;
            	
            	if (bundle.@rsl == "true")
            	{
            		bundlexml = new XML(appCargo.rsl_xml.bundle.(@id == bundle.toString()));	
            	}

            	var installDesc:BundleInstallDescriptor = new BundleInstallDescriptor(id,bundlexml);
            	installDescs.push(installDesc);
            }                
            
			bundleService.addEventListener(BundleEvent.BUNDLES_INSTALLED,onServiceReady);
			bundleService.install(installDescs);	
		}
		
		private static function onServiceReady(e:BundleEvent):void
		{
			var exts:Array = bundleService.getExtensions("Template");
			
			var ext:Extension;
			for(var i:int = 0; i < exts.length; i++)
			{
				if (exts[i].id == _templateID)
				{
					ext = exts[i];
					break;
				}
			}
			
			if (ext == null)
			{
				throw new Error("Unable to find template with id '" + _templateID + "'.");
			}
			
			injector.getInstanceOfExtension(ext,onInstanceReady);
		}
		
		private static function onInstanceReady(e:InjectionEvent):void
		{				
			var template:Container = e.instance as Container;
			Application.application.addChild(template);

			var pUI:PotomacUI = injector.getInstanceImmediate(PotomacUI) as PotomacUI;
			
			pUI.initializeTemplate(template,_templateData);
		}

	}
}