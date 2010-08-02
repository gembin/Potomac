package potomac.core
{
	/**
	 * @private
	 */
	public interface ISerializer
	{
		function serialize(object:Object):String;
		
		function deserialize(data:String):Object;
	}
}