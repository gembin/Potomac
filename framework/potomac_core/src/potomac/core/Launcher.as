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
package potomac.core
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.getDefinitionByName;
	
	import mx.containers.Canvas;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.preloaders.Preloader;
	import mx.utils.ArrayUtil;
	
	import potomac.bundle.BundleEvent;
	import potomac.bundle.BundleInstallDescriptor;
	import potomac.bundle.BundleService;
	import potomac.bundle.Extension;
	import potomac.core.IPotomacPreloader;
	import potomac.core.LaunchRunner;
	import potomac.core.LauncherManifest;
	import potomac.core.StartupEvent;
	import potomac.core.potomac;
	import potomac.inject.InjectionEvent;
	import potomac.inject.Injector;
	
	import spark.components.Application;
	import spark.components.Button;
	import spark.core.SpriteVisualElement;
	
	[ExtensionPoint(id="StartupListener",declaredOn="classes",type="flash.events.IEventDispatcher",access="public",preloadRequired="true")]
	[ExtensionPointDetails(id="StartupListener",description="Potomac managed listener for startup related events")]
	
	/**
	 * Launcher provides the main bootstrapping code for all Potomac applications.  In a regular
	 * application, Launcher is called by the automatically generated PotomacInitializer class.  
	 * <p>
	 * Sometimes its necessary to write alternative launching code for a Potomac application rather than
	 * relying on the normal autogenerated code (when running unit tests for example).
	 * </p><p>
	 * Developers who wish to run alternative code after the bootstrapping is complete 
	 * (to run unit tests for example) should provide their own LaunchRunner class in 
	 * the LauncherManifest provided to the launch method.
	 * </p>
	 */
	public class Launcher
	{
				
		private static var bundleService:BundleService;
		private static var injector:Injector;
		
		
		private static var potomacPreloader:IPotomacPreloader;
		
		private static var startupListeners:Array = new Array();
		private static var preloaderParentComponent:UIComponent;
		
		private static var runner:LaunchRunner;
		
		/**
		 * @private 
		 */		
		public static function findPreloader():void
		{
			var systemPreloader:Preloader = FlexGlobals.topLevelApplication.systemManager.mx_internal::preloader;
			potomacPreloader = findPotomacPreloader(systemPreloader);	
		}
		
		private static function findPotomacPreloader(container:DisplayObjectContainer):IPotomacPreloader
		{			
			for (var i:int = 0; i < container.numChildren; i++) 
			{
				if (container.getChildAt(i) is IPotomacPreloader)
				{
					return container.getChildAt(i) as IPotomacPreloader;
				}
				else
				{
					if (container.getChildAt(i) is DisplayObjectContainer)
					{
						var p:IPotomacPreloader = findPotomacPreloader(container.getChildAt(i) as DisplayObjectContainer);
						if (p != null)
							return p;
					}
				}
			}
			
			return null;
		}

		/**
		 * Launches Potomac and initiates the bootstrapping process.
		 * 
		 * @param manifest The manifest of launching options. 
		 */
		public static function launch(manifest:LauncherManifest):void
		{
			if (potomacPreloader != null)
			{
				preloaderParentComponent = new UIComponent();
				preloaderParentComponent.addChild(potomacPreloader as DisplayObject);
				FlexGlobals.topLevelApplication.addElement(preloaderParentComponent);
			}
			

			bundleService = new BundleService();
			bundleService.enablesForFlags = manifest.enablesForFlags;
			bundleService.airBundlesURL = manifest.airBundlesURL;
			bundleService.airDisableCaching = manifest.disableAIRCaching;	
			bundleService.potomacPreloader = potomacPreloader;
			potomacPreloader = null;
			injector = new Injector(bundleService);			
			bundleService.injector = injector;       
			
			runner = manifest.runner;
            
			bundleService.addEventListener(BundleEvent.BUNDLES_INSTALLED,onServiceReady);
			
			var descriptors:Array = new Array();
			for (var i:int = 0; i < manifest.bundles.length; i++) 
			{
				var desc:BundleInstallDescriptor = new BundleInstallDescriptor(manifest.bundles[i],manifest.preloads.indexOf(manifest.bundles[i]) != -1);
				descriptors.push(desc);
			}
			
			bundleService.install(descriptors);	
		}
		
		private static function onServiceReady(e:BundleEvent):void
		{			
			//the startuplisteners may cause more installations and we don't want to get back here unintentionally
			bundleService.removeEventListener(BundleEvent.BUNDLES_INSTALLED,onServiceReady);
			
			var exts:Array = bundleService.getExtensions("StartupListener");
			for (var i:int = 0; i < exts.length; i++) 
			{
				//since startuplisteners are required to be preloaded we can get them immediately
				var ext:Extension = Extension(exts[i]);
				var clazz:Class = getDefinitionByName(ext.className) as Class;
				var listener:IEventDispatcher =injector.getInstanceImmediate(clazz) as IEventDispatcher;
				startupListeners.push(listener);
				listener.addEventListener(StartupEvent.STARTUPLISTENER_COMPLETE,onListenerComplete);
				listener.dispatchEvent(new StartupEvent(StartupEvent.POTOMAC_INITIALIZED));
			}
			
			if (exts.length == 0)
				doRunner();
			
		}

		private static function onListenerComplete(event:Event):void
		{
			startupListeners.splice(startupListeners.indexOf(event.target),1);
			if (startupListeners.length == 0)
			{
				doRunner();
			}
		}

		
		private static function doRunner():void
		{			
			if (runner == null)
				throw new Error("LauncherRunner not specified in LauncherManifest.");
			
			runner.addEventListener(StartupEvent.LAUNCHRUNNER_COMPLETE,onRunnerComplete);
			runner.run(bundleService,injector);
		}
		
		private static function onRunnerComplete(e:StartupEvent):void
		{					
			runner.removeEventListener(StartupEvent.LAUNCHRUNNER_COMPLETE,onRunnerComplete);
			if (bundleService.potomacPreloader != null)
			{
				bundleService.potomacPreloader.addEventListener(StartupEvent.PRELOADER_CLOSE_COMPLETE,onPreloaderComplete);
				bundleService.potomacPreloader.dispatchEvent(new StartupEvent(StartupEvent.PRELOADER_CLOSE_START));
			}

		}
		
		private static function onPreloaderComplete(event:Event):void
		{
			
			if (bundleService.potomacPreloader != null)
			{
				FlexGlobals.topLevelApplication.removeElement(preloaderParentComponent);
				preloaderParentComponent = null;
				bundleService.potomacPreloader = null;
				potomacPreloader = null;
			}
		}

	}
}