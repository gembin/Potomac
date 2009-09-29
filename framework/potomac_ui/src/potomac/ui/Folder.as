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
	
	[ExtensionPoint(id="Folder",idRequired="true",page="*string",folderType="string",
					location="*choice:top,bottom,left,right",relativeTo="*string",
					percent="*integer",open="boolean")]
	/**
	 * A Folder represents a portion of a Page.  A folder can contain zero, one, or many parts.
	 */
	public class Folder
	{
		/**
		 * The id of the default folder. 
		 */
		public static const DEFAULT_ID:String = "default";
		
		private var _id:String;
		private var _page:Page;
		private var _pageInput:PageInput;

		/**
		 * Callers should not create Folders.  Only Page instances should create folders via FolderFactory. 
		 */
		public function Folder()
		{
		}
		
		/**
		 * The id of the folder.
		 */
		public function get id():String
		{
			return id;
		}
		
		public function set id(id:String):void
		{
			_id = id;
		}
		
		/**
		 * The page the folder resides in.
		 */
		public function get page():Page
		{
			return _page;
		}
		
		public function set page(page:Page):void
		{
			_page = page;
		}
		
		/**
		 * The input for the page the folder resides in.
		 */
		public function get pageInput():PageInput
		{
			return _pageInput;
		}
		
		public function set pageInput(pageInput:PageInput):void
		{
			_pageInput = pageInput;
		}
		
		/**
		 * Creates the folder UI.  Only Page instances should call this method.
		 * 
		 * @param options The folder options.
		 * @return The folder UI control.
		 */
		public function create(options:FolderOptions=null):Container
		{			
			return null;
		}
		
		/**
		 * Returns the options used when creating the folder.
		 * @return the folder options.
		 */
		public function getOptions():FolderOptions
		{
			return null;
		}
		
		/**
		 * Returns the UI control for this folder.
		 * 
		 * @return The UI control for this folder. 
		 */
		public function getContainer():Container
		{
			return null;
		}
		
		/**
		 *  Callback that allows folders to dispose of any necessary resources or
		 * remove event listeners before being unreferenced for GC.
		 */
		public function dispose():void
		{
		}
		
		/**
		 * Opens an instance of a part with the given id and input in this folder.  If a part with this id and 
		 * a matching input already exists within this folder, it will be made visible and the part creation will be 
		 * prevented.
		 *  
		 * @param id  The id of the part to open.
		 * @param input The input of the part.
		 * @param options  The options for the part instance.
		 * @param setFocus  True if the part should be made visible (ex.  its tab selected).
		 * 
		 */
		public function openPart(id:String,input:PartInput=null,options:PartOptions=null,setFocus:Boolean=true):void
		{
			
		}
		
		/**
		 * Initiates a save of the part represented by the given reference.  Saves are asynchronous and therefore
		 * this method returns before the save is complete.
		 * 
		 * @param reference part to save.
		 */
		public function savePart(reference:PartReference):void
		{
			
		}
		
		/**
		 * Closes the given part.  If <code>promptForSave</code> is true and the part is dirty, the user will
		 * be given an opportunity to save the part.  If <code>promptForSave</code> is true and the part is dirty, 
		 * this method runs asynchronously.  When the user is prompted to save, he/she may select "Cancel" thus preventing
		 * the part from closing.  Similarly if the part save fails, the part will stay open to allow the user to
		 * view the save errors.
		 * 
		 * @param reference part to close.
		 * @param promptForSave True to prompt the user to save if the part is dirty, false to close immediately.
		 * 
		 */
		public function closePart(reference:PartReference,promptForSave:Boolean=true):void
		{
			
		}
		
		/**
		 * Returns the reference for the given part UI control.
		 * 
		 * @param control the part UI itself.
		 * @return the part reference.
		 * 
		 */
		public function getPartReference(control:Container):PartReference
		{
			return null;
		}
		
		/**
		 * Returns all part references in this folder.
		 * 
		 * @return all part references in this folder. 
		 */
		public function getPartReferences():Array
		{
			return null;
		}
		
		/**
		 * Returns the part references for the part with the given id and matching the given input.
		 * 
		 * @param id id of the part to find.
		 * @param input input of the part to find.
		 * @return the part reference.
		 * 
		 */
		public function findPart(id:String,input:PartInput=null):PartReference
		{
			return null
		}
		
		/**
		 * True if the part has unsaved changes.
		 * 
		 * @param partReference part reference
		 * @return true if the part has unsaved changes.
		 * 
		 */
		public function isDirty(partReference:PartReference):Boolean
		{
			return false;
		}
		
		
		/**
		 * Returns true if any part within this folder has unsaved changes.
		 *  
		 * @return returns true if any part in the folder has unsaved changes. 
		 */
		public function containsDirty():Boolean
		{
			return false;
		}
		
		/**
		 * Makes the given part visible (ex. selecting the tab in a tabnavigator).
		 * 
		 * @param partReference part reference to show.
		 * 
		 */
		public function showPart(partReference:PartReference):void
		{
			
		}

	}
}