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
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.inject.Injector;
	
	[ExtensionPoint(id="Part",idRequired="true",type="mx.core.Container",declaredOn="classes",
					title="*string",icon="asset:png,jpg,gif",folder="string",page="string",order="integer")]
	[ExtensionPoint(id="PartInstance",declaredOn="classes",partID="*string",page="*string",folder="*string",order="integer")]	
	[Injectable(singleton="true")]
	/**
	 * PartExtensionManager helps Page instances gather part extensions for creation.
	 */
	public class PartExtensionManager
	{
		private var _bundleService:IBundleService;
		private var _injector:Injector;
		
		[Inject]
		/**
		 * Callers should not construct PartExtensionManager instance.  PartExtensionManager is available for injection.
		 */
		public function PartExtensionManager(bundleService:IBundleService,injector:Injector)
		{
			_bundleService = bundleService;
			_injector = injector;
		}

		/**
		 * Returns the parts declared for the given page.
		 *  
		 * @param page page to get parts for.
		 * @return An array of part Extensions.
		 * 
		 */
		public function getPartsFor(page:String):Array
		{
			var array:Array = new Array();
			
			var exts:Array = _bundleService.getExtensions("Part");
			for (var i:int = 0; i < exts.length; i++)
			{
				var ext:Extension = exts[i] as Extension;
				if (ext.hasOwnProperty("page") && ext.hasOwnProperty("folder") && ext.page == page)
				{
					array.push(ext);
				}				
			}
			
			exts = _bundleService.getExtensions("PartInstance");
			for (i = 0; i < exts.length; i++)
			{
				if (exts[i].page == page)
				{
					array.push(ext);
				}
			}
			
			array.sort(sortParts);
			
			return array;
		}
		
		private function sortParts(a:Extension,b:Extension):Number {
			
			if (!a.hasOwnProperty("order"))
			{
				if (!b.hasOwnProperty("order"))
					return 0;
				return 1;
			}
			if (!b.hasOwnProperty("order"))
				return -1;			
			
		    if(a.order > b.order) {
		        return 1;
		    } else if(a.order < b.order) {
		        return -1;
		    } else  {
		        return 0;
		    }
		}
		
		/**
		 * Returns the part with the given id.
		 *  
		 * @param id id of the part to return.
		 * @return A part Extension with the given id.
		 * 
		 */
		public function getPart(id:String):Extension
		{
			return _bundleService.getExtension(id,"Part");
		}

	}
}