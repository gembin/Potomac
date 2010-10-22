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


	[ExtensionPoint(id="FolderType", type="potomac.ui.Folder", idRequired="true", preloadRequired="true")]
	[ExtensionPointDetails(id="FolderType", description="Declares a new Folder UI presentation")]

	[Injectable(singleton="true")]
	/**
	 * FolderFactory creates folders for Page instances. FolderFactory is available for injection.
	 */
	public class FolderFactory
	{
		private var _bundleService:IBundleService;
		private var _injector:Injector;

		//keys are foldertype ids and values are Extensions
		private var _folderTypes:Object=new Object();

		[Inject]
		/**
		 * Callers should not construct FolderFactory's.  FolderFactory is available for injection.
		 */
		public function FolderFactory(injector:Injector, bundleService:IBundleService)
		{
			_bundleService=bundleService;
			_injector=injector;

			_bundleService.addEventListener(ExtensionEvent.EXTENSIONS_UPDATED, onExtensionsUpdated, false, 0, true);

			onExtensionsUpdated();
		}

		private function onExtensionsUpdated(e:ExtensionEvent=null):void
		{
			_folderTypes=new Object();

			var exts:Array=_bundleService.getExtensions("FolderType");
			for (var i:int=0; i < exts.length; i++)
			{
				_folderTypes[Extension(exts[i]).id]=exts[i];
			}
		}

		/**
		 * Creates a folder of the given type or the defaultType is there is no
		 * FolderType extension for the given type.
		 *
		 * @param type folder type to create
		 * @param defaultType default type if the primary folder type is not found.
		 * @return a folder instance.
		 *
		 */
		public function createFolder(type:String, defaultType:String):Folder
		{
			var ext:Extension;
			if (type != null && _folderTypes[type])
			{
				ext=_folderTypes[type];
			}
			else
			{
				ext=_folderTypes[defaultType];
			}

			try
			{
				var clz:Class=getDefinitionByName(ext.className) as Class;
			}
			catch (e:ReferenceError)
			{
				throw new Error("Unable to create FolderType '" + type + "' because the class cannot be found.  Ensure the providing bundle is an RSL and the class is included in the Flex Library Build Path.  Bundles including extensions for FolderType must be loaded as RSLs.  Also ensure the class is included in the project's build path.");
			}

			return _injector.getInstanceImmediate(clz) as Folder;
		}

	}
}