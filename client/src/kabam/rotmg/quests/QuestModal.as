package kabam.rotmg.quests {
import com.company.assembleegameclient.game.GameSprite;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

import kabam.rotmg.assets.custom.images.QuestBarImg;
import kabam.rotmg.assets.custom.images.QuestModalImg;

/**
 * The quest board window, opened by clicking Enter at a Quest Board.
 *
 * Both the frame (QuestModal.png) and the quest row (QuestBar.png) are
 * pre-scaled to exactly the size they are drawn at, so nothing is resampled at
 * runtime and the pixel art stays crisp. Every constant below is measured off
 * that artwork - the title bar, the close button, the interior recess, and the
 * row's icon slot and parchment area - so the widgets land inside the painted
 * areas. Re-measure if either image is redrawn.
 *
 * Quests come from QUESTS rather than being built by hand, so adding one is a
 * data change. Launching a quest is deliberately not wired yet: the public
 * world vs private instance choice does not exist server side, so selecting a
 * quest acknowledges and stops there.
 */
public class QuestModal extends Sprite {

    /** Authored size of QuestModal.png. Do not scale the bitmap. */
    public static const WIDTH:int = 520;
    public static const HEIGHT:int = 324;

    // --- landmarks measured off the frame ---------------------------------
    private static const TITLE_BAR_LEFT:int = 47;
    private static const TITLE_BAR_RIGHT:int = 472;
    private static const TITLE_BAR_TOP:int = 19;

    private static const CLOSE_CX:int = 492;
    private static const CLOSE_CY:int = 31;
    private static const CLOSE_HIT:int = 30;

    // --- row layout. ROW_W/ROW_H are the authored size of QuestBar.png -----
    private static const ROW_X:int = 41;
    private static const ROW_W:int = 438;
    private static const ROW_H:int = 78;
    private static const ROW_GAP:int = 8;
    private static const FIRST_ROW_Y:int = 56;

    // --- landmarks measured off the row -----------------------------------
    /** Painted parchment area, where the text has to stay. */
    private static const PARCH_X:int = 78;
    private static const PARCH_Y:int = 16;
    private static const PARCH_W:int = 335;
    private static const PARCH_H:int = 45;
    private static const TEXT_X:int = 90;

    // --- palette ----------------------------------------------------------
    private static const GOLD:uint = 0xE4CC84;
    /*
     * The name sits on cream parchment, so it is dark brown rather than the
     * gold used on the frame - gold on this parchment measures 1.15:1
     * contrast, which is illegible. The tier blue is likewise deeper than the
     * 0x3B6FD6 of the board world label, which reaches only 2.6:1 here
     * against 5.1:1 for this one.
     */
    private static const NAME_COLOR:uint = 0x3B2412;
    private static const TIER_BLUE:uint = 0x1E4290;

    /**
     * The board contents. tier is the small line under the name; tierColor
     * lets a later Intermediate/Expert tier use its own colour.
     */
    private static const QUESTS:Array = [
        {name: "Goblin Hunting", tier: "Beginner Quest", tierColor: TIER_BLUE}
    ];

    private var gs:GameSprite;

    public function QuestModal(gs:GameSprite) {
        this.gs = gs;

        addChild(new QuestModalImg() as Bitmap);
        this.buildTitle();
        this.buildCloseButton();
        this.buildQuests();

        addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
    }

    private function buildTitle():void {
        var title:SimpleText = new SimpleText(13, GOLD, false, 0, 0);
        title.setBold(true);
        title.setText("QUEST BOARD");
        title.autoSize = TextFieldAutoSize.LEFT;
        title.x = TITLE_BAR_LEFT + ((TITLE_BAR_RIGHT - TITLE_BAR_LEFT) - title.width) / 2;
        title.y = TITLE_BAR_TOP;
        title.mouseEnabled = false;
        addChild(title);
    }

    /**
     * The X is painted into the frame, so this is only an invisible hit area
     * sitting on top of it.
     */
    private function buildCloseButton():void {
        var hit:Sprite = new Sprite();
        hit.graphics.beginFill(0xFFFFFF, 0);
        hit.graphics.drawRect(CLOSE_CX - CLOSE_HIT / 2, CLOSE_CY - CLOSE_HIT / 2, CLOSE_HIT, CLOSE_HIT);
        hit.graphics.endFill();
        hit.buttonMode = true;
        hit.useHandCursor = true;

        var modal:QuestModal = this;
        hit.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            modal.close();
        });
        addChild(hit);
    }

    private function buildQuests():void {
        var y:int = FIRST_ROW_Y;
        for (var i:int = 0; i < QUESTS.length; i++) {
            var row:Sprite = this.buildRow(QUESTS[i]);
            row.x = ROW_X;
            row.y = y;
            addChild(row);
            y += ROW_H + ROW_GAP;
        }
    }

    private function buildRow(quest:Object):Sprite {
        var row:Sprite = new Sprite();
        row.addChild(new QuestBarImg() as Bitmap);

        // hover wash over the parchment only, so the frame keeps its own shading
        var highlight:Sprite = new Sprite();
        highlight.graphics.beginFill(0xFFFFFF, 0.16);
        highlight.graphics.drawRect(PARCH_X, PARCH_Y, PARCH_W, PARCH_H);
        highlight.graphics.endFill();
        highlight.visible = false;
        highlight.mouseEnabled = false;
        row.addChild(highlight);

        var name:SimpleText = new SimpleText(15, NAME_COLOR, false, 0, 0);
        name.setBold(true);
        name.setText(quest.name);
        name.autoSize = TextFieldAutoSize.LEFT;
        name.x = TEXT_X;
        name.y = 19;
        name.mouseEnabled = false;
        row.addChild(name);

        var tier:SimpleText = new SimpleText(11, quest.tierColor, false, 0, 0);
        tier.setBold(true);
        tier.setText(quest.tier);
        tier.autoSize = TextFieldAutoSize.LEFT;
        tier.x = TEXT_X;
        tier.y = 40;
        tier.mouseEnabled = false;
        row.addChild(tier);

        row.buttonMode = true;
        row.useHandCursor = true;

        var modal:QuestModal = this;
        row.addEventListener(MouseEvent.ROLL_OVER, function (e:MouseEvent):void {
            highlight.visible = true;
        });
        row.addEventListener(MouseEvent.ROLL_OUT, function (e:MouseEvent):void {
            highlight.visible = false;
        });
        row.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            modal.onQuestSelected(quest);
        });
        return row;
    }

    /** Placeholder until the dungeon launch options exist server side. */
    public function onQuestSelected(quest:Object):void {
        if (this.gs != null && this.gs.textBox_ != null)
            this.gs.textBox_.addText("", quest.name + " is not available yet.");
    }

    private function onAddedToStage(e:Event):void {
        // the board is in the world, so stop movement and hotkeys leaking through
        this.gs.mui_.setEnablePlayerInput(false);
        this.gs.mui_.setEnableHotKeysInput(false);
    }

    private function onRemovedFromStage(e:Event):void {
        this.gs.mui_.setEnablePlayerInput(true);
        this.gs.mui_.setEnableHotKeysInput(true);
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
