package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.parameters.Parameters;

import flash.display.Bitmap;
import flash.display.Sprite;

import kabam.rotmg.assets.custom.images.HudPane;
import kabam.rotmg.constants.UiMetrics;

public class CharacterWindowBackground extends Sprite
   {


      public function CharacterWindowBackground()
      {
         /* The pane art is authored at exactly UiMetrics.HUD_WIDTH x 600 with the
            surround already keyed to alpha, so the vines and lantern overhang the
            play area instead of sitting on a hard rectangle. */
         var pane:Bitmap = new Bitmap(new HudPane().bitmapData);
         addChild(pane);

         /* No skirt below the pane: HUD_SCALE makes the art end above the
            bottom of the window, and a filled rect there just reads as a stray
            brown box. Letting the play area show through is the intent. */
      }
   }
}
