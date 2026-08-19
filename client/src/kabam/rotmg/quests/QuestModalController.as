package kabam.rotmg.quests {
import com.company.assembleegameclient.game.GameSprite;

import kabam.rotmg.constants.UiMetrics;

/**
 * Owns the single QuestModal instance and centres it in the play area.
 *
 * It is centred against PLAY_WIDTH rather than the full stage so the window
 * does not sit under the HUD pane.
 */
public class QuestModalController {

    private static var modal:QuestModal;

    public static function toggle(gs:GameSprite):void {
        if (gs == null || gs.map == null || gs.map.player_ == null)
            return;

        if (modal != null && modal.parent != null) {
            close();
            return;
        }

        modal = new QuestModal(gs);
        modal.x = Math.max(0, (UiMetrics.PLAY_WIDTH - QuestModal.WIDTH) / 2);
        modal.y = Math.max(0, (UiMetrics.STAGE_HEIGHT - QuestModal.HEIGHT) / 2);
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
