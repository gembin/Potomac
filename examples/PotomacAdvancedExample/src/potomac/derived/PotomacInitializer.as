package potomac.derived {
   import flash.events.Event;
   import mx.core.FlexGlobals;
   import mx.events.FlexEvent;
   import potomac.core.Launcher;
   import potomac.core.LauncherManifest;
   import potomac.core.TemplateRunner;
   public class PotomacInitializer {
      private var bundles:Array = ["potomac_core","potomac_ui","potomac_ui_templates_dark","potomac_advancedexample_core"];
      private var preloads:Array = ["potomac_core","potomac_ui","potomac_ui_templates_dark","potomac_advancedexample_core"];
      private var templateID:String = "potomac_dark";
      private var airBundlesURL:String = "";
      private var airDisableCaching:Boolean = false;
      [Embed(source="C:/Users/cgross/workspaceFB4_Final/Potomac/examples/PotomacAdvancedExample/src/logo1.png")]
      private var templateProp_logo:Class;
      private var templateData:Object = {logo:new templateProp_logo()};
      private var enablesForFlags:Array = [];
      public function PotomacInitializer(){
         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.APPLICATION_COMPLETE,go);
         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.INITIALIZE,init);
      }
      public function init(e:Event):void {
         Launcher.findPreloader();
      }
      public function go(e:Event):void {
         var runner:TemplateRunner = new TemplateRunner(templateID,templateData);
         var manifest:LauncherManifest = new LauncherManifest();
         manifest.bundles = bundles;
         manifest.preloads = preloads;
         manifest.airBundlesURL = airBundlesURL;
         manifest.disableAIRCaching = airDisableCaching;
         manifest.enablesForFlags = enablesForFlags;
         manifest.runner = runner;
         Launcher.launch(manifest);
      }
   }
}