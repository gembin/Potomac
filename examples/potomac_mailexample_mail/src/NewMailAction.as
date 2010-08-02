package
{
	import potomac.ui.Action;
	import potomac.ui.Folder;
	import potomac.ui.Page;
	import potomac.ui.PartInput;
	import potomac.ui.PotomacUI;

	[Action(label="New Mail",icon="newmail.png")]
	public class NewMailAction extends Action
	{
		private var _potomacUI:PotomacUI
		
		[Inject]
		public function NewMailAction(potomacUI:PotomacUI)
		{		
			_potomacUI = potomacUI;	
		}
		
		override public function run():void
		{
			var page:Page = _potomacUI.findPage("mailpage");
			_potomacUI.showPage(page);
			
			var itemsFolder:Folder = page.openFolder("mail");
			var partInput:PartInput = new PartInput();
			partInput.newMail = true;
			partInput.newMailCreateDate = new Date();
			partInput.title = "Untitled";
			itemsFolder.openPart("mailitem",partInput);				
		}
		
	}
}