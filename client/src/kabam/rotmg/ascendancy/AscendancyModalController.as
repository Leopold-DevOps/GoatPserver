package kabam.rotmg.ascendancy {
import com.company.assembleegameclient.game.GameSprite;

import kabam.rotmg.constants.UiMetrics;

/**
 * Owns the single AscendancyModal and centres it in the play area.
 *
 * Centred against PLAY_WIDTH, not the whole stage, so the window does not sit
 * under the HUD pane - same reasoning as QuestModalController.
 */
public class AscendancyModalController {

    private static var modal:AscendancyModal;

    public static function toggle(gs:GameSprite):void {
        if (gs == null || gs.map == null || gs.map.player_ == null)
            return;

        if (modal != null && modal.parent != null) {
            close();
            return;
        }

        modal = new AscendancyModal(gs);
        modal.x = Math.max(0, (UiMetrics.PLAY_WIDTH - AscendancyModal.WIDTH) / 2);
        modal.y = Math.max(0, (UiMetrics.STAGE_HEIGHT - AscendancyModal.HEIGHT) / 2);
        gs.addChild(modal);
    }

    public static function close():void {
        if (modal != null) {
            modal.close();
            modal = null;
        }
    }
}
}
