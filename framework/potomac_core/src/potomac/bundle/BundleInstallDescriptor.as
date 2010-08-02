package potomac.bundle
{
	/**
	 * A parameter object containing the options necessary when installing bundles.
	 * <p>
	 * WARNING:  Using the url property of a BundleInstallDescriptor allows bundles to be loaded from a domain
	 * other than the one which served the main applications.  Currently, all Potomac bundles are loaded into
	 * the primary ApplicationDomain and SecurityDomain.  Extreme care should be taken when using the url property
	 * to ensure that the bundles are trusted. 
	 * </p>
	 */
	public class BundleInstallDescriptor
	{
		private var _bundleID:String;
		private var _url:String;
		private var _preload:Boolean;
		
		/**
		 * Creates a descriptor.
		 * 
		 * @param bundleID The id of the bundle to install.
		 * @param url The url of the bundle if the bundle does not exist in the standard location.
		 */
		public function BundleInstallDescriptor(bundleID:String,preload:Boolean=false,url:String=null)
		{
			this._bundleID = bundleID;  
			this._preload = preload;
			this._url = url;  
		}

		/**
		 * True if the bundle should be preloaded (loaded at immediately after installation).
		 */
		public function get preload():Boolean
		{
			return _preload;
		}

		/**
		 * The bundle ID.
		 */
		public function get bundleID():String
		{
			return _bundleID;
		}

		/**
		 * The bundle url or null.  When null, the bundle is assumed to be located in a 'bundles' directory located
		 * in the location where the main application was served.
		 * <p>
		 * WARNING:  When specifying a url value you may potentially allow a bundle from another domain to be loaded
		 * into your application.  Currently, all Potomac bundles are loaded in the same ApplicationDomain and SecurityDomain.
		 * Extreme care should be taken to ensure that all bundles loaded this way are trusted.
		 * </p>
		 */
		public function get url():String
		{
			return _url;
		}

	}
}