package
{
	import flash.events.Event;

	[Injectable(singleton="true")]
	public class FeedDAO
	{

		public function FeedDAO()
		{			
		}
		
		public function getEntries(name:String,url:String):Array
		{
			var entries:Array = new Array();
			for(var i:int = 0; i < 20; i++)
			{
				entries.push({title: name + " Post #" + i,date: new Date()});	
			}			
			return entries;
		}

	}
}