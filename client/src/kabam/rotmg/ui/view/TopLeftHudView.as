package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.objects.Player;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.filters.DropShadowFilter;

import kabam.rotmg.assets.custom.images.TopLeftHud;
import kabam.rotmg.constants.AdventurerRank;

/**
 * Top-left HUD plate: class portrait, character name and the two potion slots.
 *
 * These used to live in the right-hand pane; the reskinned pane has no room
 * for them, so they moved here. Geometry is measured off TopLeftHud.png
 * (300x99) - re-measure if the art is redrawn.
 */
public class TopLeftHudView extends Sprite
{
   /**
    * Base on-screen scale. The art is authored at 240x106. Applied uniformly
    * (never as separate X/Y factors) so the panel can't end up stretched.
    */
   public static const SCALE:Number = 0.80;

   /** Class portrait recess. */
   public static const ICON_X:int = 21;
   public static const ICON_Y:int = 20;
   public static const ICON_W:int = 39;
   public static const ICON_H:int = 41;

   /**
    * Open wood between the portrait and the potion slots (band runs y 20-69).
    * Name sits on the upper line, adventurer rank on the lower one.
    */
   public static const NAME_X:int = 66;
   public static const NAME_Y:int = 26;
   public static const RANK_Y:int = 47;

   /** First potion recess; PotionInventoryView lays the second out beside it. */
   public static const POTIONS_X:int = 156;
   public static const POTIONS_Y:int = 38;

   private var portrait:Bitmap;
   private var nameText:SimpleText;
   private var rankText:SimpleText;
   private var rankShown:int = -1;
   private var potions:PotionInventoryView;

   public function TopLeftHudView()
   {
      super();
      mouseEnabled = false;

      addChild(new Bitmap(new TopLeftHud().bitmapData));

      this.portrait = new Bitmap(null);
      addChild(this.portrait);

      this.nameText = new SimpleText(16, 0xF5E6C8, false, 0, 0);
      this.nameText.setBold(true);
      this.nameText.filters = [new DropShadowFilter(0, 0, 0)];
      addChild(this.nameText);

      /* Adventurer rank, in that rank's colour (see AdventurerRank). */
      this.rankText = new SimpleText(13, 0x9CA3AF, false, 0, 0);
      this.rankText.setBold(true);
      this.rankText.filters = [new DropShadowFilter(0, 0, 0)];
      addChild(this.rankText);

      /* PotionSlotView is mapped to PotionSlotMediator by type (UIConfig), so
         the slots wire themselves up as soon as they hit the stage - nothing
         extra to inject here. mouseChildren stays on so they stay clickable. */
      this.potions = new PotionInventoryView();
      this.potions.x = POTIONS_X;
      this.potions.y = POTIONS_Y;
      addChild(this.potions);
   }

   public function setName(name:String) : void
   {
      if (name == null || this.nameText.text == name) {
         return;
      }
      this.nameText.setText(name);
      this.nameText.updateMetrics();
      /* Left-aligned against the portrait rather than floating in the middle
         of the wood panel. */
      this.nameText.x = NAME_X;
      this.nameText.y = NAME_Y;
   }

   private function setRank(rank:int) : void
   {
      if (this.rankShown == rank) {
         return;
      }
      this.rankShown = rank;
      this.rankText.setColor(AdventurerRank.color(rank));
      this.rankText.setText(AdventurerRank.label(rank));
      this.rankText.updateMetrics();
      this.rankText.x = NAME_X;
      this.rankText.y = RANK_Y;
   }

   public function update(player:Player) : void
   {
      if (player == null) {
         return;
      }
      this.setName(player.name_);
      this.setRank(player.advRank_);
      if (this.portrait.bitmapData == null) {
         this.portrait.bitmapData = player.getPortrait();
         if (this.portrait.bitmapData != null) {
            /* Centre the portrait in its recess. */
            this.portrait.x = ICON_X + (ICON_W - this.portrait.bitmapData.width) / 2;
            this.portrait.y = ICON_Y + (ICON_H - this.portrait.bitmapData.height) / 2;
         }
      }
   }
}
}
