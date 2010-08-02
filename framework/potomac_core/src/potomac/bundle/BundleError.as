package potomac.bundle
{
	/**
	 * An error associated with bundle installation or loading. 
	 */
	public class BundleError extends Error
	{
		/**
		 * The bundle whose loading or installation has failed.
		 */
		private var bundleID:String;
		
		/**
		 * Creates a new BundleError.
		 */
		public function BundleError(message:*, bundleID:String)
		{
			this.bundleID = bundleID;  
			super(message);
		}
	}
}