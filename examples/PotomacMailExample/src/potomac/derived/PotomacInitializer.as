package potomac.derived {
   import flash.events.Event;
   import flash.utils.ByteArray;
   import mx.core.Application;
   import mx.events.FlexEvent;
   import potomac.ui.restricted.Launcher;
   public class PotomacInitializer {
      [Embed(source="appCargo.xml", mimeType="application/octet-stream")]
      private var appCargoData:Class;
      private var templateID:String = "potomac_dark";
      [Embed(source="C:/Users/cgross/runtime-New_configuration/PotomacMailExample/src/logo1.png")]
      private var templateProp_logo:Class;
      private var templateData:Object = {logo:new templateProp_logo()};
      private var extAssets:ExtensionAssets;
      private var styleReferences:StyleReferences;
      private var enablesForFlags:Array = [];
      public function PotomacInitializer(){
         Application.application.addEventListener(FlexEvent.APPLICATION_COMPLETE,go);
      }
      public function go(e:Event):void {
         var bytes:ByteArray = new appCargoData() as ByteArray;
         var appCargo:XML = new XML(bytes.readUTFBytes(bytes.length));
         Launcher.launch(appCargo,templateID,templateData,enablesForFlags);
      }
   }
}