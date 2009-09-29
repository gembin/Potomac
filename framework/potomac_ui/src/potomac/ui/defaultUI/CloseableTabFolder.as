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
	import flexlib.containers.SuperTabNavigator;
	import flexlib.controls.tabBarClasses.SuperTab;
	import flexlib.events.SuperTabEvent;
	
	import mx.core.Container;
	import mx.events.IndexChangedEvent;
	
	import potomac.inject.Injector;
	import potomac.ui.FolderOptions;
	import potomac.ui.PartExtensionManager;
	import potomac.ui.PartReference;
	import potomac.ui.PotomacUI;
	import potomac.ui.SelectionService;
	import potomac.ui.restricted.BusyCanvas;

	[FolderType(id="closeableTabs")]
	/**
	 * @private
	 */
	public class CloseableTabFolder extends DefaultBaseFolder
	{
		/**
		 * The folderType attribute for this folder. 
		 */
		public static const ID:String = "closeableTabs";
		
		private var _tabFolder:SuperTabNavigator;

		
		[Inject]
		/**
		 * Callers should not construct Folders.  Only Page classes should construct Folders via FolderFactory.
		 */
		public function CloseableTabFolder(injector:Injector,partExtensionMgr:PartExtensionManager,selectionSrv:SelectionService,potomacUI:PotomacUI)
		{
			super(injector,partExtensionMgr,selectionSrv,potomacUI);		
		}
		
		/**
		 * @inheritDoc
		 */
		override public function create(options:FolderOptions=null):Container
		{
			_tabFolder = new SuperTabNavigator;
			_tabFolder.setStyle("paddingTop",0);
			_tabFolder.dragEnabled = false;
			_tabFolder.dropEnabled = false;
			_tabFolder.popUpButtonPolicy = SuperTabNavigator.POPUPPOLICY_OFF;
			_tabFolder.closePolicy = SuperTab.CLOSE_ALWAYS;
			_tabFolder.historyManagementEnabled = false;
			_tabFolder.addEventListener(IndexChangedEvent.CHANGE,onTabChange);
			_tabFolder.addEventListener(SuperTabEvent.TAB_CLOSE,onTabClose);
			return _tabFolder;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getContainer():Container
		{
			return _tabFolder;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			_tabFolder.removeEventListener(IndexChangedEvent.CHANGE,onTabChange);
			_tabFolder.removeEventListener(SuperTabEvent.TAB_CLOSE,onTabClose);
		}

		/**
		 * @inheritDoc
		 */
		override protected function loadSelected():void
		{
			if (_tabFolder.selectedChild != null)
				loadPart(_tabFolder.selectedChild as BusyCanvas);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function isShown(busyCanvas:BusyCanvas):Boolean
		{
			return (_tabFolder.selectedChild == busyCanvas);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function showPart(partReference:PartReference):void
		{
			if (partReference.control == null)
			{
				var busyCanvas:BusyCanvas;
				var kids:Array = getContainer().getChildren();
				for (var i:int = 0; i < kids.length; i++)
				{
					if (partReference.equals(kids[i].partReference))
					{
						busyCanvas = kids[i] as BusyCanvas;
						break;
					}					
				}
				if (busyCanvas == null)
				{
					return;
				}
				_tabFolder.selectedChild = busyCanvas;
			}
			else
			{
				_tabFolder.selectedChild = partReference.control.parent as Container;
			}
		}
		
		private function onTabClose(e:SuperTabEvent):void
		{
			e.preventDefault();
			var busyCanvas:BusyCanvas = BusyCanvas(_tabFolder.getChildAt(e.tabIndex)); 
			_tabFolder.selectedChild = busyCanvas;
			closePart(busyCanvas.partReference);
		}
		
		private function onTabChange(event:IndexChangedEvent):void
		{
			loadPart(event.relatedObject as BusyCanvas);
		}
	
	}
}