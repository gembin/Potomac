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
package potomac.inject
{
	import flash.events.IEventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.core.Application;
	import mx.core.FlexGlobals;
	import mx.utils.ArrayUtil;
	
	import potomac.bundle.Argument;
	import potomac.bundle.BundleEvent;
	import potomac.bundle.Extension;
	import potomac.bundle.IBundleService;
	import potomac.core.potomac;
	
	use namespace potomac;
	
	
	[ExtensionPoint(id="Injectable",access="public",declaredOn="classes",
					boundTo="type",implementedBy="class",named="string",
					providedBy="class:potomac.inject.IProvider",singleton="boolean",asyncInit="boolean")]
	[ExtensionPointDetails(id="Injectable",description="Binds a class for dependency injection")]
	[ExtensionPointDetails(id="Injectable",attribute="boundTo",description="Class or interface to bind the class to",order="0",common="false")]
	[ExtensionPointDetails(id="Injectable",attribute="implementedBy",description="Fully qualified class name of the implementation class. If not specified, the class where the [Injectable] was declared is assumed",order="1",common="false")]
	[ExtensionPointDetails(id="Injectable",attribute="named",description="Unique string which differentiates this binding from others bound to the same type",order="2",common="false")]
	[ExtensionPointDetails(id="Injectable",attribute="providedBy",description="Fully qualified class that implements IProvider. Providers allow programmatic control of injection class creation",order="3",common="false")]
	[ExtensionPointDetails(id="Injectable",attribute="singleton",description="If true the injector will only create one implementation instance for this binding",order="4",defaultValue="true")]
	[ExtensionPointDetails(id="Injectable",attribute="asyncInit",description="Allows the injectable to invoke asynchronous initialization code. Use sparingly!",order="5")]
	
	[ExtensionPoint(id="Inject",argumentsAsAttributes="true",access="public",
	                declaredOn="variables,methods,constructors")]
	[ExtensionPointDetails(id="Inject",description="Injects resources using dependency inject")]
	
	[ExtensionPoint(id="InjectionListener",type="flash.events.IEventDispatcher",
					declaredOn="classes",preloadRequired="true")]
	[ExtensionPointDetails(id="InjectionListener",description="Marks a class as a Potomac managed listener to all injection requests")]
	
	/**
	 * Injector is responsible for creating new classes and injecting dependencies into them.   
	 * <p>
	 * Developers may use [Inject] to trigger injection on classes created through the Injector.  
	 * The inject tag may include attribute names that match the argument or variable names to associate the arguments 
	 * with named bindings.  For example:
	 * </p>
	 * <listing>
	 * [Inject(field1="green")]
	 * public var field1:IInterface;
	 * 
	 * [Inject(arg1="red",arg3="blue")]
	 * public function injectHere(arg1:IInterface,arg2:IInterface,arg3:IInterface):void
	 * {
	 *   ...
	 * </listing>
	 * <p>
	 * Injection bindings can be created declaratively through [Injectable] or programmatically through bind().  The injectable tag supports parameters 
	 * to build out injection rules.  The attributes are:
	 * </p>
	 * <p>
	 * <table>
	 * <tr><td>boundTo</td><td>Fully qualified interface or class name that becomes the binding's front class.</td></tr>
	 * <tr><td>implementedBy</td><td>Fully qualified class name of the implementation class.  If not specified, the class where the [Injectable] was declared is assumed.</td></tr>
	 * <tr><td>named</td><td>A unique string which differentiates this binding from others bound to the same type.</td></tr>
	 * <tr><td>providedBy</td><td>A fully qualified class that implements IProvider.  Providers allow programmatic control of injection class creation.</td></tr>
	 * <tr><td>singleton</td><td>True/false.  If true the injector will only create one implementation instance for this binding.</td></tr>
	 * <tr><td>asyncInit</td><td>True/false.  If true the injector allow asynchronous initialization code before declaring the object ready.  When true, injectables must extend flash.events.EventDispatcher and dispatch an InjectInitEvent when complete.  Use sparingly as this feature is incompatible with some synchronous injection features.</td></tr>
	 * </table>
	 * </p>
	 * <p>
	 * Examples:
	 * </p>
	 * <p>
	 * <listing>
	 * [Injectable(boundTo="package.IInterface",named="green",providedBy="package.MyProvider",singleton="true")]
	 * public class InterfaceImpl {
	 *   ...
	 * </listing>
	 * </p>
	 * <p>
	 * The primary Potomac injector is available for injection.  It is bound directly to Injector.
	 * </p>
	 * @author cgross
	 */
	public class Injector
	{
		private var _injectables:Array = new Array();
		private var _manualInjectables:Array = new Array();
		private var _bundleSrv:IBundleService;
		private var _listeners:Array = new Array();
		
		//dynamic class/map with properties equal to class names and values are Arrays of Extensions
		private var _injectionPoints:Object = new Object();
		
		/**
		 * Creates a new injector.
		 * 
		 * @param bundleService The main Potomac bundle service which the Injector will use to load bundles as necessary.
		 */
		public function Injector(bundleService:IBundleService)
		{
			_bundleSrv = bundleService;
			bundleService.addEventListener(BundleEvent.BUNDLES_INSTALLED,onBundlesInstalled);
			
			bind(IBundleService).toInstance(bundleService);
			bind(Injector).toInstance(this);
		}
		
		private function onBundlesInstalled(e:BundleEvent):void
		{
			_injectables = new Array();
			var extInjectables:Array = _bundleSrv.getExtensions("Injectable");			
			for(var i:int = 0; i < extInjectables.length; i++)
			{
				var ext:Extension = extInjectables[i];
				var bundle:String = ext.bundleID;
				var boundTo:String = ext.className;
				if (ext.hasOwnProperty("boundTo"))
				{
					boundTo = ext.boundTo;
				}
				var implementedBy:String = ext.className;
				var named:String = null;
				if (ext.hasOwnProperty("named"))
				{
					named = ext.named;
				}
				var singleton:Boolean = false;
				if (ext.hasOwnProperty("singleton"))
				{
					singleton = ext.singleton;
				}
				var providedBy:String = null;
				if (ext.hasOwnProperty("providedBy"))
				{
					providedBy = ext.providedBy;
				}
				var asyncInit:Boolean = false;
				if (ext.hasOwnProperty("asyncInit"))
				{
					asyncInit = ext.asyncInit;
				}
				
				var injectable:Injectable = new Injectable(bundle,boundTo,implementedBy,named,singleton,providedBy,asyncInit);
				_injectables.push(injectable);
			}
			
			for(i = 0; i < _manualInjectables.length; i++)
			{
				_injectables.push(_manualInjectables[i]);
			}
			
			_injectionPoints = new Object();			
			var extInjects:Array = _bundleSrv.getExtensions("Inject");
			for (i = 0; i < extInjects.length; i++)
			{
				ext = extInjects[i];
				var exts:Array;
				if (_injectionPoints.hasOwnProperty(ext.className))
				{
					exts = _injectionPoints[ext.className];
				}
				else
				{
					exts = new Array();
					_injectionPoints[ext.className] = exts;
				}
				
				exts.push(ext);
			}	
			
			//populate listeners
			_listeners = new Array();
			var lisExts:Array = _bundleSrv.getExtensions("InjectionListener");
			for(i = 0; i < lisExts.length; i++)
			{
				var clz:Class = getDefinitionByName(lisExts[i].className) as Class;
				_listeners.push(getInstanceImmediate(clz));
			}
		}

		/**
		 * Starts the creation of a injection binding to the given class.  Use the returned INamer to 
		 * continue to injection binding.  Continue to use the returned object from subsequent calls to
		 * build the binding.
		 * 
		 * @example The following code sets a binding on IInterface named "myName" to IImplementation as a singleton:
		 * <listing version="3.0"> 
		 * myInjector.bind(IInterface).named("myName").toClass(IImplementation).asSingleton(); 
		 * </listing> 
		 *  
		 * @param clazz Class instance of a class or interface to create a binding for.
		 * @return an INamer allowing further creation of the binding. 
		 */
		public function bind(clazz:Class):INamer
		{
			if (clazz == null)
				throw new ArgumentError();
				
			var injectable:Injectable = new Injectable(null,normalizeClassName(getQualifiedClassName(clazz)));
			_injectables.push(injectable);
			_manualInjectables.push(injectable);
			return new Binder(injectable);			
		}

		/**
		 * Creates an instance (asynchronously) of the given injection rule.  If a listener function is given, the listener will be 
		 * called automatically when the instance is created, otherwise the caller must add a listener to the returned
		 * InjectionRequest.
		 *  
		 * @param className  Class name of the binding.
		 * @param named Name attribute of the binding.
		 * @param listener Function to call when creation and injection are complete.
		 * @return An injection request.  If the caller supplied a listener function, the return value can be safely 
		 * ignored.
		 * 
		 */
		public function getInstance(className:String,named:String=null,listener:Function=null):InjectionRequest
		{
			if (className == null || className == "")
				throw new ArgumentError();
				
			var injRequest:InjectionRequest = new InjectionRequest(_bundleSrv,this,className,named,null);
			if (listener != null)
			{
				injRequest.addEventListener(InjectionEvent.INSTANCE_READY,listener);
				FlexGlobals.topLevelApplication.callLater(injRequest.start);
			}	
			
			return injRequest;
		}
		
		/**
		 * Creates an instance (asynchronously) of the class where the given extension was declared.  If a listener function
		 * is given, the listener will be called automatically when the instance is created, otherwise the caller must add
		 * a listener to the returned InjectionRequest.
		 *  
		 * @param extension Extension whose declaring class should be created.
		 * @param listener Listener fired when the instance is created.
		 * @return An injection request.  If the caller supplied a listener function, the return value can be safely
		 * ignored.
		 * 
		 */
		public function getInstanceOfExtension(extension:Extension,listener:Function=null):InjectionRequest
		{
			if (extension == null)
				throw new ArgumentError();
			
			var injRequest:InjectionRequest = new InjectionRequest(_bundleSrv,this,null,null,extension);
			if (listener != null)
			{
				injRequest.addEventListener(InjectionEvent.INSTANCE_READY,listener);
				FlexGlobals.topLevelApplication.callLater(injRequest.start);
			}
			
			return injRequest; 
		}
		
		/**
		 * @private
		 */
		internal function fillReferencedBundles(clazz:Class,bundles:Array):void
		{			
			var className:String = normalizeClassName(getQualifiedClassName(clazz));
			
			if (_injectionPoints.hasOwnProperty(className))
			{
				var exts:Array = _injectionPoints[className];
				for (var i:int = 0; i < exts.length; i++)
				{
					var injectables:Array = getInjectablesForPoint(exts[i]);
					for (var j:int = 0; j < injectables.length; j++)
					{
						if (injectables[j].bundle != null && ArrayUtil.getItemIndex(injectables[j].bundle,bundles) == -1)
						{
							bundles.push(injectables[j].bundle);
						}
					}
				}
			}
			
			var superClass:String = normalizeClassName(getQualifiedSuperclassName(clazz));
			if (superClass != null)
			{
				fillReferencedBundles(getDefinitionByName(superClass) as Class,bundles);
			}
		}

		private function getInjectablesForPoints(injectionPoints:Vector.<Extension>):Array
		{
			// Called recursively, there could be a problem with cycles between Injects and Injectables, which would cause a stack overflow here
			var injectables:Array = [];
			for each (var injectionPoint:Extension in injectionPoints)
			{
				injectables = injectables.concat( getInjectablesForPoint(injectionPoint) );	
			}
			return injectables;
		}
		
		private function getInjectablesForInjectable(injectable:Injectable):Array
		{
			if (!((injectable.implementedBy) && _injectionPoints.hasOwnProperty(injectable.implementedBy)))
			{
				return [];
			}
			return getInjectablesForPoints( Vector.<Extension>(_injectionPoints[injectable.implementedBy]) );
		}
		
		private function getInjectablesForPoint(injectionPoint:Extension):Array
		{
			var injectables:Array = new Array();
			var injectable:Injectable;
			
			if (injectionPoint.declaredOn == Extension.DECLAREDON_VARIABLE)
			{
				injectable = getInjectable(injectionPoint.variable.type,injectionPoint.variable.metadata);
				if (injectable != null)
				{
					injectables.push(injectable);
					injectables = injectables.concat( getInjectablesForInjectable(injectable) );
				}
			}
			else
			{
				var args:Array;
				
				if (injectionPoint.declaredOn == Extension.DECLAREDON_CONSTRUCTOR)
				{
					args = injectionPoint.constructor.arguments;
				}
				else
				{
					args = injectionPoint.method.arguments;
				}
				
				for (var i:int = 0; i < args.length; i++)
				{
					injectable = getInjectable(Argument(args[i]).type,Argument(args[i]).metadata);
					if (injectable != null)
					{
						injectables.push(injectable);
						injectables = injectables.concat( getInjectablesForInjectable(injectable) );
					}
				}
				
			}
			
			return injectables;
		}

		/**
		 * Creates an instance (synchronously) of the given injection binding.  This method should be used with caution as it 
		 * assumes all necessary bundles are loaded to satisfy the injection requests.  
		 *  
		 * @param clazz Class of the injection binding.
		 * @param named Name attribute of the injection binding.
		 * @return An instance of the injection binding.
		 * 
		 */
		public function getInstanceImmediate(clazz:Class,named:String=null):Object
		{
			if (clazz == null)
				throw new ArgumentError();
			
			var className:String = normalizeClassName(getQualifiedClassName(clazz));
			
			return getInstanceImmediateByName(className,named);
		}
		
		/**
		 * @private
		 */
		internal function getInstanceImmediateByName(className:String,named:String):Object
		{
			//find injectable
			var injectable:Injectable = getInjectable(className,named);
			
			if (injectable == null && named != null)
				throw new Error("Injector cannot find an Injectable for " + className + " named = " + named + ".");
				
		
			var obj:Object;
			if (injectable != null)
			{
				obj = injectable.getInstance(this);
				if (injectable.needsInjection())
					injectInto(obj);
			}
			else
			{
				obj = doCreation(className);
				injectInto(obj);
			}		
			
			return obj;
		}
				
		/**
		 * @private
		 */
		internal function doCreation(className:String):Object
		{
			var obj:Object; 
			try{
				var clazz:Class = getDefinitionByName(className) as Class;
			} catch (e:ReferenceError)
			{
				throw new Error("Unable to load " + className + ".  Ensure the class is included in the project's build path.");
			}

			var constructorExt:Extension;
			
			if (_injectionPoints.hasOwnProperty(className))
			{
				var injPoints:Array = _injectionPoints[className];
				for (var i:int = 0; i < injPoints.length; i++)
				{
					if (Extension(injPoints[i]).declaredOn == Extension.DECLAREDON_CONSTRUCTOR)
					{
						if (constructorExt == null)
						{
							constructorExt = injPoints[i];
							break;
						}
					}
				}	
			}
			
			if (constructorExt != null)
			{
				var argsMeta:Array = constructorExt.constructor.arguments;
				var args:Array = new Array();
				for (var j:int = 0; j < argsMeta.length; j ++)
				{
					var arg:Argument = argsMeta[j];
					args.push(getInstanceImmediateByName(arg.type,arg.metadata));
				}	
				
				obj = doBigNasty(clazz,args);			
			}
			else
			{
				obj = new clazz();
				//todo: catch here throw better error
			}
			return obj;
		}
		
		/**
		 * Injects dependencies into the given object.
		 */
		public function injectInto(object:Object):void
		{
			if (object == null)
				throw new ArgumentError();
			
			var injectionPoints:Object = new Object();
			fillInjectionPoints(getDefinitionByName(getQualifiedClassName(object)) as Class,injectionPoints);
			
			//first do variables
			for (var injPointName:String in injectionPoints)
			{
				if (Extension(injectionPoints[injPointName]).declaredOn == Extension.DECLAREDON_VARIABLE)
				{
					object[injPointName] = getInstanceImmediateByName(Extension(injectionPoints[injPointName]).variable.type,Extension(injectionPoints[injPointName]).variable.metadata);
				} 
			}
			
			//now do methods
			for (injPointName in injectionPoints)
			{
				if (Extension(injectionPoints[injPointName]).declaredOn == Extension.DECLAREDON_METHOD)
				{
					var injPoint:Extension = Extension(injectionPoints[injPointName]);
					var args:Array = injPoint.method.arguments;
					var actualArgs:Array = new Array();
					for(var i:int = 0; i < args.length; i ++)
					{
						actualArgs.push(getInstanceImmediateByName(Argument(args[i]).type,Argument(args[i]).metadata));
					}
					object[injPointName].apply(object,actualArgs);
				} 				
			}
			
			var event:InjectionEvent = new InjectionEvent(InjectionEvent.POST_INJECTION,null,null,null,object);
			for (i = 0; i < _listeners.length; i++)
			{				
				IEventDispatcher(_listeners[i]).dispatchEvent(event);
			}			
		}
		
		
		private function fillInjectionPoints(clazz:Class,injectionPoints:Object):void
		{
			var className:String = normalizeClassName(getQualifiedClassName(clazz));
			
			if (_injectionPoints.hasOwnProperty(className))
			{
				var exts:Array = _injectionPoints[className];
				for (var i:int = 0; i < exts.length; i++)
				{
					var injPoint:Extension = Extension(exts[i]);
					if (injPoint.declaredOn == Extension.DECLAREDON_CONSTRUCTOR)
					{
						continue;
					}
					else if (injPoint.declaredOn == Extension.DECLAREDON_VARIABLE)
					{
						if (!injectionPoints.hasOwnProperty(injPoint.variable.name))
						{
							injectionPoints[injPoint.variable.name] = injPoint;
						}
					}
					else if (injPoint.declaredOn == Extension.DECLAREDON_METHOD)
					{
						if (!injectionPoints.hasOwnProperty(injPoint.method.name))
						{
							injectionPoints[injPoint.method.name] = injPoint
						}
					}					
				}
			}
			
			var superClass:String = normalizeClassName(getQualifiedSuperclassName(clazz));
			if (superClass != null)
			{
				fillInjectionPoints(getDefinitionByName(superClass) as Class,injectionPoints);
			}
		}
		
		/**
		 * @private
		 */
		internal function getInjectable(className:String,named:String):Injectable
		{
			var injectable:Injectable;
			for(var i:int = 0; i < _injectables.length; i++)
			{
				if (Injectable(_injectables[i]).matches(className,named))
				{
					injectable = _injectables[i];
					break;
				}
			}
			
			return injectable;
		}
		
		/**
		 * @private 
		 */
		potomac static function normalizeClassName(className:String):String
		{
			if (className == null) return null;
			return className.replace("::",".");
		}
		
		private function doBigNasty(clazz:Class,args:Array):Object
		{
			var obj:Object;
			
			if (args.length > 25)
				throw new Error("Potomac only supports constructor injection with 25 parameters or less.");
				
			switch (args.length)
			{
				case 1:
					obj = new clazz(args[0]);
					break;
				case 2:
					obj = new clazz(args[0],args[1]);
					break;
				case 3:
					obj = new clazz(args[0],args[1],args[2]);
					break;
				case 4:
					obj = new clazz(args[0],args[1],args[2],args[3]);
					break;					
				case 5:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4]);
					break;					
				case 6:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5]);
					break;
				case 7:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
					break;
				case 8:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
					break;
				case 9:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
					break;
				case 10:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
					break;
				case 11:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10]);
					break;
				case 12:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11]);
					break;
				case 13:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12]);
					break;
				case 14:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13]);
					break;
				case 15:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14]);
					break;
				case 16:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15]);
					break;
				case 17:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16]);
					break;					
				case 18:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17]);
					break;					
				case 19:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18]);
					break;
				case 20:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19]);
					break;
				case 21:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20]);
					break;
				case 22:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20],args[21]);
					break;
				case 23:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20],args[21],args[22]);
					break;
				case 24:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20],args[21],args[22],args[23]);
					break;					
				case 25:
					obj = new clazz(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20],args[21],args[22],args[23],args[24]);
					break;
				default:
					obj = new clazz();
			}			
			
			return obj;
		}
	}
}