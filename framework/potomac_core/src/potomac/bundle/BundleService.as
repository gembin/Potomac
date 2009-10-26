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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import mx.core.Application;
	import mx.events.ModuleEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	
	import potomac.core.potomac;
	import potomac.inject.Injector;
	
	/**
	* Dispatched when a bundle is loaded.
	* If the <code>isRepeat</code> property is <code>true</code>,
	* this event is repeated bundle ready event and can be ignored.
	*
	* @eventType potomac.bundle.BundleEvent.BUNDLE_READY
	*/
	[Event(name="bundleReady", type="potomac.bundle.BundleEvent")]

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
	 * The BundleService is responsible for loading and managing bundles.  It is also the source for 
	 * all bundle metadata extensions. 
	 * 
	 * @author cgross
	 */
	public class BundleService extends EventDispatcher implements IBundleService
	{
		//URL where the main application SWF is loaded from.  Used to calculate relative locations
		//of bundle assets
		private var baseURL:String;
		
		//bundles is a dynamic collection where the properties are the bundle ids
		//and the values are other dynamic objects whose properties include 'moduleLoaded',
		//'bundleLoaded','moduleLoading','requiredBundles','rsl','activatorName','activator', and temporarily 'bundleXML'.
		//also 'version','useAIRCache'
		private var bundles:Object = new Object();
		
		//A simple array that holds objects that we don't want to be garbage collected until we're
		//dont with them
		private var dontGC:Array = new Array();
		
		//dynamic collection, bundleIDs as props and the URLLoaders as values.
		private var bundleXMLLoaders:Object = new Object();
		private var bundleXMLCountdown:int = 0;
		
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
		
		public var _airBundlesURL:String = "";
		public var airDisableCaching:Boolean = true;
		
		private static var logger:ILogger = Log.getLogger("potomac.bundle.BundleService");
		
		/**
		 * Callers should not construct instances of BundleService.  It is available for 
		 * injection through <code>IBundleService</code>. 
		 */		
		public function BundleService()
		{
			baseURL = Application.application.url;
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
		 * 
		 * @param installDescriptors An array of <code>BundleInstallDescriptor</code>s.
		 */		
		public function install(installDescriptors:Array):void
		{
			if (bundleXMLCountdown > 0)
			{
				throw new Error("Can't initiate another bundle installation while one is currently executing.");
			}
			
			for (var i:int = 0; i < installDescriptors.length; i++)
			{
				if (!(installDescriptors[i] is BundleInstallDescriptor))
				{
					throw new ArgumentError();
				}
			}
			
			for (i = 0; i < installDescriptors.length; i++)
			{
				var instDesc:BundleInstallDescriptor = BundleInstallDescriptor(installDescriptors[i]);
				
				var bundle:Object = new Object();
		        bundle.requiredBundles = null;
		        if (!instDesc.isRSL)
		        {		        	
		        	bundle.rsl = false;
			        bundle.moduleLoading = false;
			        bundle.moduleLoaded = false;
			        bundle.bundleLoaded = false;
		        }
		        else
		        {
		   			bundle.rsl = true;
		       		bundle.moduleLoading = true;
		       		bundle.moduleLoaded = true;
		       		bundle.bundleLoaded = true;
		        }
		        bundles[instDesc.bundleID] = bundle;
		        if (instDesc.isRSL)
		        {
		        	parseBundleXML(instDesc.bundleID,instDesc.bundleXML);
		        }			
		        else
		        {
					var loader:URLLoader = new URLLoader();
		            loader.addEventListener(IOErrorEvent.IO_ERROR,onBundleXMLLoadError);
		            loader.addEventListener(Event.COMPLETE,onBundleXMLReady);
	
		            bundleXMLLoaders[instDesc.bundleID] = loader;          				
					
				    dontGC.push(loader);
				    bundleXMLCountdown ++;
				    
				    if (inAIR())
				    {
				    	if (inAIRandBuilder())
				    	{
				    		loader.load(new URLRequest("app:/bundles/" + instDesc.bundleID + "/bundle.xml"));
				    	}	
				    	else
				    	{
				    		loader.load(new URLRequest(airBundlesURL + "/" + instDesc.bundleID + "/bundle.xml"));
				    	}
				    }
				    else
				    {
				    	loader.load(new URLRequest(baseURL + "bundles/" + instDesc.bundleID + "/bundle.xml"));
				    }
		        }	
			}
			
			//if all the bundles were rsls
			if (bundleXMLCountdown == 0)
			{
				parseExtensions();
				dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLED));
				
				triggerRSLActivators();
			}	
					
		}
		
		private function triggerRSLActivators():void
		{
			for (var bundleID:String in bundles)
			{
				if (bundles[bundleID].rsl)
				{
					triggerActivator(bundleID,new BundleEvent(BundleEvent.BUNDLE_READY,bundleID));
				}
			}
		}
			
		private function onBundleXMLReady(e:Event):void
		{
			var loader:URLLoader = URLLoader(e.target);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,onBundleXMLLoadError);
			loader.removeEventListener(Event.COMPLETE,onBundleXMLReady);
			dontGC.splice(dontGC.indexOf(loader),1);
			
			for (var id:String in bundleXMLLoaders)
			{
				if (bundleXMLLoaders[id] == loader)
				{					
					bundleXMLLoaders[id] = null;
					delete bundleXMLLoaders[id];
					break;
				}
			}
			
			//id should be set after break from loop
			
			var newXML:XML = new XML(loader.data);
			
			if (inAIR() && !airDisableCaching)
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
				    var xmlData:String = fileStream.readUTF();
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
				    fileStream.writeUTF(loader.data);
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
			
			bundleXMLCountdown --;
			if (bundleXMLCountdown == 0)
			{
				parseExtensions();
				dispatchEvent(new BundleEvent(BundleEvent.BUNDLES_INSTALLED));
				triggerRSLActivators();
				if (newlyAddedExtensions.length >0)
	        	{
	        		var newExts:Array = newlyAddedExtensions;
	        		newlyAddedExtensions = new Array();
	        		dispatchEvent(new ExtensionEvent(ExtensionEvent.EXTENSIONS_UPDATED,newlyAddedExtensions,new Array()));
	        	}
			}			
		}
		
		private function onBundleXMLLoadError(e:IOErrorEvent):void
		{
             var loader:URLLoader = URLLoader(e.target);
            loader.removeEventListener(IOErrorEvent.IO_ERROR,onBundleXMLLoadError);
            loader.removeEventListener(Event.COMPLETE,onBundleXMLReady);
			dontGC.splice(dontGC.indexOf(loader),1);
			
			for (var id:String in bundleXMLLoaders)
			{
				if (bundleXMLLoaders[id] == loader)
				{					
					bundleXMLLoaders[id] = null;
					delete bundleXMLLoaders[id];
					break;
				}
			}
			
			
			
			if (inAIR() && !airDisableCaching)
			{
				logger.warn("Unable to retrieve remote bundle.xml for " + id + ".  Falling back to cached bundle.xml in app-storage.");
				//load bundlexml from app-storage
				bundles[id].useAIRCache = true;
				var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
				var bundleXML:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/bundle.xml");
				if (!bundleXML.exists)					
				{
					logger.error("No cached bundle.xml for " + id + " found.  Throwing original IO error.");
					throw new Error(e.text);
				}
				
				var fileStreamClass:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
				var fileStream:Object = new fileStreamClass();
				fileStream.open(bundleXML,"read");
				var xmlData:String = fileStream.readUTF();
				fileStream.close();
					
				var xml:XML = new XML(xmlData);
	
				handleBundleXML(id,xml);
				return;
			}
			
			throw new Error(e.text);
		}
		
		/**
		 * Returns an array of <code>Extension</code>s of the specified extension point.  If the
		 * className parameter is passed, it will return only those extensions declared within that
		 * class.
		 * 
		 * @param extensionPointID extension point id of the extensions to return.
		 * @param className name of the class in which the extensions are declared.
		 * @return an array of <code>Extension</code>s. 
		 */		
		public function getExtensions(extensionPointID:String,className:String=null):Array
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
		 * Triggers the retrieval and load of the given bundle.  This method is asynchronous.  A 
		 * <code>bundleReady</code> event will be dispatched when the bundle is loaded.
		 * 
		 * @param id id of bundle to load. 
		 */		
		public function loadBundle(id:String):void
		{			
			if (bundles[id] == undefined)
			{
				throw new Error("Bundle " + id + " isn't recognized.");
			}			
			if (isBundleLoaded(id))
			{
				//allow a single line of logic for consumers even if bundle is already loaded
				dispatchEvent(new BundleEvent(BundleEvent.BUNDLE_READY,id,true));
				return;
			}
			if (isModuleLoading(id))
			{
				//already loading
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
            	if (!isModuleLoading(reqs[i])) //dont load em if theyre already loaded/loading
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
		
		private function loadModuleInBrowser(bundle:String):void
		{
			var moduleInfo:IModuleInfo = ModuleManager.getModule(baseURL + "bundles/" + bundle + "/" + bundle + ".swf");
			moduleInfo.addEventListener(ModuleEvent.READY,onModuleReady);
			moduleInfo.addEventListener(ModuleEvent.ERROR,onModuleError);
			bundleModuleInfos[bundle] = moduleInfo;
		    dontGC.push(moduleInfo);
		    setModuleLoading(bundle);
			logger.info("Loading bundle swf: " + moduleInfo.url);
		    moduleInfo.load(ApplicationDomain.currentDomain);
		}
		
		private function loadModuleInAIR(bundle:String):void
		{
			var url:String = "";
			if (inAIRandBuilder())
			{
				//load it from app:/bundles (i.e. bin-debug)
				url = "app:/bundles/" + bundle + "/" + bundle + ".swf";
			}
			else
			{				
				url = airBundlesURL + "/" + bundle + "/" + bundle + ".swf";
				if (!airDisableCaching && bundles[bundle].useAIRCache == true)
				{
					var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
			   		var bundleSWF:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + bundle + "/" + bundle +".swf");
			   		if (bundleSWF.exists)
					{						
						url = bundleSWF.url;
					}
					else
					{
						logger.warn("Cached swf for " + bundle + " not found.  Falling back to remote swf.");
					}
				 }
			}

			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			bundleLoaders[bundle] = loader;
			setModuleLoading(bundle);
			bundles[bundle].url = url;
			logger.info("Loading bundle swf: "+ url);
			loader.load(new URLRequest(url));
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
			
			if (!airDisableCaching && String(bundles[id].url).substr(0,12) != "app-storage:")
		    {
			    var fileClass:Class = getDefinitionByName("flash.filesystem.File") as Class;
			    var bundleSWF:Object = fileClass.applicationStorageDirectory.resolvePath("bundles/" + id + "/" + id +".swf");
			    var fileStreamClass:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
			    var fileStream:Object = new fileStreamClass();
			    fileStream.open(bundleSWF,"write");
			    fileStream.writeBytes(data);
			    fileStream.close();
			}

			
			var moduleInfo:IModuleInfo = ModuleManager.getModule(bundles[id].url);
			moduleInfo.addEventListener(ModuleEvent.READY,onModuleReady);
			moduleInfo.addEventListener(ModuleEvent.ERROR,onModuleError);
			bundleModuleInfos[id] = moduleInfo;
		    dontGC.push(moduleInfo);
		    moduleInfo.load(ApplicationDomain.currentDomain,null,data);			
		}
		
		private function onLoaderError(e:IOErrorEvent):void
		{
            e.target.removeEventListener(Event.COMPLETE,onLoaderComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR,onLoaderError);
            throw new Error(e.text);		
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
					bundleModuleInfos[id] = null;
					delete bundleModuleInfos[id];
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

            throw new Error(e.errorText);			
		}
		
		private function checkSatifisfiedBundles():void
		{
			for (var bundleID:String in bundles)
            {
                if (isModuleLoaded(bundleID) && !isBundleLoaded(bundleID))//potentially now satisfied
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
                    
                    if (isReady)
                    {
                        setBundleLoaded(bundleID);

						var e:BundleEvent = new BundleEvent(BundleEvent.BUNDLE_READY,bundleID);
 
						triggerActivator(bundleID,e);

                        dispatchEvent(e);
                        //start all over again from the top
                        checkSatifisfiedBundles();
                        break;
                    }
                }
            }
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
	            bundles[bundleID].bundleXML = null
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
            	try 
            	{
            	var activatorClass:Class = getDefinitionByName(bundles[bundleID].activatorName) as Class;
            	} catch(e:ReferenceError) {
            	if (activatorClass == null)
            		throw new Error("Activator class '" + bundles[bundleID].activatorName + "' for " + bundleID + " is not a valid class.");
            	}
        		var activator:IEventDispatcher = _injector.getInstanceImmediate(activatorClass) as IEventDispatcher;
        		//in the futre, when stopping is added, we'll need to save the activator like this to call stop on it later
        		bundles[bundleID].activator = activator;
        		activator.dispatchEvent(event);
            }
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

	}
}