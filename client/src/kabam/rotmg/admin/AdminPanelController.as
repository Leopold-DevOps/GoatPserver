package kabam.rotmg.admin {
import com.company.assembleegameclient.game.GameSprite;

/**
 * Owns the single AdminPanel instance and wires /admin to it.
 *
 * The rank check here is only a convenience so the panel does not appear for
 * regular players - every button still goes through the server's own
 * permission check, so this is not the security boundary.
 */
public class AdminPanelController {

    private static const MIN_RANK:int = 5;

    private static var panel:AdminPanel;

    public static function toggle(gs:GameSprite):void {
        if (gs == null || gs.map == null || gs.map.player_ == null)
            return;

        if (panel != null && panel.parent != null) {
            close();
            return;
        }

        if (gs.map.player_.rank < MIN_RANK) {
            gs.textBox_.addText("", "You do not have permission to use /admin.");
            return;
        }

        panel = new AdminPanel(gs);
        panel.x = 6;
        panel.y = 22;
        gs.addChild(panel);
    }

    public static function close():void {
        if (panel != null) {
            panel.close();
            panel = null;
        }
    }
}
}
