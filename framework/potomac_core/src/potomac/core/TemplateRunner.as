/*******************************************************************************
 *  Copyright (c) 2010 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package potomac.core
{
	import flash.utils.getDefinitionByName;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.inject.InjectionEvent;
	import potomac.inject.Injector;
	
	/**
	 * Default application startup logic for Potomac applications.  Creates the 
	 * template specified in the appManifest.xml and loads the default parts
	 * and pages.
	 * 
	 */
	public class TemplateRunner extends LaunchRunner
	{
		
		private var _templateID:String;
		private var _templateData:Object;
		private var _injector:Injector;

		/**
		 * Called by the PotomacInitializer (automatically generated code in the 
		 * application project).
		 * 
		 * @param templateID  template ID specified in the appManifest
		 * @param templateData template properties specified in the appManifest
		 * 
		 */
		public function TemplateRunner(templateID:String, templateData:Object)
		{
			this._templateID = templateID;  
			this._templateData = templateData;  
			super();
		}


		/**
		 * Creates the template and loads the default parts and pages.
		 */
		override public function run(bundleService:IBundleService, injector:Injector):void
		{
			_injector = injector;
			
			var exts:Array = bundleService.getExtensions("Template");
			
			var ext:Extension;
			for(var i:int = 0; i < exts.length; i++)
			{
				if (exts[i].id == _templateID)
				{
					ext = exts[i];
					break;
				}
			}
			
			if (ext == null)
			{
				throw new Error("Unable to find template with id '" + _templateID + "'.");
			}
			
			injector.getInstanceOfExtension(ext,onTemplateReady);			
		}

		
		private function onTemplateReady(e:InjectionEvent):void
		{					
			var template:UIComponent = e.instance as UIComponent;
			FlexGlobals.topLevelApplication.addElementAt(template,0);			

			//Using reflection to get the class here so core doesn't have any references to UI
			//(but obviously there's a code dependency here)
			var pUIClass:Class = getDefinitionByName("potomac.ui.PotomacUI") as Class;
			
			var pUI:Object = _injector.getInstanceImmediate(pUIClass);
			
			pUI.initializeTemplate(template,_templateData);
			
			dispatchEvent(new StartupEvent(StartupEvent.LAUNCHRUNNER_COMPLETE));			
		}
	}
}