package kabam.rotmg.admin {
import com.company.assembleegameclient.account.ui.TextInputField;
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.objects.Player;
import com.company.ui.SimpleText;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

/**
 * Left-hand admin panel, opened with /admin.
 *
 * Everything here drives the existing server command layer over PlayerText -
 * there is no bespoke packet - so anything the panel can do is also typeable
 * by hand, and a non-admin clicking it just gets the usual permission error.
 */
public class AdminPanel extends Sprite {

    public static const WIDTH:int = 186;

    private static const STAT_NAMES:Array = ["HP", "MP", "ATT", "DEF", "SPD", "DEX", "VIT", "WIS"];

    private var gs:GameSprite;
    private var levelSlider:AdminSlider;
    private var statSliders:Vector.<AdminSlider> = new Vector.<AdminSlider>();
    private var catalog:AdminItemCatalog;
    private var searchField:TextInputField;
    private var resultLabel:SimpleText;

    public function AdminPanel(gs:GameSprite) {
        this.gs = gs;

        this.drawBackground();
        this.buildHeader();

        var y:int = 30;
        y = this.buildLevel(y);
        y = this.buildStats(y);
        y = this.buildActions(y);
        this.buildCatalog(y);

        addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
    }

    private function drawBackground():void {
        graphics.clear();
        graphics.beginFill(0x141414, 0.92);
        graphics.drawRoundRect(0, 0, WIDTH, 566, 8, 8);
        graphics.endFill();
        graphics.lineStyle(1, 0x3C3C3C, 1);
        graphics.drawRoundRect(0, 0, WIDTH, 566, 8, 8);
        graphics.lineStyle();
    }

    private function buildHeader():void {
        var title:SimpleText = new SimpleText(14, 0xF0C674, false, WIDTH, 0);
        title.setBold(true);
        title.setText("ADMIN");
        title.autoSize = TextFieldAutoSize.LEFT;
        title.x = 8;
        title.y = 6;
        addChild(title);

        var closeButton:SimpleText = new SimpleText(14, 0xAAAAAA, false, 20, 0);
        closeButton.setBold(true);
        closeButton.setText("x");
        closeButton.autoSize = TextFieldAutoSize.LEFT;
        closeButton.x = WIDTH - 16;
        closeButton.y = 6;
        closeButton.mouseEnabled = true;
        addChild(closeButton);

        var panel:AdminPanel = this;
        closeButton.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            panel.close();
        });
    }

    private function buildLevel(y:int):int {
        var panel:AdminPanel = this;
        this.levelSlider = new AdminSlider("Level", 1, 20, 1);
        this.levelSlider.x = 10;
        this.levelSlider.y = y;
        this.levelSlider.onCommit = function (value:int):void {
            panel.send("/setlevel " + value);
        };
        addChild(this.levelSlider);
        return y + 30;
    }

    private function buildStats(y:int):int {
        for (var i:int = 0; i < STAT_NAMES.length; i++) {
            var slider:AdminSlider = new AdminSlider(STAT_NAMES[i], 0, 100, 0);
            slider.x = 10;
            slider.y = y;
            slider.onCommit = this.makeStatCommit(i);
            addChild(slider);
            this.statSliders.push(slider);
            y += 27;
        }
        return y + 2;
    }

    /** Captures the stat index for the closure, avoiding the classic loop-variable bug. */
    private function makeStatCommit(index:int):Function {
        var panel:AdminPanel = this;
        return function (value:int):void {
            panel.send("/setstat " + index + " " + value);
        };
    }

    private function buildActions(y:int):int {
        var labels:Array = ["God", "Hide", "Damaging", "Berserk", "Killall", "Max"];
        var commands:Array = ["/eff invincible", "/hide", "/eff damaging", "/eff berserk", "/killall", "/max"];

        for (var i:int = 0; i < labels.length; i++) {
            var button:Sprite = this.makeButton(labels[i], commands[i]);
            button.x = 10 + (i % 3) * 56;
            button.y = y + Math.floor(i / 3) * 22;
            addChild(button);
        }
        return y + 50;
    }

    private function makeButton(label:String, command:String):Sprite {
        var button:Sprite = new Sprite();
        button.graphics.beginFill(0x2B2B2B, 1);
        button.graphics.drawRoundRect(0, 0, 52, 18, 4, 4);
        button.graphics.endFill();
        button.buttonMode = true;

        var text:SimpleText = new SimpleText(10, 0xDDDDDD, false, 52, 0);
        text.setText(label);
        text.autoSize = TextFieldAutoSize.CENTER;
        text.y = 2;
        text.mouseEnabled = false;
        button.addChild(text);

        var panel:AdminPanel = this;
        button.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            panel.send(command);
        });
        return button;
    }

    private function buildCatalog(y:int):void {
        var heading:SimpleText = new SimpleText(11, 0xF0C674, false, WIDTH, 0);
        heading.setBold(true);
        heading.setText("ITEMS");
        heading.autoSize = TextFieldAutoSize.LEFT;
        heading.x = 10;
        heading.y = y;
        addChild(heading);

        this.resultLabel = new SimpleText(10, 0x888888, false, 90, 0);
        this.resultLabel.autoSize = TextFieldAutoSize.RIGHT;
        this.resultLabel.x = WIDTH - 98;
        this.resultLabel.y = y + 1;
        addChild(this.resultLabel);

        this.searchField = new TextInputField("search", false, "", "", 160);
        this.searchField.x = 10;
        this.searchField.y = y + 16;
        this.searchField.addEventListener(KeyboardEvent.KEY_UP, this.onSearchKey);
        this.searchField.addEventListener(FocusEvent.FOCUS_IN, this.onSearchFocus);
        this.searchField.addEventListener(FocusEvent.FOCUS_OUT, this.onSearchBlur);
        addChild(this.searchField);

        this.catalog = new AdminItemCatalog(this.gs, 566 - (y + 52) - 8);
        this.catalog.x = 10;
        this.catalog.y = y + 52;
        this.catalog.onGive = this.onGive;
        this.catalog.onGiveToSlot = this.onGiveToSlot;
        addChild(this.catalog);

        this.updateResultLabel();
    }

    private function onSearchKey(e:KeyboardEvent):void {
        this.catalog.setFilter(this.searchField.text());
        this.updateResultLabel();
    }

    private function updateResultLabel():void {
        this.resultLabel.setText(this.catalog.resultCount + " items");
    }

    /**
     * While the search box has focus the game must stop eating keystrokes,
     * otherwise typing "wasd" walks the character around.
     */
    private function onSearchFocus(e:FocusEvent):void {
        this.gs.mui_.setEnablePlayerInput(false);
        this.gs.mui_.setEnableHotKeysInput(false);
    }

    private function onSearchBlur(e:FocusEvent):void {
        this.gs.mui_.setEnablePlayerInput(true);
        this.gs.mui_.setEnableHotKeysInput(true);
    }

    private function onGive(type:int):void {
        var id:String = ObjectLibrary.getIdFromType(type);
        if (id != null)
            this.send("/give " + id);
    }

    private function onGiveToSlot(type:int, slot:int):void {
        var id:String = ObjectLibrary.getIdFromType(type);
        if (id != null)
            this.send("/giveslot " + slot + " " + id);
    }

    public function send(command:String):void {
        if (this.gs != null && this.gs.gsc_ != null && this.gs.map.player_ != null)
            this.gs.gsc_.playerText(command);
    }

    private function onAddedToStage(e:Event):void {
        addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
        this.syncFromPlayer();
    }

    private function onRemovedFromStage(e:Event):void {
        removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
        this.catalog.dispose();
        // never leave the game deaf to input because the panel closed while focused
        this.gs.mui_.setEnablePlayerInput(true);
        this.gs.mui_.setEnableHotKeysInput(true);
    }

    private function onEnterFrame(e:Event):void {
        this.syncFromPlayer();
    }

    /** Mirrors the server's authoritative values back into the sliders. */
    private function syncFromPlayer():void {
        var player:Player = this.gs.map.player_;
        if (player == null)
            return;

        this.levelSlider.setValue(player.level_);

        this.applyStat(0, player.maxHP_ - player.maxHPBoost_, player.maxHPMax_);
        this.applyStat(1, player.maxMP_ - player.maxMPBoost_, player.maxMPMax_);
        this.applyStat(2, player.attack_ - player.attackBoost_, player.attackMax_);
        this.applyStat(3, player.defense_ - player.defenseBoost_, player.defenseMax_);
        this.applyStat(4, player.speed_ - player.speedBoost_, player.speedMax_);
        this.applyStat(5, player.dexterity_ - player.dexterityBoost_, player.dexterityMax_);
        this.applyStat(6, player.vitality_ - player.vitalityBoost_, player.vitalityMax_);
        this.applyStat(7, player.wisdom_ - player.wisdomBoost_, player.wisdomMax_);
    }

    private function applyStat(index:int, base:int, max:int):void {
        var slider:AdminSlider = this.statSliders[index];
        if (max > 0)
            slider.setBounds(0, max);
        slider.setValue(base);
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
