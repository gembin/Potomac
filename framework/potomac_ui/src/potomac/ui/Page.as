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
	import mx.core.Container;
	
	import potomac.bundle.IBundleService;
	
	[ExtensionPoint(id="Page",declaredOn="classes",title="*string",
	                idRequired="true",icon="asset:png,gif,jpg",
	                pageType="string",order="integer",open="boolean")]
	/**
	 * A page is a high-level subsection of an application.  Pages display 
	 * UI through one or more Folders.  Each page has one default Folder (with the id of "default")
	 * which is automatically created.
	 * 
	 * @author cgross
	 */
	public class Page
	{
		public static const LOCATION_TOP:String="top";
		public static const LOCATION_BOTTOM:String="bottom";
		public static const LOCATION_LEFT:String="left";
		public static const LOCATION_RIGHT:String="right";
		
		private var _id:String;
		private var _input:PageInput;
		private var _descriptor:PageDescriptor;
		
		/**
		 * Callers should not construct Page instances.  They are constructed via PotomacUI. 
		 * 
		 */
		public function Page()
		{
		}
		
		public function set id(id_:String):void
		{
			_id = id_;
		}
		
		/**
		 * The id of this page.
		 */
		public function get id():String
		{
			return _id;
		}
		
		public function set descriptor(descriptor:PageDescriptor):void
		{
			_descriptor = descriptor;
		}
		
		/**
		 * The descriptor for this page.
		 */
		public function get descriptor():PageDescriptor
		{
			return _descriptor;
		}
		
		/**
		 * The input for this page.
		 */
		public function get input():PageInput
		{
			return _input;
		}
		
		public function set input(input:PageInput):void
		{
			_input = input;
		}
		
		/**
		 * Creates the UI for this page.
		 * 
		 * @param options page options
		 * 
		 */
		public function create(options:PageOptions):void
		{
		}
		
		/**
		 * Stores the settings for this page so that subsequent recreations
		 * can maintain the same settings. 
		 * 
		 */
		public function storeSettings():void
		{
		}
		
		/**
		 * Returns the UI control for this page.
		 *  
		 * @return the UI control for this page.
		 * 
		 */
		public function getContainer():Container
		{
			return null;
		}
		
		//if anything from location on isn't specified then it opens it in its declared location
		/**
		 * Creates a folder in this page.  If the location information (location,relativeTo,percent) is not
		 * specified, then the folder is opened in its declared (or persisted) location. 
		 * 
		 * @param id id of the folder to open
		 * @param folderType folder type to open or null for the default folder type.
		 * @param options folder options
		 * @param location one of the LOCATION_* constants
		 * @param relativeTo the id of the folder that will be resized to accomodate this new folder
		 * @param percent the percent of the relativeTo folder's size which will be allocated to the new folder
		 * @return the new folder 
		 * 
		 */
		public function openFolder(id:String,folderType:String=null,options:FolderOptions=null,location:String=null,relativeTo:String=null,percent:int=0):Folder
		{
			return null;
		}
		
		/**
		 * Returns the folder in this page with the given id or null if no matching folder is found.
		 *  
		 * @param id id of folder to return.
		 * @return a folder instance or null.
		 * 
		 */
		public function getFolder(id:String):Folder
		{
			return null;
		}
		
		/**
		 * Returns an array of Folders that exist in this page.
		 *  
		 * @return Array of Folders
		 * 
		 */
		public function getFolders():Array
		{
			return null;
		}
		
		/**
		 * Closes the given folder.
		 *  
		 * @param folder folder to close.
		 * 
		 */
		public function closeFolder(folder:Folder):void
		{
			
		}
		
		/**
		 * Closes the folder with the given id.
		 *  
		 * @param id id of the folder to close.
		 * 
		 */
		public function closeFolderByID(id:String):void
		{
			
		}
		
		/**
		 * Returns all folder extensions declared for given page.
		 *   
		 * @param pageID id of the page.
		 * @param bundleService the main bundle service.
		 * @return an Array of Folder Extensions.
		 * 
		 */
		protected function getFolderExtensions(pageID:String,bundleService:IBundleService):Array
		{
			var allExts:Array = bundleService.getExtensions("Folder");
			var exts:Array = new Array();
			
			for (var i:int = 0; i < allExts.length; i++)
			{
				if (allExts[i].page == pageID)
				{
					exts.push(allExts[i]);
				}
			}
			
			return exts;
		}
		
		/**
		 * Returns true if this page contains any part which has unsaved changes.
		 * 
		 * @return True if any part in any folder in this page has unsaved changes. 
		 */
		public function containsDirty():Boolean
		{
			return false;
		}

	}
}