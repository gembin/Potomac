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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.core.Container;
	import mx.events.CloseEvent;
	
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	
	[ExtensionPoint(id="Template",declaredOn="classes",idRequired="true",
					rslRequired="true",type="mx.core.Container",properties="string")]
	[Injectable(singleton="true")]
	/**
	 * PotomaUI is the main controller for the Potomac UI framework.  Its primarily responsible for
	 * managing pages.
	 */
	public class PotomacUI extends EventDispatcher
	{
		private var _pageFactory:PageFactory;
		
		private var _pageDescs:Array = new Array();
		
		private var _pages:Array = new Array();
		
		//map of pages to Objects with those Obj having props like saving and closing
		private var _pageVars:Object = new Dictionary();
		
		private var _template:Container;
		
		[Inject]
		/**
		 * Callers should not construct PotomacUI. Its is available for injection.
		 */
		public function PotomacUI(bundleSrv:IBundleService,pageFactory:PageFactory)
		{
			_pageFactory = pageFactory;
			
			var pageExts:Array = bundleSrv.getExtensions("Page");
			pageExts.sort(sortPages);			
			for(var i:int = 0; i < pageExts.length; i++)
			{
				var ext:Extension = Extension(pageExts[i]);
				_pageDescs.push(new PageDescriptor(ext.id,ext.title,ext.icon,ext.pageType,ext));
			}			
			
			addEventListener(PotomacEvent.PART_SAVED,onPartSaveComplete);
			addEventListener(PotomacEvent.PART_SAVE_ERROR,onPartSaveError);
			addEventListener(PotomacEvent.PART_DIRTY_CHANGE,onPartDirtyChange);
			addEventListener(PotomacEvent.PART_CLOSED,onPartClosed);
		}
		
		private function sortPages(a:Extension,b:Extension):Number {
			
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
		 * @private
		 */
		public function initializeTemplate(template:Container,templateData:Object):void
		{
			_template = template;
			template.dispatchEvent(new TemplateEvent(TemplateEvent.INITIALIZE,templateData,null,null,null,null,false));
			
			for(var i:int = 0; i < _pageDescs.length; i++)
			{
				var open:String = _pageDescs[i].extension.open;
				if (open != "false")	
					openPage(_pageDescs[i].id,null,null,false);
			}
			
		}
		
		private function getPageDescriptor(id:String):PageDescriptor
		{
			for (var i:int = 0; i< _pageDescs.length; i++)
			{
				if (_pageDescs[i].id == id)
					return _pageDescs[i];
			}
			return null;			
		}
		
		/**
		 * Opens an instance of the page with the given id and input.
		 * 
		 * @param id id of the page.
		 * @param input input for the page.
		 * @param options page options.
		 * @param setFocus if true, the Template will show this page (ex. select its tab).
		 * @return the Page instance.
		 * 
		 */
		public function openPage(id:String,input:PageInput=null,options:PageOptions=null,setFocus:Boolean=true):Page
		{
			var pageDesc:PageDescriptor = getPageDescriptor(id);
			if (pageDesc == null)
				throw new Error("Page '" + id + "' not found.");
				
			var ref:Page = findPage(id,input);
			if (ref != null)
			{
				if (setFocus)
				{
					showPage(ref);
				}
				return ref;
			}
			
			var newPage:Page = _pageFactory.createPage(pageDesc.type);
			newPage.id = id;
			newPage.input = input;
			newPage.descriptor = pageDesc;

			_pages.push(newPage);
			_pageVars[newPage] = new Object();

			_template.dispatchEvent(new TemplateEvent(TemplateEvent.OPEN_PAGE,null,pageDesc,input,options,newPage,setFocus));
			
			return newPage;
		}

		/**
		 * Closes the given page.  If <code>promptForSave</code> is true, this method runs
		 * asynchronously and may fail if either the user presses "Cancel" or a save on 
		 * one of the parts fails.
		 *  
		 * @param page page to save.
		 * @param promptForSave if true, the user will be prompted to save all dirty parts on the page.
		 * 
		 */
		public function closePage(page:Page,promptForSave:Boolean=true):void
		{
			if (_pageVars[page].closing == true)
				return;
			
			if (promptForSave && page.containsDirty())
			{
				_pageVars[page].closing = true;
				_pageVars[page].saveAlert = Alert.show("'" + page.descriptor.title + "' has been modified.  Save changes?","Save",
							Alert.YES | Alert.NO | Alert.CANCEL,null,onCloseSavePrompt,null,Alert.YES);
				return;		
			}
			
			_template.dispatchEvent(new TemplateEvent(TemplateEvent.CLOSE_PAGE,null,null,null,null,page,false));
			
			_pages.splice(_pages.indexOf(page),1);
			_pageVars[page] = null;
			delete _pageVars[page];
			
			dispatchEvent(new PotomacEvent(PotomacEvent.PAGE_CLOSED,null,page));
		}
		
		private function onCloseSavePrompt(e:CloseEvent):void
		{
			for (var i:Object in _pageVars)
			{
				if (_pageVars[i].saveAlert == e.target)
				{
					var page:Page = i as Page;
					break;
				}
			}
			
			if (page == null)
			{
				//not sure how we could really get here but so lets just return if so.
				return;
			}
			
			if (e.detail == Alert.CANCEL)
			{
				_pageVars[page].closing = false;
				return;
			}
			else if (e.detail == Alert.NO)
			{
				_pageVars[page].closing = false;
				closePage(page,false);
			}
			else if (e.detail == Alert.YES)
			{
				savePage(page);
			}
		}
		
		/**
		 * Initiates a save on the given page.  All dirty parts will be asked to save.  This method is asynchronous and may 
		 * fail if the save on one of the parts fails.
		 *  
		 * @param page page to save.
		 * 
		 */
		public function savePage(page:Page):void
		{
			if (_pageVars[page].saving == true)
			{
				return;
			}
			
			_pageVars[page].saving = true;
			_pageVars[page].savingError = false;
			_pageVars[page].saveStillTriggering = true;
			
			_pageVars[page].savingPageRefs = new Array();
			
			var folders:Array = page.getFolders();
			for (var i:int = 0; i< folders.length; i++)
			{
				var folder:Folder = folders[i] as Folder;
				var refs:Array = folder.getPartReferences();
				for (var j:int = 0; j < refs.length; j++)
				{
					if (folder.isDirty(refs[j]))
					{
						_pageVars[page].savingPageRefs.push(refs[j]);
						folder.savePart(refs[j]);
					}
				}	
			}	
			
			_pageVars[page].savingStillTriggering = false;
			
			if (_pageVars[page].savingPageRefs.length == 0)
			{
				completeSave(page);
			}	
		}
		
		private function onPartSaveComplete(e:PotomacEvent):void
		{			 
			if (_pageVars[e.page] == undefined || _pageVars[e.page] == null)
				return;
			
			if (_pageVars[e.page].saving == true)
			{
				var savingArray:Array = _pageVars[e.page].savingPageRefs as Array;
				savingArray.splice(savingArray.indexOf(e.partReference),1);
				
				if (savingArray.length == 0 && _pageVars[e.page].savingStillTriggering == false)
				{
					completeSave(e.page);
				}
			}	
			
		}
		
		private function onPartDirtyChange(e:PotomacEvent):void
		{
			_template.dispatchEvent(new TemplateEvent(TemplateEvent.PAGE_DIRTY_CHANGE,null,null,null,null,e.page,true));
		}
		
		private function onPartClosed(e:PotomacEvent):void
		{
			_template.dispatchEvent(new TemplateEvent(TemplateEvent.PAGE_DIRTY_CHANGE,null,null,null,null,e.page,true));
		}
		
		private function onPartSaveError(e:PotomacEvent):void
		{
			if (_pageVars[e.page].saving == true)
			{
				var savingArray:Array = _pageVars[e.page].savingPageRefs as Array;
				savingArray.splice(savingArray.indexOf(e.partReference),1);
				
				_pageVars[e.page].savingError = true;
				
				if (savingArray.length == 0 && _pageVars[e.page].savingStillTriggering == false)
				{
					completeSave(e.page);
				}
			}	
		}
		
		private function completeSave(page:Page):void
		{
			if (_pageVars[page].savingError != true)
			{
				dispatchEvent(new PotomacEvent(PotomacEvent.PAGE_SAVED,null,page));
			}
			else
			{
				dispatchEvent(new PotomacEvent(PotomacEvent.PAGE_SAVE_ERROR,null,page));
			}
			
			_pageVars[page].saving = false;
			
			if (_pageVars[page].closing == true)
			{
				_pageVars[page].closing = false;
				if (_pageVars[page].savingError != true)
				{
					closePage(page,false);
				}
			}
		}
		
		/**
		 * Makes the given page visible (ex. selects its tab).
		 *  
		 * @param page page to show.
		 * 
		 */
		public function showPage(page:Page):void
		{
			_template.dispatchEvent(new TemplateEvent(TemplateEvent.SHOW_PAGE,null,null,null,null,page,true));
		}
		
		/**
		 * Returns the page with the given id and input or null if no matching page is found.
		 *  
		 * @param id id of page to find.
		 * @param input input of page to find.
		 * @return Page instance or null if no matching page is found.
		 * 
		 */
		public function findPage(id:String,input:PageInput=null):Page
		{
			for(var i:int = 0; i < _pages.length; i++)
			{
				if (id == _pages[i].id)
				{
					if (input == null)
					{
						if (_pages[i].input == null)
							return _pages[i];
					}
					else
					{
						if (input.equals(_pages[i].input))
							return _pages[i];
					}
				}
			}
			return null;
		}
		
		/**
		 * Dispatches the given event on all parts on all pages.
		 *  
		 * @param e event to dispatch.
		 * 
		 */
		public function dispatchEventToParts(e:Event):void
		{
			for(var i:int = 0; i < _pages.length; i++)
			{
				var folders:Array = _pages[i].getFolders();
				for (var j:int = 0; j< folders.length; j++)
				{
					var folder:Folder = folders[j] as Folder;
					var refs:Array = folder.getPartReferences();
					for (var k:int = 0; k < refs.length; k++)
					{
						var partRef:PartReference = PartReference(refs[k]);
						if (partRef.control != null)
							partRef.control.dispatchEvent(e);
					}	
				}
			}
		}

	}
}