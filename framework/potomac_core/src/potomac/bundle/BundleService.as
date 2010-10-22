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
package potomac.bundle
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.core.FlexGlobals;
	import mx.events.ModuleEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	import mx.preloaders.Preloader;
	import mx.utils.ObjectUtil;
	
	import potomac.core.IPotomacPreloader;
	import potomac.core.potomac;
	import potomac.inject.InjectionEvent;
	import potomac.inject.InjectionRequest;
	import potomac.inject.Injector;
	
	import spark.components.Application;
	
	/**
	* Dispatched when a bundle is loaded.
	* If the <code>isRepeat</code> property is <code>true</code>,
	* this event is repeated bundle ready event and can be ignored.
	*
	* @eventType potomac.bundle.BundleEvent.BUNDLE_READY
	*/
	[Event(name="bundleReady", type="potomac.bundle.BundleEvent")]

	/**
	 * Dispatched when a bundle installation is initiated.
	 *
	 * @eventType potomac.bundle.BundleEvent.BUNDLES_INSTALLING
	 */
	[Event(name="bundlesInstalling", type="potomac.bundle.BundleEvent")]
	
	/**
	 * Dispatched when bundle preloading is initiated.
	 *
	 * @eventType potomac.bundle.BundleEvent.BUNDLES_PRELOADING
	 */
	[Event(name="bundlesPreloading", type="potomac.bundle.BundleEvent")]
	
	/**
	 * Dispatched when a bundle file (either the assets.swf or the bundle.swf) is being downloaded.
	 *
	 * @eventType potomac.bundle.BundleEvent.BUNDLE_PROGRESS
	 */
	[Event(name="bundleProgress", type="potomac.bundle.BundleEvent")]
	
	/**
	* Dispatched when a set of bundles is installed.
	*
	* @eventType potomac.bundle.BundleEvent.BUNDLES_INSTALLED
	*/
	[Event(name="bundlesInstalled", type="potomac.bundle.BundleEvent")]

	/**
	* Dispatched when one or more extensions are added or removed from the extension registry.
	*
	* @eventType potomac.bundle.ExtensionEvent.EXTENSIONS_UPDATED
	*/
	[Event(name="extensionsUpdated", type="potomac.bundle.ExtensionEvent")]
	
	/**
	 * Dispatched when an error is encountered during bundle installation or loading.
	 *
	 * @eventType potomac.bundle.BundleEvent.BUNDLE_ERROR
	 */
	[Event(name="bundleError", type="potomac.bundle.BundleEvent")]
	
	/**
	 * Dispatched when a bundle starts loading.
	 * 
	 * @eventType potomac.bundle.BundleEvent.BUNDLE_LOADING
	 */
	[Event(name="bundleLoading",type="potomac.bundle.BundleEvent")]
	
	/**
	 * Dispatched before the bundle service starts downloading a resource or asset of
	 * a bundle.  Currently this is either an assets.swf or the main bundle.swf.
	 * 
	 * @eventType potomac.bundle.BundleEvent.PREDOWNLOAD
	 */
	[Event(name="predownload",type="potomac.bundle.BundleEvent")]
	
	/**
	 * Dispatched after the bundle service completed downloading a resource or asset of
	 * a bundle.  Currently this is either an assets.swf or the main bundle.swf.
	 * 
	 * @eventType potomac.bundle.BundleEvent.POSTDOWNLOAD
	 */
	[Event(name="postdownload",type="potomac.bundle.BundleEvent")]
	
	/**
	 * The BundleService is responsible for loading and managing bundles.  It is also the source for 
	 * all bundle metadata extensions. 
	 * 
	 * @author cgross
	 */
	public class BundleService extends EventDispatcher implements IBundleService
	{
		private static const ASSETS_FILE:String = "assets.swf";
		
		//URL where the main application SWF is loaded from.  Used to calculate relative locations
		//of bundle assets
		private var baseURL:String;
		
		//bundles is a dynamic collection where the properties are the bundle ids
		//and the values are other dynamic objects whose properties include 'moduleLoaded',
		//'bundleLoaded','moduleLoading','moduleDataLoading','requiredBundles','activatorName','activator', and temporarily 'bundleXML'.
		//also 'version','useAIRCache','moduleData'(temporary),'baseURL','url','assetURL','bundleSWFURL'
		private var bundles:Object = new Object();
		
		//A simple array that holds objects that we don't want to be garbage collected until we're
		//dont with them
		private var dontGC:Array = new Array();
		
		//dynamic collection, bundleIDs as props and the URLLoaders as values.
		private var bundleAssetLoaders:Object = new Object();
		private var bundleAssetCountdown:int = 0;
		
		//dynamic collection, bundleIDs as props and Loaders as values
		private var bundleAssetsBytesLoaders:Object = new Object();
		
		//dynamic collection,bundleIDS as props, moduleInfos as values.
		private var bundleModuleInfos:Object = new Object();
		
		//dyn collectin, bundleIDs to URLLoaders (used in AIR only)
		private var bundleLoaders:Object = new Object();

		//Array of Extensions
		private var extensions:Array = new Array();
		
		//dynamic collection, extPtID as prop and ExtensionPoint objects as values
		private var extensionPoints:Object = new Object();
				
		private var newlyAddedExtensions:Array = new Array();
		
		private var _injector:Injector;
		
		private var _enablesForFlags:Array;
		
		private var _airBundlesURL:String = "";
		/**
		 * If true, bundle caching in the local storage when running in AIR will be disabled.
		 */
		public var airDisableCaching:Boolean = true;
		
		/**
		 * @private
		 */
		public var potomacPreloader:IPotomacPreloader;
		private var currentlyInstalling:Boolean = false;
		
		private var pendingPreloads:Array = new Array();
		 
		private static var logger:ILogger = Log.getLogger("potomac.bundle.BundleService");
		
		/**
		 * Callers should not construct instances of BundleService.  It is available for 
		 * injection through <code>IBundleService</code>. 
		 */		
		public function BundleService()
		{
		  	baseURL = FlexGlobals.topLevelApplication.url;
			var rslWeirdnessIndex:int = baseURL.indexOf("/[[DYNAMIC]]/");
			if (rslWeirdnessIndex != -1)
			{
				baseURL = baseURL.substring(0,rslWeirdnessIndex);
			}
			
			var lastFowardSlash:int = baseURL.lastIndexOf("/");
			var lastTwoBackSlash:int = baseURL.lastIndexOf("\\");
			baseURL = baseURL.slice(0,Math.max(lastFowardSlash,lastTwoBackSlash) +1);
		}
		
		/**
		 * @private 
		 */		
		public function set injector(injector:Injector):void
		{
			_injector = injector;
		}
		
		/**
		 * An array of Strings determine which extensions are enabled or disabled based on the 
		 * 'enablesFor' attribute in each extension.  
		 */
		public function set enablesForFlags(flags:Array):void
		{
			_enablesForFlags = flags;
		}
		
		/**
		 * An array of Strings determine which extensions are enabled or disabled based on the 
		 * 'enablesFor' attribute in each extension.  
		 */
		public function get enablesForFlags():Array
		{
			return _enablesForFlags;
		}
		
		/**
		 * The remote URL where the bundles will be downloaded when running inside AIR.
		 */
		public function set airBundlesURL(value:String):void
		{
			_airBundlesURL = value;
			if (_airBundlesURL.charAt(_airBundlesURL.length -1) == "/")
			{
				_airBundlesURL = _airBundlesURL.substr(0,_airBundlesURL.length -1);
			}	
		}
		/**
		 * The remote URL where the bundles will be downloaded when running inside AIR. 
		 */
		public function get airBundlesURL():String
		{
			return _airBundlesURL;
		}
		
		/**
		 * Triggers the installation of one or more bundles.  This method is asynchronous.  When the 
		 * installation is complete a <code>bundlesInstalled</code> event will be dispatched.
		 * <p>
		 * This method accepts an array that may contain <code>String</code>s that contain just the simple
		 * bundle ID or <code>BundleInstallDescriptor</code>s if you need to provide more options.
		 * </p>
		 * @param installables An array of bundle IDs as <code>String</code>s or 
		 * descriptors (<code>BundleInstallDescriptor</code>s).
		 */		
		public function install(installables:Array):void
		{
			if (installables.length == 0)
				return;
			
			if (currentlyInstalling)
			{
				throw new Error("Can't initiate another bundle installation while one is currently executing.");
			}
			
			for (var i:int = 0; i < installables.length; i++)
			{
				if (!(installables[i] is String || installables[i] is BundleInstallDescriptor))
				{
					throw new ArgumentError();
				}
			}
			
			currentlyInstalling = true;
			
			dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLING));
			if (potomacPreloader != null)
				potomacPreloader.dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLING));
			
			for (i = 0; i < installables.length; i++)
			{  
				var id:String = "";
				var bundleBaseURL:String = "";
				var remote:Boolean = false;
				
				var installable:Object = installables[i];
				
				if (installable is String)
				{
					id = installable as String;
					bundleBaseURL = baseURL + "bundles/" + id;
				}
				else
				{
					var descriptor:BundleInstallDescriptor = BundleInstallDescriptor(installable);
					id = descriptor.bundleID;
					if (descriptor.url != null)
					{
						bundleBaseURL = descriptor.url;
						remote = true;
					}
					else
					{
						bundleBaseURL = baseURL + "bundles/" + id;
					}
					if (descriptor.preload)
						pendingPreloads.push(id);
				}
				
				var bundle:Object = new Object();
		        bundle.requiredBundles = null;
	        	
		        bundle.moduleLoading = false;
		        bundle.moduleLoaded = false;
		        bundle.bundleLoaded = false;
				bundle.moduleDataLoading = false;

		        bundles[id] = bundle;

//				var loader:Loader = new Loader();
//	            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onBundleAssetLoadError);
//	            loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onAssetsReady);
//				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,onProgress);
				 
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE, onAssetsReady);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onBundleAssetLoadError);
				loader.addEventListener(ProgressEvent.PROGRESS,onProgress);

	            bundleAssetLoaders[id] = loader;          				
				
			    dontGC.push(loader);
			    bundleAssetCountdown ++;
				
				var url:String = bundleBaseURL + "/" + ASSETS_FILE;
				
			    if (inAIR() && !remote)
			    {
			    	if (inAIRandBuilder())
			    	{
						url = "app:/bundles/" + id + "/" + ASSETS_FILE;
						bundleBaseURL = "app:/bundles/" + id; 
			    	}	
			    	else
			    	{
						url = airBundlesURL + "/" + id + "/" + ASSETS_FILE;
						bundleBaseURL = airBundlesURL + "/" + id;
			    	}
			    }

				bundles[id].assetURL = url;
				bundles[id].baseURL = bundleBaseURL;
				
				var request:URLRequest = new URLRequest(url);
				
				var downloadEvent:BundleEvent = new BundleEvent(BundleEvent.PREDOWNLOAD,id,false,url,0,0,null,loader,request);
				dispatchEvent(downloadEvent);
				
			    loader.load(request);
			}				
		}

		private function onProgress(event:ProgressEvent):void
		{
			var bundleID:String = "";
			var url:String = "";
			var bytesLoaded:uint = 0;
			var bytesTotal:uint = 0;

			var found:Boolean = false;
			
			for (var id:String in bundleAssetLoaders)
			{
				if (bundleAssetLoaders[id] == URLLoader(event.target))
				{					
					found = true;
					bundleID = id;
					break;
				}
			}
			
			if (found)
			{
				url = bundles[bundleID].assetURL;
				bytesLoaded = URLLoader(event.target).bytesLoaded;
				bytesTotal = URLLoader(event.target).bytesTotal;
			}
			else
			{
				for (id in bundleLoaders)
				{
					if (bundleLoaders[id] == event.target)
					{	
						bundleID = id;
						break;
					}
				}
				url = bundles[bundleID].url;
				bytesLoaded = URLLoader(event.target).bytesLoaded;
				bytesTotal = URLLoader(event.target).bytesTotal;
			}

			
			
			var bundleEvent:BundleEvent = new BundleEvent(BundleEvent.BUNDLE_PROGRESS,bundleID,false,url,bytesLoaded,bytesTotal);
			dispatchEvent(bundleEvent);
			
			if (potomacPreloader != null)
				potomacPreloader.dispatchEvent(bundleEvent);
		}
			
		private function onAssetsReady(e:Event):void
		{
			var loader:URLLoader = URLLoader(e.target);
			
			loader.removeEventListener(Event.COMPLETE, onAssetsReady);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onBundleAssetLoadError);
			loader.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			
			dontGC.splice(dontGC.indexOf(loader),1);
			
			for (var id:String in bundleAssetLoaders)
			{
				if (bundleAssetLoaders[id] == loader)
				{					
					bundleAssetLoaders[id] = null;
					delete bundleAssetLoaders[id];
					break;
				}
			}
			
			var downloadEvent:BundleEvent = new BundleEvent(BundleEvent.POSTDOWNLOAD,id,false,bundles[id].assetURL,0,0,null,loader,null);
			dispatchEvent(downloadEvent);
			
			var byteLoader:Loader = new Loader();
			byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onBundleAssetBytesLoadError);
			byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onAssetsBytesReady);
			
			bundleAssetsBytesLoaders[id] = byteLoader;          				
			
			dontGC.push(loader);
			
			var context:LoaderContext = new LoaderContext(false,ApplicationDomain.currentDomain);
			
			if ("allowLoadBytesCodeExecution" in context)
				context["allowLoadBytesCodeExecution"] = true;
			
			byteLoader.loadBytes(loader.data,context);
		}
		
		private function onBundleAssetBytesLoadError(e:IOErrorEvent):void
		{
			//we don't ever expect this unless somethings corrupted/etc
			throw new Error("Error while loading bytes of assets.swf: " + e.text);
		}
			
			
		private function onAssetsBytesReady(e:Event):void
		{
			var loader:Loader = Loader(e.target.loader);
			dontGC.splice(dontGC.indexOf(loader),1);
			
			for (var id:String in bundleAssetsBytesLoaders)
			{
				if (bundleAssetsBytesLoaders[id] == loader)
				{					
					bundleAssetsBytesLoaders[id] = null;
					delete bundleAssetsBytesLoaders[id];
					break;
				}
			}
			 
			var className:String = "PotomacAssets_" + id;
			
			var assetClass:Class = getDefinitionByName(className) as Class;
			var assetObject:Object = new assetClass();
			
			var newXML:XML = new XML(new assetObject.bundlexml());
			  
			if (inAIR() && !airDisableCaching && !bundles[id].attemptingFromCache)
		    { 
				logger.info("Checking version in cache for " + id);
		    	bundles[id].useAIRCache = false;
		    	var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
				var bundleXML:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/bundle.xml");
				if (bundleXML.exists)
				{
					var fileStreamClass:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
				    var fileStream:Object = new fileStreamClass();
				    fileStream.open(bundleXML,"read");
				    var xmlData:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
				    fileStream.close();
				    
				    var xml:XML = new XML(xmlData);
 
				    if (xml.@version == newXML.@version)
				    {
						logger.info("Using cached swf for " + id);
						bundles[id].useAIRCache = true;
				    }
					else
					{
						logger.info("Using remote swf for " + id);
					}
				}			
		    	
		    	if (!bundles[id].useAIRCache)
		    	{
				    bundleXML = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/bundle.xml");
				    fileStreamClass = getDefinitionByName("flash.filesystem.FileStream") as Class;
				    fileStream = new fileStreamClass();
				    fileStream.open(bundleXML,"write");
				    fileStream.writeUTFBytes(new assetObject.bundlexml());
				    fileStream.close();
				    
					var bundleAsset:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/" + ASSETS_FILE);
					fileStreamClass = getDefinitionByName("flash.filesystem.FileStream") as Class;
					fileStream = new fileStreamClass();
					fileStream.open(bundleAsset,"write");
					fileStream.writeUTFBytes(loader.contentLoaderInfo.bytes);
					fileStream.close();
					
				    //remove the older SWF so we make sure we don't accidentally use it later and believe
				    //its a good cached version
				    var bundleSWF:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/" + id + ".swf");
				    if (bundleSWF.exists)
				    {
				    	bundleSWF.deleteFile();
				    } 
				}
			}
			
			handleBundleXML(id,newXML);
			
		}
		
		private function handleBundleXML(bundle:String,xml:XML):void
		{
			
			parseBundleXML(bundle,xml);
			
			bundleAssetCountdown --;
			if (bundleAssetCountdown == 0)
			{
				if (pendingPreloads.length > 0)
				{
					//send preloads event
					dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_PRELOADING));
					if (potomacPreloader != null)
						potomacPreloader.dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_PRELOADING));
					
					addEventListener(BundleEvent.BUNDLE_READY,onPreloadBundleReady);
					
					//do preloads
					var preloadsClone:Array = ObjectUtil.clone(pendingPreloads) as Array;
					for (var i:int = 0; i < preloadsClone.length; i++)
					{
						loadBundle(preloadsClone[i]);
					}
				}
				else
				{
					finalizeInstall();
				}				
			}			
		}

		private function onPreloadBundleReady(event:BundleEvent):void
		{
			if (pendingPreloads.indexOf(event.bundleID) != -1)
			{
				pendingPreloads.splice(pendingPreloads.indexOf(event.bundleID),1);
				if (pendingPreloads.length == 0)
				{
					finalizeInstall();
				}
			}
		}
		
		
		
		private function finalizeInstall():void
		{
			currentlyInstalling = false;
			parseExtensions();
			dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLED));
			if (potomacPreloader != null)
				potomacPreloader.dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLED));
			
			if (newlyAddedExtensions.length >0)
			{
				var newExts:Array = newlyAddedExtensions;
				newlyAddedExtensions = new Array();
				dispatchEvent(new ExtensionEvent(ExtensionEvent.EXTENSIONS_UPDATED,newExts,new Array()));
			}			
		}
		
		private function onBundleAssetLoadError(e:IOErrorEvent):void
		{
			var loader:URLLoader = URLLoader(e.target);
			loader.removeEventListener(Event.COMPLETE, onAssetsReady);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onBundleAssetLoadError);
			loader.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			
			dontGC.splice(dontGC.indexOf(loader),1);
			
			for (var id:String in bundleAssetLoaders)
			{
				if (bundleAssetLoaders[id] == loader)
				{					
					bundleAssetLoaders[id] = null;
					delete bundleAssetLoaders[id];
					break;
				}
			}
			
			
			
			if (inAIR() && !airDisableCaching && !bundles[id].attemptingFromCache)
			{
				logger.warn("Unable to retrieve remote "+ASSETS_FILE+" for " + id + ".  Falling back to cache in app-storage.");
				//load assets.swf from app-storage
				bundles[id].useAIRCache = true;
				var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
				var bundleAssets:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/" + ASSETS_FILE);
				if (!bundleAssets.exists)					
				{
					logger.error("No cached "+ASSETS_FILE+" for " + id + " found.  Throwing original IO error.");
					handleError(id,e.text);
					return;
				}
				
				var fileStreamClass:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
				var fileStream:Object = new fileStreamClass();
				fileStream.open(bundleAssets,"read");
				var assetData:ByteArray = new ByteArray();
				fileStream.readBytes(assetData);
				fileStream.close();
					
				bundles[id].attemptingFromCache = true;
				
				var byteLoader:Loader = new Loader();
				byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onBundleAssetBytesLoadError);
				byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onAssetsBytesReady);
				
				bundleAssetsBytesLoaders[id] = byteLoader;          				
				
				dontGC.push(loader);
				
				var context:LoaderContext = new LoaderContext(false,ApplicationDomain.currentDomain);
				
				if ("allowLoadBytesCodeExecution" in context)
					context["allowLoadBytesCodeExecution"] = true;

				byteLoader.loadBytes(assetData,context);
				
				return;
			}
			
			handleError(id,e.text);
		}
		
		/**
		 * Returns an array of <code>Extension</code>s of the specified extension point.  If the
		 * className parameter is passed, it will return only those extensions declared within that
		 * class.
		 * <p>
		 * By default, when the className parameter is specified, only extensions declared directly within
		 * the specific class are returned.  Extensions declared in the base class or super classes of the
		 * specified class are not returned.  When <code>true</code> is passed for the superClass argument,
		 * all extensions declared in the entire class hierarchy are returned.  Importantly, for Potomac to
		 * be able to inspect the class hierarchy, the class specified must be available in the Flash 
		 * ApplicationDomain.  In other words, the class's bundle must be loaded.
		 * </p>
		 * @param extensionPointID extension point id of the extensions to return.
		 * @param className name of the class in which the extensions are declared.
		 * @param superClasses if true, will return extensions declared in super classes.
		 * @return an array of <code>Extension</code>s. 
		 */		
		public function getExtensions(extensionPointID:String,className:String=null,superClasses:Boolean=false):Array
		{
			use namespace potomac;
			var extensionsForPoint:Array = new Array();
			var classNameNorm:String = Injector.normalizeClassName(className);
			for (var i:int = 0; i < extensions.length; i++)
			{
				if (Extension(extensions[i]).pointID == extensionPointID && (classNameNorm == null || (extensions[i].className == classNameNorm)))
				{
					extensionsForPoint.push(extensions[i]);
				}
			}
			
			if (className != null && superClasses)
			{
				var clz:Class = getDefinitionByName(className) as Class;
				if (clz == null)
					throw new Error("Cannot parse class hierarchy when class isn't loaded (e.g. bundle isn't loaded).");
				
				classNameNorm = Injector.normalizeClassName(getQualifiedSuperclassName(clz));
				while (classNameNorm != null && className != "Object")
				{
					for (i = 0; i < extensions.length; i++)
					{
						if (Extension(extensions[i]).pointID == extensionPointID && (classNameNorm == null || (extensions[i].className == classNameNorm)))
						{
							extensionsForPoint.push(extensions[i]);
						}
					}				

					classNameNorm = getQualifiedSuperclassName(getDefinitionByName(classNameNorm));
				}
			}    
            
			return extensionsForPoint;
		}
		
		/**
		 * Returns a single <code>Extension</code> with the given id for the given extension point.
		 *  
		 * @param id extension id.
		 * @param point extension point id.
		 * @return the first matching <code>Extension</code> or null if none exists. 
		 */		
		public function getExtension(id:String,point:String):Extension
		{			
			for (var i:int = 0; i < extensions.length; i++)
			{
				if (extensions[i].pointID == point && extensions[i].id == id)
				{
					return extensions[i];
				}
			}
            
			return null;
		}
		
		/**
		 * Returns an array of ExtensionPoint objects including 
		 * each extension point in all installed bundles.
		 *  
		 * @return array of ExtensionPoints 
		 */
		public function getExtensionPoints():Array
		{
			var array:Array = new Array();
			for (var ptID:String in extensionPoints)
			{
				array.push(extensionPoints[ptID]);
			}
			
			return array;
		}
		
		
		/**
		 * Returns the extension point with the given point id.
		 *  
		 * @param pointID id/tag name of the extension point.
		 * 
		 * @return the ExtensionPoint
		 * 
		 */
		public function getExtensionPoint(pointID:String):ExtensionPoint
		{
			return extensionPoints[pointID];
		}
		
		
		/**
		 * Triggers the retrieval and load of the given bundle.  This method is asynchronous.  A 
		 * <code>bundleReady</code> event will be dispatched when the bundle is loaded.
		 * 
		 * @param id id of bundle to load. 
		 */		
		public function loadBundle(id:String):void
		{			
			if (bundles[id] == undefined)
			{
				throw new BundleError("Bundle " + id + " isn't installed.",id);
			}			
			if (isBundleLoaded(id))
			{
				//allow a single line of logic for consumers even if bundle is already loaded
				dispatchEvent(new BundleEvent(BundleEvent.BUNDLE_READY,id,true));
				return;
			}
			if (isModuleDataLoading(id))
			{
				//already loading
				return;
			}
			
			//potomac_core is the only special RSL bootstrap bundle (it should never be loaded)
			if (id == "potomac_core")
			{
				setModuleDataLoading(id);
				setModuleLoaded(id);				
				checkSatifisfiedBundles();
				return;
			}
			
			if (inAIR())
			{
				loadModuleInAIR(id);
			}
			else
			{
				loadModuleInBrowser(id);
			}
			
			var reqs:Array = getRequiredBundles(id);
			
			for (var i:int = 0; i < reqs.length; i++)
            {
            	if (!isModuleDataLoading(reqs[i])) //dont load em if theyre already loaded/loading
            	{
            		if (inAIR())
            		{
            			loadModuleInAIR(reqs[i]);
            		}
            		else
            		{
            			loadModuleInBrowser(reqs[i]);	
            		}
            	}            	
            }               
		}
		

		
		private function loadModuleInAIR(bundle:String):void
		{
			var url:String = bundles[bundle].baseURL +"/" + bundle + ".swf";
			
			if (!inAIRandBuilder() && !airDisableCaching && bundles[bundle].useAIRCache == true)
			{
				//see if cache exists
				url = airBundlesURL + "/" + bundle + "/" + bundle + ".swf";

				var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
				var bundleSWF:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + bundle + "/" + bundle +".swf");
				if (bundleSWF.exists)
				{						
					url = bundleSWF.url;
				}
				else
				{
					logger.warn("Cached swf for " + bundle + " not found.  Falling back to remote swf.");
					url = bundles[bundle].baseURL + "/" + bundle + ".swf";
				}
			}

			loadModule(bundle,url);
		}
		
		private function loadModuleInBrowser(bundle:String):void
		{
			loadModule(bundle,bundles[bundle].baseURL + "/" + bundle + ".swf");
		}
		
		private function loadModule(bundle:String, url:String):void
		{
			bundles[bundle].bundleSWFURL = url;
			
			var event:BundleEvent = new BundleEvent(BundleEvent.BUNDLE_LOADING,bundle,false,url);
			dispatchEvent(event);
			if (potomacPreloader != null)
				potomacPreloader.dispatchEvent(event);
			
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			loader.addEventListener(ProgressEvent.PROGRESS,onProgress);
			bundleLoaders[bundle] = loader;
			setModuleDataLoading(bundle);
			bundles[bundle].url = url;
			logger.info("Loading bundle swf: "+ url);
			
			var request:URLRequest = new URLRequest(url);
			
			var downloadEvent:BundleEvent = new BundleEvent(BundleEvent.PREDOWNLOAD,bundle,false,url,0,0,null,loader,request);
			dispatchEvent(downloadEvent);
			
			loader.load(request);		
			
			
		}

		
		private function onLoaderComplete(e:Event):void
		{
			var data:ByteArray;
			
			for (var id:String in bundleLoaders)
			{
				if (bundleLoaders[id] == e.target)
				{
					data = ByteArray(URLLoader(bundleLoaders[id]).data);
					bundleLoaders[id] = null;
					delete bundleLoaders[id];
					break;
				}
			}

			bundles[id].moduleData = data;
			
			var downloadEvent:BundleEvent = new BundleEvent(BundleEvent.POSTDOWNLOAD,id,false,bundles[id].bundleSWFURL,0,0,null,URLLoader(e.target),null);
			dispatchEvent(downloadEvent);
			
			checkSatifisfiedBundles();	
		}
		
		private function onLoaderError(e:IOErrorEvent):void
		{
			for (var id:String in bundleLoaders)
			{
				if (bundleLoaders[id] == e.target)
				{					
					bundleLoaders[id] = null;
					delete bundleLoaders[id];
					break;
				}
			}
			
            e.target.removeEventListener(Event.COMPLETE,onLoaderComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR,onLoaderError);
           	handleError(id,e.text);  
		}
	    	
		private function onModuleReady(e:ModuleEvent):void
		{
			dontGC.splice(dontGC.indexOf(e.module),1);
			e.module.removeEventListener(ModuleEvent.READY,onModuleReady);
			e.module.removeEventListener(ModuleEvent.ERROR,onModuleError);
			
			
			 
			for (var id:String in bundleModuleInfos)
			{
				if (bundleModuleInfos[id] == e.module)
				{				
					
					if (inAIR() && !airDisableCaching && String(bundles[id].url).substr(0,12) != "app-storage:")
					{
						var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
						var bundleSWF:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/" + id +".swf");
						var fileStreamClass:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
						var fileStream:Object = new fileStreamClass();
						fileStream.open(bundleSWF,"write");
						fileStream.writeBytes(bundles[id].moduleData);
						fileStream.close();
					}         
					                          
					bundleModuleInfos[id] = null;
					delete bundleModuleInfos[id];
					
					bundles[id].moduleData = null;
					delete bundles[id].moduleData;
					
					break;
				}
			}
			
			//id should be set after break from loop
			
			setModuleLoaded(id);

            checkSatifisfiedBundles();
		}
		
		private function onModuleError(e:ModuleEvent):void
		{
            dontGC.splice(dontGC.indexOf(e.module),1);
            e.module.removeEventListener(ModuleEvent.READY,onModuleReady);
            e.module.removeEventListener(ModuleEvent.ERROR,onModuleError);

			for (var id:String in bundleModuleInfos)
			{
				if (bundleModuleInfos[id] == e.module)
				{					
					bundleModuleInfos[id] = null;
					delete bundleModuleInfos[id];
					
					bundles[id].moduleData = null;
					delete bundles[id].moduleData;
					
					break;
				}
			}
			
			handleError(id,e.errorText);			
		}
		
		private function checkSatifisfiedBundles():void
		{
			for (var bundleID:String in bundles)
            {
                if (!isBundleLoaded(bundleID) && (isModuleLoaded(bundleID) || isModuleDataLoaded(bundleID)))//potentially now satisfied
                {
					var isReady:Boolean = isDependenciesLoaded(bundleID);
                    
                    if (isReady)
                    {
						if (isModuleLoaded(bundleID))
						{
							setBundleLoaded(bundleID);
							
							var e:BundleEvent = new BundleEvent(BundleEvent.BUNDLE_READY,bundleID);
							
							triggerActivator(bundleID,e);
							
							dispatchEvent(e);
							if (potomacPreloader != null)
								potomacPreloader.dispatchEvent(e);
							
							//start all over again from the top
							checkSatifisfiedBundles();
							break;							
						}
						else
						{
							if (!isModuleLoading(bundleID))
							{
								setModuleLoading(bundleID);
								var moduleInfo:IModuleInfo = ModuleManager.getModule(bundles[bundleID].url);
								moduleInfo.addEventListener(ModuleEvent.READY,onModuleReady);
								moduleInfo.addEventListener(ModuleEvent.ERROR,onModuleError);
								bundleModuleInfos[bundleID] = moduleInfo;
								dontGC.push(moduleInfo);
								moduleInfo.load(ApplicationDomain.currentDomain,null,bundles[bundleID].moduleData);
							}
						}
                    }
                }
            }
		}

		private function isDependenciesLoaded(bundleID:String):Boolean
		{
			var reqs:Array = getRequiredBundles(bundleID);
			var isReady:Boolean = true;
			for (var i:int = 0; i < reqs.length; i++)
			{
				if (!isBundleLoaded(reqs[i]))
				{
					isReady = false;
					break;
				}
			}
			return isReady;
		}
		
		private function isModuleLoaded(bundleID:String):Boolean
		{
			return bundles[bundleID].moduleLoaded == true;
		}		
		private function setModuleLoaded(bundleID:String):void
		{
			bundles[bundleID].moduleLoaded = true;
		}
		/**
		 * Returns true if the given bundle is loaded.
		 *  
		 * @param bundleID bundle id to check if loaded.
		 * @return true if the bundle is loaded, otherwise false. 
		 */		
		public function isBundleLoaded(bundleID:String):Boolean
		{
			return bundles[bundleID].bundleLoaded == true;
		}
        private function setBundleLoaded(bundleID:String):void
        {
            bundles[bundleID].bundleLoaded = true;
        }
        private function isModuleLoading(bundleID:String):Boolean
        {
            return bundles[bundleID].moduleLoading == true;
        }
        private function setModuleLoading(bundleID:String):void
        {
            bundles[bundleID].moduleLoading = true;
        }
		private function isModuleDataLoaded(bundleID:String):Boolean
		{
			return bundles[bundleID].moduleData != null;
		}
		private function isModuleDataLoading(bundleID:String):Boolean
		{
			return bundles[bundleID].moduleDataLoading == true;
		}
		private function setModuleDataLoading(bundleID:String):void
		{
			bundles[bundleID].moduleDataLoading = true;
		}
		
        private function getRequiredBundles(bundleID:String):Array
        {
        	var reqs:Array = bundles[bundleID].requiredBundles;
        	for (var i:int = 0; i < reqs.length; i++)
        	{
        		var subReqs:Array = getRequiredBundles(reqs[i]);
        		addArrays(reqs,subReqs);
        	}
        	return reqs;
        }
        
        private function addArrays(main:Array,sub:Array):void
        {
        	for (var i:int = 0; i < sub.length; i++)
        	{
        		if (main.indexOf(sub[i]) == -1)
        			main.push(sub[i]);
        	}
        }
        
        private function parseBundleXML(bundleID:String,bundleXML:XML):void
        {
        	bundles[bundleID].activatorName = bundleXML.@activator;      
        	bundles[bundleID].version = bundleXML.@version;  	
			bundles[bundleID].name = bundleXML.@name;
        	
        	//required bundles
        	var reqs:Array = new Array();
        	for each (var req:XML in bundleXML.requiredBundles.bundle)
        	{
        		var reqID:String = req.text()[0]; 
        		reqs.push(reqID);
        	}
        	bundles[bundleID].requiredBundles = reqs;
        	
        	
        	//extension points
            for each (var pointXML:XML in bundleXML.extensionPoints.extensionPoint)
            {
            	var extPt:ExtensionPoint = new ExtensionPoint(pointXML);
            	extensionPoints[extPt.id] = extPt;
            }
        	
        	bundles[bundleID].bundleXML = bundleXML;
        	
 			//extension parsing happens after initialization
        	
        }
        
        private function parseExtensions():void
        {
        	for (var bundleID:String in bundles)
        	{
        		var bundleXML:XML = bundles[bundleID].bundleXML;
				if (bundleXML == null)
					continue; //this means the bundle was installed previously
	            for each (var extXML:XML in bundleXML.extensions.extension)
	            {
	            	var point:String = extXML.attribute("point").toString();
	            	if (!extensionPoints.hasOwnProperty(point))
	            		continue;
	            	if (!isEnabled(extXML))
	            		continue;
	            	var ext:Extension = new Extension(extXML,extensionPoints[point],baseURL);
	            	extensions.push(ext);
	            	newlyAddedExtensions.push(ext);
	            }        
	            bundleXML = null;
	            bundles[bundleID].bundleXML = null;
	            delete bundles[bundleID].bundleXML;     		
        	}        	
        }
        
        private function isEnabled(extXML:XML):Boolean
        {
        	if (extXML.hasOwnProperty("@enablesFor"))
        	{
        		var enablesFor:String = extXML.@enablesFor;
        		var enables:Array = enablesFor.split(",");
        		var foundMinus:Boolean = false;
        		
        		for (var i:int = 0; i < enables.length; i++)
        		{
        			if (String(enables[i]).charAt(0) == "-")
        			{
        				foundMinus = true;
        				if (_enablesForFlags.indexOf(String(enables[i]).substr(1)) != -1)
        				{
        					return false;
        				}
        			}
        			else
        			{
        				if (_enablesForFlags.indexOf(enables[i]) != -1)
        				{
        					return true;
        				}        				
        			}
        		}
        		if (foundMinus)
        		{
        			return true;
        		}
        		else
        		{
        			return false;
        		}
        	}
        	return true;
        }
        
        
        private function triggerActivator(bundleID:String,event:BundleEvent):void
        {
            if (bundles[bundleID].activatorName != null && bundles[bundleID].activatorName != "" &&
				bundles[bundleID].activator == null)
            {
				var request:InjectionRequest = _injector.getInstance(bundles[bundleID].activatorName);
				request.activatorEvent = event;
				request.activatorBundleID = bundleID;
				request.addEventListener(InjectionEvent.INSTANCE_READY,onActivatorReady);
				request.start();
            }
        }
		
		private function onActivatorReady(event:InjectionEvent):void
		{
			var activator:IEventDispatcher = event.instance as IEventDispatcher;
			//in the futre, when stopping is added, we'll need to save the activator like this to call stop on it later
			bundles[event.target.activatorBundleID].activator = activator;
			activator.dispatchEvent(event.target.activatorEvent as Event);
		}
        
        private function inAIR():Boolean
        {
        	return Capabilities.playerType == "Desktop";
        }
        
        private function inAIRandBuilder():Boolean
        {
        	var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
        	var bundlesDir:Object = fileClass.applicationDirectory.resolvePath("bundles/");
        	return bundlesDir.exists;
        }

		private function handleError(bundleID:String,message:String):void
		{
			var throwIt:Boolean = true;
			var event:BundleEvent = new BundleEvent(BundleEvent.BUNDLE_ERROR,bundleID,false,null,0,0,message);
			
			if (potomacPreloader != null)
			{
				potomacPreloader.dispatchEvent(event);
				throwIt = false;
			}
			if (hasEventListener(BundleEvent.BUNDLE_ERROR))
			{
				dispatchEvent(event);
				throwIt = false;
			}
			
			if (throwIt)
				throw new BundleError(message,bundleID);
		}
		
		/**
		 * Returns the BundleDescriptor of the installed bundle with the given id.
		 * <p>
		 * This method should not be called while bundles are currently installing.
		 * </p>
		 * @param bundleID Bundle ID of the bundle whose descriptor is requested.
		 * 
		 * @return BundleDescriptor or null of no bundle is found with the given id. 
		 */
		public function getBundleDescriptor(bundleID:String):BundleDescriptor
		{
			if (bundles[bundleID] == undefined)
				return null;
			
			var swfURL:String = null;
			if (isBundleLoaded(bundleID))
				swfURL = bundles[bundleID].url;
			
			var desc:BundleDescriptor = new BundleDescriptor(bundleID,bundles[bundleID].requiredBundles,bundles[bundleID].version,bundles[bundleID].name,bundles[bundleID].assetURL,isBundleLoaded(bundleID),swfURL);
			
			return desc;
		}
		
		/**
		 * Returns an array of BundleDescriptors for all installed bundles.
		 * <p>
		 * This method should not be called while bundles are currently installing.
		 * </p>
		 */		
		public function get bundleDescriptors():Array
		{
			var array:Array = new Array();
			for (var bundleID:String in bundles)
			{
				array.push(getBundleDescriptor(bundleID));
			}
			
			return array;
		}
	}
}