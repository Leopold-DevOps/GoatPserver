package kabam.rotmg.ui.view
{
   import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.ui.BoostPanelButton;
import com.company.assembleegameclient.ui.ExperienceBoostTimerPopup;
import com.company.assembleegameclient.ui.IconButton;
   import com.company.ui.SimpleText;
   import com.company.util.AssetLibrary;
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import org.osflash.signals.Signal;
   import org.osflash.signals.natives.NativeSignal;
   
   public class CharacterDetailsView extends Sprite
   {
      
      public static const NEXUS_BUTTON:String = "NEXUS_BUTTON";
      
      public static const OPTIONS_BUTTON:String = "OPTIONS_BUTTON";
       
      
      private var portrait_:Bitmap;
      
      private var button:IconButton;
      
      private var nameText_:SimpleText;
      
      private var nexusClicked:NativeSignal;
      
      private var optionsClicked:NativeSignal;
      
      public var gotoNexus:Signal;
      
      public var gotoOptions:Signal;

      private var boostPanelButton:BoostPanelButton;

      private var expTimer:ExperienceBoostTimerPopup;
      
      public function CharacterDetailsView()
      {
         this.portrait_ = new Bitmap(null);
         this.nameText_ = new SimpleText(20,11776947,false,0,0);
         this.nexusClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.optionsClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.gotoNexus = new Signal();
         this.gotoOptions = new Signal();
         super();
      }
      
      public function init(playerName:String, buttonType:String) : void
      {
         this.createPortrait();
         this.createNameText(playerName);
         this.createButton(buttonType);
      }
      
      private function createButton(buttonType:String) : void
      {
         if(buttonType == NEXUS_BUTTON)
         {
            this.button = new IconButton(AssetLibrary.getImageFromSet("lofiInterfaceBig",6),"Nexus","escapeToNexus");
            this.nexusClicked = new NativeSignal(this.button,MouseEvent.CLICK,MouseEvent);
            this.nexusClicked.add(this.onNexusClick);
         }
         else if(buttonType == OPTIONS_BUTTON)
         {
            this.button = new IconButton(AssetLibrary.getImageFromSet("lofiInterfaceBig",5),"Options","options");
            this.optionsClicked = new NativeSignal(this.button,MouseEvent.CLICK,MouseEvent);
            this.optionsClicked.add(this.onOptionsClick);
         }
         /* The wrench (idx 5) fills its whole 16x16 cell while the tab icons
            (idx 24/25/30) use only ~10-11px of theirs, so it renders oversized
            beside them - scale the visible art to match. The button origin is
            then its content centre, and HUDView places that origin exactly
            where TabView centres a tab icon. */
         this.button.scaleX = this.button.scaleY = 11 / 16;
         this.button.centreIconOnContent();
         this.button.x = 0;
         this.button.y = 0;
         addChild(this.button);
      }
      
      private function createPortrait() : void
      {
         /* Portrait and name are no longer shown in the right-hand pane - they
            are moving to a separate top-left HUD. The objects are still built
            and updated so update()/draw() stay valid; they are simply never
            added to the display list. */
         this.portrait_.x = -2;
         this.portrait_.y = -8;
      }
      
      private function createNameText(name:String) : void
      {
         this.nameText_.setBold(true);
         this.nameText_.x = 36;
         this.nameText_.y = 0;
         this.nameText_.filters = [new DropShadowFilter(0,0,0)];
         this.nameText_.text = name;
         this.nameText_.updateMetrics();
      }
      
      public function update(player:Player) : void
      {
         this.portrait_.bitmapData = player.getPortrait();
      }

      public function draw(_arg1:Player):void {
         if (this.expTimer) {
            this.expTimer.update(_arg1.xpTimer);
         }
         if (_arg1.dropBoost) {
            this.boostPanelButton = ((this.boostPanelButton) || (new BoostPanelButton(_arg1)));
            if (this.portrait_) {
               this.portrait_.x = 13;
            }
            if (this.nameText_) {
               this.nameText_.x = 47;
            }
            this.boostPanelButton.x = 6;
            this.boostPanelButton.y = 5;
            addChild(this.boostPanelButton);
         }
         else {
            if (this.boostPanelButton) {
               removeChild(this.boostPanelButton);
               this.boostPanelButton = null;
               this.portrait_.x = -2;
               this.nameText_.x = 36;
            }
         }
      }
      
      private function onNexusClick(event:MouseEvent) : void
      {
         this.gotoNexus.dispatch();
      }
      
      private function onOptionsClick(event:MouseEvent) : void
      {
         this.gotoOptions.dispatch();
      }
      
      public function setName(name:String) : void
      {
         this.nameText_.text = name;
      }
   }
}
