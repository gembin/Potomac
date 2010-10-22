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
	import mx.containers.TitleWindow;
	import mx.core.Container;
	import mx.core.UIComponent;

	import potomac.inject.Injector;
	import potomac.ui.FolderOptions;
	import potomac.ui.PartExtensionManager;
	import potomac.ui.PotomacUI;
	import potomac.ui.SelectionService;
	import potomac.ui.restricted.BusyCanvas;

	[FolderType(id="titleWindow")]
	/**
	 * @private
	 */
	public class TitleWindowFolder extends DefaultBaseFolder
	{
		/**
		 * The folderType attribute for this folder.
		 */
		public static const ID:String="titleWindow";

		private var _titleWindow:TitleWindow;

		[Inject]
		/**
		 * Callers should not construct Folders.  Only Page classes should construct Folders via FolderFactory.
		 */
		public function TitleWindowFolder(injector:Injector, partExtensionMgr:PartExtensionManager, selectionSrv:SelectionService, potomacUI:PotomacUI)
		{
			super(injector, partExtensionMgr, selectionSrv, potomacUI);
		}

		/**
		 * @inheritDoc
		 */
		override public function create(options:FolderOptions=null):Container
		{
			_titleWindow=new TitleWindow();
			_titleWindow.setStyle("paddingTop", 0);
			_titleWindow.setStyle("paddingLeft", 0);
			_titleWindow.setStyle("paddingRight", 0);
			_titleWindow.setStyle("paddingBottom", 0);
			return _titleWindow;
		}

		/**
		 * @inheritDoc
		 */
		override public function getContainer():Container
		{
			return _titleWindow;
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
		override protected function afterAdd(busyCanvas:BusyCanvas):void
		{
			_titleWindow.title=busyCanvas.label;
			_titleWindow.titleIcon=busyCanvas.icon;
		}

		/**
		 * @inheritDoc
		 */
		override protected function isShown(busyCanvas:BusyCanvas):Boolean
		{
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateIconLabel(part:UIComponent):void
		{
			super.updateIconLabel(part);
			_titleWindow.title=Container(part.parent).label;
			_titleWindow.titleIcon=Container(part.parent).icon;
		}

	}
}