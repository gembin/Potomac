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
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	
	import potomac.bundle.Extension;
	import potomac.inject.InjectionEvent;
	import potomac.inject.InjectionRequest;
	import potomac.inject.Injector;
	import potomac.ui.Folder;
	import potomac.ui.PartEvent;
	import potomac.ui.PartExtensionManager;
	import potomac.ui.PartInput;
	import potomac.ui.PartOptions;
	import potomac.ui.PartReference;
	import potomac.ui.PotomacEvent;
	import potomac.ui.PotomacUI;
	import potomac.ui.SelectionEvent;
	import potomac.ui.SelectionService;
	import potomac.ui.restricted.BusyCanvas;

	/**
	 * @private
	 */
	public class DefaultBaseFolder extends Folder
	{

		protected var _partExtensionManager:PartExtensionManager;
		protected var _injector:Injector;
		protected var _selectionService:SelectionService;
		protected var _potomacUI:PotomacUI;
		
		/**
		 * Callers should not construct Folders.  Folders should be constructed by Page instances via the FolderFactory.
		 */
		public function DefaultBaseFolder(injector:Injector,partExtensionMgr:PartExtensionManager,selectionSrv:SelectionService,potomacUI:PotomacUI)
		{
			super();		
			_injector = injector;
			_partExtensionManager = partExtensionMgr;	
			_selectionService = selectionSrv;
			_potomacUI = potomacUI;
		}
		
		protected function findPartParent(id:String,input:PartInput=null):BusyCanvas
		{
			var kids:Array = getContainer().getChildren();
			for(var i:int = 0; i < kids.length; i++)
			{
				if (kids[i].partReference.id == id)
				{
					if (input == null)
					{
						if (kids[i].partReference.input == null) 
							return kids[i] as BusyCanvas;
					}
					else
					{
						if (kids[i].partReference.input != null)
						{
							if (input.equals(kids[i].partReference.input)) 
								return kids[i] as BusyCanvas;
						}
					}
				}	
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function openPart(id:String,input:PartInput=null,options:PartOptions=null,setFocus:Boolean=true):void
		{			
			var existing:BusyCanvas = findPartParent(id,input);
			if (existing)
			{
				if (setFocus)
					showPart(existing.partReference);
				return;
			}
			
			var ext:Extension = _partExtensionManager.getPart(id);
			if (ext == null)
				throw new Error("Unable to find part '" + id + "'.");
				
			var busyCanvas:BusyCanvas = new BusyCanvas();
			if (input != null && input.title != null)
			{
				busyCanvas.label = input.title;
			}
			else
			{
				busyCanvas.label = ext.title;
			}
			if (input != null && input.icon != null)
			{
				busyCanvas.icon = input.icon;
			}
			else
			{
				busyCanvas.icon = ext.icon;
			}
			busyCanvas.percentHeight = 100;
			busyCanvas.percentWidth = 100;
			
			getContainer().addChild(busyCanvas);
			
			afterAdd(busyCanvas);
			
			var partRef:PartReference = new PartReference(id,input,null);
			busyCanvas.partReference = partRef;
			busyCanvas.partExtension = ext;
			
			if (setFocus)
			{
				showPart(busyCanvas.partReference);
			}
			
			if (isShown(busyCanvas))
			{
				loadPart(busyCanvas);
			}
		}

		protected function afterAdd(busyCanvas:BusyCanvas):void
		{
			
		}

		//abstract
		protected function isShown(busyCanvas:BusyCanvas):Boolean
		{
			return false;
		}
		
		protected function loadPart(container:BusyCanvas):void
		{
			if (container.partLoadInitiated)
			{
				return;
			}
			container.partLoadInitiated = true;
			
			var injReq:InjectionRequest = _injector.getInstanceOfExtension(container.partExtension);
			injReq.partContainer = container;
			injReq.addEventListener(InjectionEvent.INSTANCE_READY,onInstanceReady);
			container.busy = true;
			injReq.start();
		}
		
		private function onInstanceReady(event:InjectionEvent):void
		{
			event.target.removeEventListener(InjectionEvent.INSTANCE_READY,onInstanceReady);
			var container:BusyCanvas = event.target.partContainer as BusyCanvas;
			var part:UIComponent = event.instance as UIComponent;
			part.percentHeight = 100;
			part.percentWidth = 100;
			container.addChild(part);
			container.partLoaded = true;
			container.dirty = false;
			container.partReference.control = part;
			part.addEventListener("iconChanged",onIconLabelChange);
			part.addEventListener("labelChanged",onIconLabelChange);
			part.addEventListener(PartEvent.DIRTY,onDirtyChange);
			part.addEventListener(PartEvent.CLEAN,onDirtyChange);
			part.addEventListener(PartEvent.BUSY,onBusyChange);
			part.addEventListener(PartEvent.IDLE,onBusyChange);
			part.addEventListener(PartEvent.SELECTION_CHANGED,onSelectionChanged);
			part.addEventListener(PartEvent.SAVE_COMPLETE,onSaveComplete);
			part.addEventListener(PartEvent.SAVE_ERROR,onSaveError);
			part.addEventListener(PartEvent.BROADCAST_TO_PARTS,onBroadcastEvent);
			
			container.busy = false;
			var initEvent:PartEvent = new PartEvent(PartEvent.INITIALIZE,null,container.partReference.input,this,page,pageInput);
			part.dispatchEvent(initEvent);
		}
		
		private function onBroadcastEvent(e:PartEvent):void
		{
			if (e.eventToBroadcast == null)
				return;
				
			_potomacUI.dispatchEventToParts(e.eventToBroadcast);
		}
		
		private function onBusyChange(e:PartEvent):void
		{
			if (e.type == PartEvent.BUSY)
			{
				e.target.parent.busyText = e.busyText;
			}
			e.target.parent.busy = (e.type == PartEvent.BUSY);
		}
		
		private function onDirtyChange(e:PartEvent):void
		{
			e.target.parent.dirty = (e.type == PartEvent.DIRTY);
			onIconLabelChange(e);
			_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_DIRTY_CHANGE,e.target.parent.partReference as PartReference,page));
		}
		
		private function onSelectionChanged(e:PartEvent):void
		{
			var event:SelectionEvent = _selectionService.setSelection(e.target.parent.partReference as PartReference,e.selection);
			_potomacUI.dispatchEventToParts(event);
		}
		
		private function onIconLabelChange(e:Event):void
		{
			updateIconLabel(e.target as Container);
		}
		
		protected function updateIconLabel(part:Container):void
		{
			var parent:BusyCanvas = part.parent as BusyCanvas;
			
			var dirty:String = "";
			if (parent.dirty == true)
			{
				dirty = "*";
			}
			var label:String = parent.partExtension.title;
			if (parent.partReference.input != null && parent.partReference.input.title != null)
				label = parent.partReference.input.title;
			if (part.label != null && part.label != "")
				label = part.label;
			parent.label = dirty + label;
			var icon:Class = parent.partExtension.icon;
			if (parent.partReference.input != null && parent.partReference.input.icon != null)
				icon = parent.partReference.input.icon;
			if (part.icon != null)
				icon = part.icon;

			parent.icon = icon;					
		}
		
		/**
		 * @inheritDoc
		 */
		override public function savePart(reference:PartReference):void
		{
			var busyCanvas:BusyCanvas;
			if (reference.control != null)
			{
				if (reference.control.parent.parent != getContainer())
				{
					throw new Error("Part is not a child of this folder.");
				}
				busyCanvas = reference.control.parent as BusyCanvas;
			}
			else 
			{			
				_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_SAVED,reference,page));
			}
			
			
			if (busyCanvas.saving == true)
				return;
			
			busyCanvas.busy = true;
			
			if (reference.control.hasEventListener(PartEvent.DO_SAVE))
			{
				reference.control.dispatchEvent(new PartEvent(PartEvent.DO_SAVE));
			}
			else
			{
				finishSave(reference.control,false);
			}
		}
		
		private function onSaveComplete(e:PartEvent):void
		{
			e.target.parent.dirty = false;
			onIconLabelChange(e);
			_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_DIRTY_CHANGE,e.target.parent.partReference as PartReference,page));
			finishSave(e.target as Container,true);
		}
		
		private function finishSave(part:Container,sendEvent:Boolean):void
		{			
			var busyCanvas:BusyCanvas = BusyCanvas(part.parent);
			busyCanvas.saving = false;
			if (sendEvent)
				_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_SAVED,busyCanvas.partReference as PartReference,page));
			if (busyCanvas.closing == true)
			{
				busyCanvas.closing = false; //dont prevent this following closing
				closePart(busyCanvas.partReference,false);
			}
			else
			{
				busyCanvas.busy = false;
				busyCanvas.saveError = false;
				updateIconLabel(part);
			}
		}
		
		private function onSaveError(e:PartEvent):void
		{
			e.target.parent.saving = false;
			_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_SAVE_ERROR,e.target.parent.partReference as PartReference,page));
			if (e.target.parent.closing == true)
			{
				e.target.parent.closing = false;
			}		
			e.target.parent.busy = false;
			e.target.parent.saveError = true;	
			updateIconLabel(e.target as Container);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function closePart(reference:PartReference,promptForSave:Boolean=true):void
		{
			var busyCanvas:BusyCanvas;
			if (reference.control != null)
			{
				if (reference.control.parent.parent != getContainer())
				{
					throw new Error("Part is not a child of this folder.");
				}
				busyCanvas = reference.control.parent as BusyCanvas;
			}
			else 
			{			
				var kids:Array = getContainer().getChildren();
				for (var i:int = 0; i < kids.length; i++)
				{
					if (reference.equals(kids[i].partReference))
					{
						busyCanvas = kids[i] as BusyCanvas;
						break;
					}					
				}
			}	
			if (busyCanvas == null)
			{
				throw new Error("Part not found in this folder.");
			}
			
			if (busyCanvas.closing == true)
			{
				return;
			}
			
			if (promptForSave && busyCanvas.dirty == true)
			{
				busyCanvas.closing = true;
				//put up prompt
				
				showPart(busyCanvas.partReference);
				busyCanvas.saveAlert = Alert.show("'" + busyCanvas.label.substr(1) + "' has been modified.  Save changes?","Save",
													Alert.YES | Alert.NO | Alert.CANCEL,null,onCloseSavePrompt,null,Alert.YES);
				return;
			}
			
			if (busyCanvas.partReference.control != null)
			{
				var part:Container = busyCanvas.partReference.control;
				part.removeEventListener("iconChanged",onIconLabelChange);
				part.removeEventListener("labelChanged",onIconLabelChange);
				part.removeEventListener(PartEvent.DIRTY,onDirtyChange);
				part.removeEventListener(PartEvent.CLEAN,onDirtyChange);
				part.removeEventListener(PartEvent.BUSY,onBusyChange);
				part.removeEventListener(PartEvent.IDLE,onBusyChange);
				part.removeEventListener(PartEvent.SELECTION_CHANGED,onSelectionChanged);
				part.removeEventListener(PartEvent.SAVE_COMPLETE,onSaveComplete);
				part.removeEventListener(PartEvent.SAVE_ERROR,onSaveError);
				part.removeEventListener(PartEvent.BROADCAST_TO_PARTS,onBroadcastEvent);
			}
			getContainer().removeChild(busyCanvas);
			
			loadSelected();
				
			_potomacUI.dispatchEvent(new PotomacEvent(PotomacEvent.PART_CLOSED,busyCanvas.partReference,page));
		}
		
		protected function loadSelected():void
		{
		}

		private function onCloseSavePrompt(e:CloseEvent):void
		{
				
			var kids:Array = getContainer().getChildren();
			var busyCanvas:BusyCanvas;
			for (var i:int = 0; i < kids.length; i++)
			{
				if (kids[i].saveAlert == e.target)
				{
					busyCanvas = kids[i];
					break;
				}
			}
			if (busyCanvas == null)
			{
				//this could happen if someone closes the part underneath us, not sure what is the appropriate action
				//for now, just bailing
				return;
			}
			
			if (e.detail == Alert.CANCEL)
			{
				busyCanvas.closing = false;
				//just return;
			}
			else if (e.detail == Alert.YES)
			{
				savePart(busyCanvas.partReference);	
			}
			else
			{
				busyCanvas.closing = false;  //don't want to prevent this close
				closePart(busyCanvas.partReference,false);
			}			
		}

		/**
		 * @inheritDoc
		 */
		override public function getPartReferences():Array
		{
			var refs:Array = new Array();
			var kids:Array = getContainer().getChildren();
			for (var i:int = 0; i < kids.length; i++)
			{
				refs.push(kids[i].partReference);
			}			
			
			return refs;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function findPart(id:String,input:PartInput=null):PartReference
		{
			var busyCanvas:BusyCanvas = findPartParent(id,input);
			if (busyCanvas == null)
				return null;
			
			return busyCanvas.partReference;
		}
		
		/**
		 * @inheritDoc 
		 */
		override public function getPartReference(control:Container):PartReference
		{
			if (control.parent.parent != getContainer())
			{
				throw new Error("Part not found in this folder.");
			}
			return BusyCanvas(control.parent).partReference;
		}		
		
		/**
		 * @inheritDoc
		 */
		override public function isDirty(partReference:PartReference):Boolean
		{
			if (partReference.control == null)
				return false;
				
			return BusyCanvas(partReference.control.parent).dirty;
		}
		
		/**
		* @inheritDoc
		*/
		override public function containsDirty():Boolean
		{
			var kids:Array = getContainer().getChildren();
			for (var i:int = 0; i < kids.length; i++)
			{
				if (kids[i].partReference.control != null &&
					kids[i].partReference.control.parent.dirty == true)
					{
						return true;
					}
			}	
			return false;
		}		
	}
}