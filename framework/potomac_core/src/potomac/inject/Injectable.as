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
	import flash.utils.getDefinitionByName;
	
	internal class Injectable
	{
		private var _boundTo:String;
		private var _implementedBy:String;
		private var _named:String;
		private var _providedBy:String;
		private var _providerInstance:IProvider;
		private var _singleton:Boolean;
		
		private var _bundle:String;
		
		private var _singleInstance:Object = null;
		//tells the injector not to re-inject into singleton instances
		private var _needsInjection:Boolean = true;
		
		public function Injectable(bundle:String,boundTo:String,implementedBy:String=null,named:String=null,singleton:Boolean=false,providedBy:String=null)
		{
			_bundle = bundle;
			_boundTo = boundTo;
			_implementedBy = implementedBy;
			_named = named;
			_singleton = singleton;
			_providedBy = providedBy;			
		}
		
		public function get boundTo():String
		{
			return _boundTo;
		}
		
		public function get named():String
		{
			return _named;
		}
		
		public function get bundle():String
		{
			return _bundle;
		}
		
		public function get implementedBy():String
		{
			return _implementedBy;
		}
		
		public function set implementedBy(val:String):void
		{
			_implementedBy = val;
		}
		
		public function set named(val:String):void
		{
			_named = val;
		}
		
		public function set providedBy(val:String):void
		{
			_providedBy = val;
		}
		public function set providerInstance(val:IProvider):void
		{
			_providerInstance = val;
		}
		
		public function set instance(val:Object):void
		{
			_singleton = true;
			_singleInstance = val;
		}
		
		public function set asSingleton(val:Boolean):void
		{
			_singleton = val;
		}
		
		internal function matches(className:String,isNamed:String):Boolean
		{
			if (_boundTo != className)
				return false;
				
			if (isNamed == null && _named == null)
				return true;
				
			return isNamed == _named;
		}
		
		internal function needsInjection():Boolean
		{
			return _needsInjection;
		}
		
		//assumes all necessary bundles are loaded
		internal function getInstance(injector:Injector):Object
		{
			if (_singleton && _singleInstance != null)
			{
				_needsInjection = false;
				return _singleInstance;
			}
			
			var obj:Object;
			
			if (_providedBy != null)
			{
				var provider:IProvider = _providerInstance;
				if (provider == null)
				{
					provider = injector.doCreation(_providedBy) as IProvider;
					injector.injectInto(provider);
				}
				obj = provider.getInstance();			
			}
			else if (_implementedBy != null)
			{
				obj = injector.doCreation(_implementedBy);
			} 
			else
			{
				obj = injector.doCreation(_boundTo);				
			}
			
			if (_singleton)
			{
				_singleInstance = obj;
			}
			
			return obj;
		}

	}
}