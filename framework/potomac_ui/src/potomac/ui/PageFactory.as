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
package potomac.ui
{
	import flash.utils.getDefinitionByName;
	
	import potomac.bundle.Extension;
	import potomac.bundle.ExtensionEvent;
	import potomac.bundle.IBundleService;
	import potomac.inject.Injector;
	
	[ExtensionPoint(id="PageType",type="potomac.ui.Page",idRequired="true",preloadRequired="true")]
	[ExtensionPointDetails(id="PageType",description="Declares a new page UI presentation")]
	
	[Injectable(singleton="true")]
	/**
	 * A PageFactory creates Page instances.
	 */
	public class PageFactory
	{
		private var _bundleService:IBundleService;
		private var _injector:Injector;
		
		//keys are pageType ids and values are Extensions
		private var _pageTypes:Object = new Object();
		
		[Inject]
		/**
		 * Callers should not construct PageFactory instances.  PageFactory is available for injection.
		 */
		public function PageFactory(injector:Injector,bundleService:IBundleService)
		{
			_bundleService = bundleService;
			_injector = injector;
			
			_bundleService.addEventListener(ExtensionEvent.EXTENSIONS_UPDATED,onExtensionsUpdated,false,0,true);
			
			onExtensionsUpdated();
		}
		
		private function onExtensionsUpdated(e:ExtensionEvent=null):void
		{
			_pageTypes = new Object();
			
			var exts:Array = _bundleService.getExtensions("PageType");
			for (var i:int = 0; i < exts.length; i++)
			{
				_pageTypes[Extension(exts[i]).id] = exts[i];
			}
		}
		
		/**
		 * Creates a Page instance of the given type.
		 *  
		 * @param type type of page to construct.
		 * @return the Page instance.
		 * 
		 */
		public function createPage(type:String):Page
		{
			var ext:Extension;
			if (type != null && _pageTypes[type])
			{
				ext = _pageTypes[type];
			}	
			else
			{
				ext = _pageTypes["default"];
			}
			
			try 
			{
				var clz:Class = getDefinitionByName(ext.className) as Class;
			}
			catch (e:ReferenceError)
			{
				throw new Error("Unable to create PageType '" + type +"' because bundle isn't loaded.  Bundles including extensions for PageType must be loaded as RSLs.  Also ensure the class is included the project's build path.");	
			}
			
			return _injector.getInstanceImmediate(clz) as Page;	
		}

	}
}