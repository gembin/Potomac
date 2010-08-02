package
{
	[Injectable(singleton="true")]
	public class MailDAO
	{
		private var _mailitems:Array;
		private var _fakeService:FakeService = new FakeService();
		
		public function MailDAO()
		{
		}

		public function getMail():Array
		{
			if (_mailitems == null)
			{			
				_mailitems = new Array();
				for(var i:int = 0; i < 100; i++)
				{
					_mailitems.push({id: i, from: "nobody@nowhere.com",subject: "Random Subject #" + i, received: new Date()});				
				}
			}
			return _mailitems;
		}

		public function getMailItem(id:int):Object
		{
			for (var i:int = 0; i < _mailitems.length; i++)
			{
				if (_mailitems[i].id == id)
					return _mailitems[i];
			}
			return null;
		}
		
		public function sendMail(item:Object,listener:Function):void
		{
			_fakeService.addEventListener("fakeComplete",listener);
			_fakeService.go(2000);
		}

	}
}