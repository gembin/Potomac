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
package potomac.ui.defaultUI
{
	import mx.containers.Canvas;
	import mx.core.Container;

	import potomac.inject.Injector;
	import potomac.ui.FolderOptions;
	import potomac.ui.PartExtensionManager;
	import potomac.ui.PartReference;
	import potomac.ui.PotomacUI;
	import potomac.ui.SelectionService;
	import potomac.ui.restricted.BusyCanvas;

	[FolderType(id="naked")]
	/**
	 * @private
	 */
	public class NakedFolder extends DefaultBaseFolder
	{
		/**
		 * The folderType attribute for this folder.
		 */
		public static const ID:String="naked";

		private var _canvas:Canvas;

		[Inject]
		/**
		 * Callers should not construct Folders.  Only Page classes should construct Folders via FolderFactory.
		 */
		public function NakedFolder(injector:Injector, partExtensionMgr:PartExtensionManager, selectionSrv:SelectionService, potomacUI:PotomacUI)
		{
			super(injector, partExtensionMgr, selectionSrv, potomacUI);
		}

		/**
		 * @inheritDoc
		 */
		override public function create(options:FolderOptions=null):Container
		{
			_canvas=new Canvas();
			return _canvas;
		}

		/**
		 * @inheritDoc
		 */
		override public function getContainer():Container
		{
			return _canvas;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
		}


		/**
		 * @inheritDoc
		 */
		override protected function isShown(busyCanvas:BusyCanvas):Boolean
		{
			return true;
		}

	}
}