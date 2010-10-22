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
	import flash.display.DisplayObjectContainer;

	import mx.containers.BoxDirection;
	import mx.containers.Canvas;
	import mx.containers.DividedBox;
	import mx.core.Container;

	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.ui.Folder;
	import potomac.ui.FolderFactory;
	import potomac.ui.FolderOptions;
	import potomac.ui.Page;
	import potomac.ui.PageOptions;
	import potomac.ui.PartExtensionManager;
	import potomac.ui.PotomacUI;

	[PageType(id="default")]
	/**
	 * @private
	 */
	public class DefaultPage extends Page
	{
		private var root:Canvas=new Canvas();
		//keys are folder ids, vals are Folders
		private var folders:Object=new Object();

		private var _folderFactory:FolderFactory;
		private var _potomacUI:PotomacUI;
		private var _bundleService:IBundleService;
		private var _partExtensionManager:PartExtensionManager;

		private static const STORAGEDELIMITER:String="<\$\*\$>";

		[Inject]
		public function DefaultPage(folderFactory:FolderFactory, potomacUI:PotomacUI, bundleService:IBundleService, partExtensionMgr:PartExtensionManager)
		{
			super();
			_folderFactory=folderFactory;
			_potomacUI=potomacUI;
			_bundleService=bundleService;
			_partExtensionManager=partExtensionMgr;
		}

		/**
		 * @inheritDoc
		 */
		override public function create(options:PageOptions):void
		{
			createFolders();
			createParts();
		}

		private function createFolders():void
		{
//			var storageID:String = "potomac.ui.defaultUI.DefaultPage$" + id;
//			if (_potomacUI.restoreLastOpened && _storageService.hasOwnProperty(storageID))
//			{
//				var savedFolders:Array = _storageService.getProperty(storageID) as Array;
//				var params:Array;
//				for(var i:int = 0; i < savedFolders.length; i++)
//				{
//					params = String(savedFolders[i]).split(STORAGEDELIMITER);
//					var folderOptions:FolderOptions = _serializationService.deserialize(params[4]) as FolderOptions;
//					openFolder(params[0],params[1],params[2],int(params[3]),folderOptions,params[5]);
//				}
//			}
//			else
//			{
			var exts:Array=getFolderExtensions(id, _bundleService);
			//first find default folder if it exists
			var defaultType:String="default";
			for (var i:int=0; i < exts.length; i++)
			{
				if (exts[i].id == "default")
				{
					if (exts[i].folderType)
						defaultType=exts[i].folderType;
					exts.splice(i, 1);
					i--;
				}
			}

			openFolderAbsolute(Folder.DEFAULT_ID, "", "", 0, null, defaultType);

			var folderOpened:Boolean=true;
			while (folderOpened && exts.length > 0)
			{
				folderOpened=false;

				for (i=0; i < exts.length; i++)
				{
					var open:String=exts[i].open;
					if (open != "false")
					{
						if (getFolder(exts[i].relativeTo) != null)
						{
							//open folder
							openFolderAbsolute(exts[i].id, exts[i].location, exts[i].relativeTo, exts[i].percent, null, exts[i].folderType);

							exts.splice(i, 1);
							folderOpened=true;
							break;
						}
					}
				}
			}
//			}
		}

		private function createParts():void
		{
			//get list of parts 
			var partExts:Array=_partExtensionManager.getPartsFor(id);
			for (var i:int=0; i < partExts.length; i++)
			{
				var ext:Extension=partExts[i];

				var open:String=ext.open;
				if (open != "false")
				{
					var partID:String=ext.id;
					if (ext.pointID == "PartInstance")
						partID=ext.partID;
					if (!folders[ext.folder])
						throw new Error("Unknown folder '" + ext.folder + "' specified in '" + partID + "'.");

					var folder:Folder=folders[ext.folder];
					folder.openPart(partID, null, null, false);
				}
			}
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function storeSettings():void
		{
			//walk down tree of divboxes

		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function getContainer():Container
		{
			return root;
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function openFolder(id:String, folderType:String=null, options:FolderOptions=null, location:String=null, relativeTo:String=null, percent:int=0):Folder
		{
			if (location != null)
			{
				if (location != LOCATION_BOTTOM && location != LOCATION_LEFT && location != LOCATION_RIGHT && location != LOCATION_TOP)
				{
					throw new ArgumentError("Location argument must be one of top,left,right,bottom.");
				}
				if (relativeTo == null)
				{
					throw new ArgumentError("When location argument is specified, both relativeTo and percent must also be specified.");
				}
				if (relativeTo != null && !folders[relativeTo])
				{
					throw new ArgumentError("relativeTo folder not found.");
				}
				if (percent <= 0 || percent >= 100)
				{
					throw new ArgumentError("Percent must be > 0 and < 100.");
				}

				return openFolderAbsolute(id, location, relativeTo, percent, options, folderType);
			}



			//get last known location or declared location
			var ext:Extension=_bundleService.getExtension(id, "Folder");
			if (ext == null)
			{
				throw new ArgumentError("Folder with id '" + id + "' was not found.  If you wish to open a folder dynamically please provide the necessary location arguments.");
			}

			if (folderType == null)
			{
				folderType=ext.folderType;
			}

			return openFolderAbsolute(id, ext.location, ext.relativeTo, ext.percent, options, folderType);

		}

		private function openFolderAbsolute(id:String, location:String, relativeTo:String, percent:int, options:FolderOptions=null, folderType:String=null):Folder
		{
			if (folders.hasOwnProperty(id))
				return folders[id];

			var newFolder:Folder=_folderFactory.createFolder(folderType, TabFolder.ID);



			if (root.numChildren == 0)
			{
				var newContainer:Container=newFolder.create(options) as Container;
				newContainer.percentWidth=100;
				newContainer.percentHeight=100;
				root.addChild(newContainer);
			}
			else
			{
				if (!folders[relativeTo])
				{
					throw new Error("Unable to open folder '" + id + "' because relativeTo folder '" + relativeTo + "' not found.");
				}
				newContainer=newFolder.create(options) as Container;
				newContainer.percentWidth=100;
				newContainer.percentHeight=100;

				var oldFolder:Folder=folders[relativeTo];
				var oldContainer:DisplayObjectContainer=oldFolder.getContainer();
				var oldParent:Container=oldContainer.parent as Container;
				oldParent.removeChild(oldContainer);

				var divBox:DividedBox=new DividedBox();
				var canvas:Canvas;
				if (location == Page.LOCATION_BOTTOM)
				{
					divBox.direction=BoxDirection.VERTICAL;
					canvas=new Canvas();
					canvas.percentWidth=100;
					canvas.percentHeight=100;
					canvas.addChild(oldContainer);
					divBox.addChild(canvas);
					canvas=new Canvas();
					canvas.percentHeight=100;
					canvas.percentWidth=100;
					canvas.addChild(newFolder.getContainer());
					divBox.addChild(canvas);
				}
				else if (location == Page.LOCATION_TOP)
				{
					divBox.direction=BoxDirection.VERTICAL;
					canvas=new Canvas();
					canvas.percentWidth=100;
					canvas.percentHeight=100;
					canvas.addChild(newFolder.getContainer());
					divBox.addChild(canvas);
					canvas=new Canvas();
					canvas.percentHeight=100;
					canvas.percentWidth=100;
					canvas.addChild(oldContainer);
					divBox.addChild(canvas);
				}
				else if (location == Page.LOCATION_LEFT)
				{
					divBox.direction=BoxDirection.HORIZONTAL;
					canvas=new Canvas();
					canvas.percentWidth=100;
					canvas.percentHeight=100;
					canvas.addChild(newFolder.getContainer());
					divBox.addChild(canvas);
					canvas=new Canvas();
					canvas.percentHeight=100;
					canvas.percentWidth=100;
					canvas.addChild(oldContainer);
					divBox.addChild(canvas);
				}
				else
				{
					divBox.direction=BoxDirection.HORIZONTAL;
					canvas=new Canvas();
					canvas.percentWidth=100;
					canvas.percentHeight=100;
					canvas.addChild(oldContainer);
					divBox.addChild(canvas);
					canvas=new Canvas();
					canvas.percentHeight=100;
					canvas.percentWidth=100;
					canvas.addChild(newFolder.getContainer());
					divBox.addChild(canvas);
				}



				divBox.percentHeight=100;
				divBox.percentWidth=100;
				oldParent.addChild(divBox);

				var movePixels:Number;
				Container(root).validateNow();
				if (location == Page.LOCATION_BOTTOM)
				{
					movePixels=(divBox.height * .5) - (divBox.height * (percent / 100));
				}
				else if (location == Page.LOCATION_TOP)
				{
					movePixels=(divBox.height * (percent / 100)) - (divBox.height * .5);
				}
				else if (location == Page.LOCATION_LEFT)
				{
					movePixels=(divBox.width * (percent / 100)) - (divBox.width * .5);
				}
				else
				{
					movePixels=(divBox.width * .5) - (divBox.width * (percent / 100));
				}
				//trace(divBox.width + "," + divBox.height + " - " + movePixels);
				divBox.moveDivider(0, movePixels);
			}

			folders[id]=newFolder;
			newFolder.id=id;
			newFolder.page=this;
			newFolder.pageInput=input;
			return newFolder;
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function getFolder(id:String):Folder
		{
			if (folders[id])
			{
				return folders[id];
			}
			return null;
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function getFolders():Array
		{
			var array:Array=new Array();
			for (var i:String in folders)
			{
				array.push(folders[i]);
			}

			return array;
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function closeFolder(folder:Folder):void
		{
			var id:String=null;
			for (var i:String in folders)
			{
				if (folders[i] == folder)
				{
					id=i;
					break;
				}
			}
			if (id == null)
			{
				throw new Error("Given folder does not exist in this page.");
			}

			var container:DisplayObjectContainer=folder.getContainer();
			if (!(container.parent.parent is DividedBox))
			{
				//must be root folder
				container.parent.removeChild(container);
				folders[id]=null
				delete folders[id];
				return;
			}

			var siblingContainer:DisplayObjectContainer;
			var divBox:DividedBox=container.parent.parent as DividedBox;
			if (divBox.getChildIndex(container.parent) == 0)
			{
				siblingContainer=DisplayObjectContainer(divBox.getChildAt(1)).getChildAt(0) as DisplayObjectContainer;
			}
			else
			{
				siblingContainer=DisplayObjectContainer(divBox.getChildAt(0)).getChildAt(0) as DisplayObjectContainer;
			}

			var divBoxParent:DisplayObjectContainer=divBox.parent;
			divBoxParent.removeChild(divBox);
			divBoxParent.addChild(siblingContainer);

			folders[id]=null
			delete folders[id];
		}

		/**
		 * @inheritDoc
		 *
		 */
		override public function closeFolderByID(id:String):void
		{
			if (!folders[id])
			{
				throw new Error("Folder '" + id + "' not found.");
			}
			closeFolder(folders[id] as Folder);
		}

		/**
		 * @inheritDoc
		 */
		override public function containsDirty():Boolean
		{
			for (var i:String in folders)
			{
				if (folders[i].containsDirty())
					return true;
			}
			return false;
		}
	}
}