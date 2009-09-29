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
	import flash.utils.getQualifiedClassName;
	import potomac.core.potomac;
	
	internal class Binder implements INamer,ILinker,IScoper
	{
		private var _injectable:Injectable;
		
		public function Binder(injectable:Injectable)
		{
			_injectable = injectable
		}
		
		public function named(name:String):ILinker
		{
			_injectable.named = name;
			return this;
		}
		
		public function toClass(clazz:Class):IScoper
		{
			use namespace potomac;
			_injectable.implementedBy = Injector.normalizeClassName(getQualifiedClassName(clazz));
			return this;
		}
		
		public function toInstance(instance:Object):void
		{
			_injectable.instance = instance;
			return;
		}
		
		public function toProvider(providerClass:Class):IScoper
		{
			use namespace potomac;
			_injectable.providedBy = Injector.normalizeClassName(getQualifiedClassName(providerClass));
			return this;
		}
		
		public function toProviderInstance(providerInstance:IProvider):IScoper
		{
			_injectable.providerInstance = providerInstance;
			return this;
		}
		
		public function asSingleton():void
		{
			_injectable.asSingleton = true;
			return;
		}

	}
}