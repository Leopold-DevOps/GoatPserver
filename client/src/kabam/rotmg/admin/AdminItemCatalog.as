package kabam.rotmg.admin {
import com.company.assembleegameclient.constants.InventoryOwnerTypes;
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.ui.panels.itemgrids.itemtiles.ItemTile;
import com.company.assembleegameclient.ui.tooltip.EquipmentToolTip;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.utils.Dictionary;

/**
 * Scrollable, searchable grid of every equippable item in the game.
 * Only the visible rows are ever rendered, so the ~2k item list stays cheap.
 *
 * Click a tile to send it to the first free inventory slot; drag a tile onto
 * an inventory slot to place it there specifically.
 */
public class AdminItemCatalog extends Sprite {

    private static const COLS:int = 5;
    private static const TILE:int = 34;
    private static const ICON:int = 30;

    public var onGive:Function;          // function(type:int):void
    public var onGiveToSlot:Function;    // function(type:int, slot:int):void

    private var gs:GameSprite;
    private var viewHeight:int;

    private var allTypes:Vector.<int> = new Vector.<int>();
    private var filtered:Vector.<int> = new Vector.<int>();

    private var scroller:Sprite;
    private var maskShape:Shape;
    private var pool:Vector.<Sprite> = new Vector.<Sprite>();
    private var scrollY:Number = 0;

    private static const iconCache:Dictionary = new Dictionary();

    private var toolTip:EquipmentToolTip;
    private var dragProxy:Bitmap;
    private var dragType:int = -1;
    private var pressType:int = -1;
    private var pressPoint:Point;

    public function AdminItemCatalog(gs:GameSprite, viewHeight:int) {
        this.gs = gs;
        this.viewHeight = viewHeight;

        this.buildTypeList();
        this.filtered = this.allTypes.concat();

        this.scroller = new Sprite();
        addChild(this.scroller);

        this.maskShape = new Shape();
        this.maskShape.graphics.beginFill(0xFFFFFF, 1);
        this.maskShape.graphics.drawRect(0, 0, COLS * TILE, viewHeight);
        this.maskShape.graphics.endFill();
        addChild(this.maskShape);
        this.scroller.mask = this.maskShape;

        this.buildPool();
        this.refresh();

        addEventListener(MouseEvent.MOUSE_WHEEL, this.onWheel);
    }

    private function buildTypeList():void {
        var type:Object;
        for (type in ObjectLibrary.typeToIdItems_) {
            this.allTypes.push(int(type));
        }
        this.allTypes.sort(Array.NUMERIC);
    }

    private function buildPool():void {
        var rows:int = Math.ceil(this.viewHeight / TILE) + 1;
        var count:int = rows * COLS;
        for (var i:int = 0; i < count; i++) {
            var tile:Sprite = new Sprite();
            tile.graphics.beginFill(0x2B2B2B, 1);
            tile.graphics.drawRoundRect(0, 0, TILE - 2, TILE - 2, 4, 4);
            tile.graphics.endFill();

            var icon:Bitmap = new Bitmap();
            icon.x = icon.y = 1;
            tile.addChild(icon);

            tile.addEventListener(MouseEvent.MOUSE_DOWN, this.onTileDown);
            tile.addEventListener(MouseEvent.MOUSE_OVER, this.onTileOver);
            tile.addEventListener(MouseEvent.MOUSE_OUT, this.onTileOut);

            this.scroller.addChild(tile);
            this.pool.push(tile);
        }
    }

    private function getIcon(type:int):BitmapData {
        if (iconCache[type] == null)
            iconCache[type] = ObjectLibrary.getRedrawnTextureFromType(type, ICON, true);
        return iconCache[type];
    }

    /** Re-binds the pooled tiles to whatever rows are currently in view. */
    private function refresh():void {
        var firstRow:int = Math.floor(this.scrollY / TILE);
        if (firstRow < 0) firstRow = 0;

        for (var i:int = 0; i < this.pool.length; i++) {
            var tile:Sprite = this.pool[i];
            var index:int = firstRow * COLS + i;

            if (index >= this.filtered.length) {
                tile.visible = false;
                continue;
            }

            var type:int = this.filtered[index];
            tile.visible = true;
            tile.x = (i % COLS) * TILE;
            tile.y = Math.floor(index / COLS) * TILE - this.scrollY;
            tile.name = String(type);

            var icon:Bitmap = tile.getChildAt(0) as Bitmap;
            icon.bitmapData = this.getIcon(type);
        }
    }

    public function setFilter(search:String):void {
        var needle:String = search == null ? "" : search.toLowerCase();
        this.filtered.length = 0;

        for (var i:int = 0; i < this.allTypes.length; i++) {
            var type:int = this.allTypes[i];
            if (needle.length == 0 || String(ObjectLibrary.typeToIdItems_[type]).indexOf(needle) != -1)
                this.filtered.push(type);
        }

        this.scrollY = 0;
        this.refresh();
    }

    public function get resultCount():int {
        return this.filtered.length;
    }

    private function get maxScroll():Number {
        var contentHeight:Number = Math.ceil(this.filtered.length / COLS) * TILE;
        var max:Number = contentHeight - this.viewHeight;
        return max < 0 ? 0 : max;
    }

    private function onWheel(e:MouseEvent):void {
        this.scrollY -= e.delta * TILE;
        if (this.scrollY < 0) this.scrollY = 0;
        if (this.scrollY > this.maxScroll) this.scrollY = this.maxScroll;
        this.refresh();
    }

    private function typeOf(tile:DisplayObject):int {
        return tile == null || tile.name == null ? -1 : int(tile.name);
    }

    private function onTileOver(e:MouseEvent):void {
        var type:int = this.typeOf(e.currentTarget as DisplayObject);
        if (type <= 0 || this.gs.map.player_ == null)
            return;

        this.toolTip = new EquipmentToolTip(type, this.gs.map.player_, -1, InventoryOwnerTypes.NPC, 1.0, true, null);
        this.gs.mui_.layers.overlay.addChild(this.toolTip);
        this.toolTip.addEventListener(Event.ENTER_FRAME, this.onTooltipFrame);
    }

    private function onTooltipFrame(e:Event):void {
        if (stage == null || this.toolTip == null || this.toolTip.parent == null)
            return;
        this.toolTip.parent.scaleX = 800 / stage.stageWidth;
        this.toolTip.parent.scaleY = 600 / stage.stageHeight;
        this.toolTip.x = (stage.stageWidth - 800) / 2 + stage.mouseX + 12;
        this.toolTip.y = (stage.stageHeight - 600) / 2 + stage.mouseY + 12;
    }

    private function onTileOut(e:MouseEvent):void {
        this.clearTooltip();
    }

    private function clearTooltip():void {
        if (this.toolTip == null)
            return;
        this.toolTip.removeEventListener(Event.ENTER_FRAME, this.onTooltipFrame);
        if (this.toolTip.parent != null)
            this.toolTip.parent.removeChild(this.toolTip);
        this.toolTip = null;
    }

    private function onTileDown(e:MouseEvent):void {
        this.pressType = this.typeOf(e.currentTarget as DisplayObject);
        if (this.pressType <= 0 || stage == null)
            return;

        this.pressPoint = new Point(stage.mouseX, stage.mouseY);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onStageMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, this.onStageUp);
    }

    private function onStageMove(e:MouseEvent):void {
        if (this.dragType == -1) {
            // only promote to a drag once the pointer has actually moved
            if (Point.distance(this.pressPoint, new Point(stage.mouseX, stage.mouseY)) < 5)
                return;
            this.beginDrag();
        }

        this.dragProxy.x = stage.mouseX - ICON / 2;
        this.dragProxy.y = stage.mouseY - ICON / 2;
        e.updateAfterEvent();
    }

    private function beginDrag():void {
        this.dragType = this.pressType;
        this.clearTooltip();

        this.dragProxy = new Bitmap(this.getIcon(this.dragType));
        this.dragProxy.alpha = 0.85;
        stage.addChild(this.dragProxy);
    }

    private function onStageUp(e:MouseEvent):void {
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onStageMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, this.onStageUp);

        if (this.dragType == -1) {
            // never moved -> treat as a plain click
            if (this.pressType > 0 && this.onGive != null)
                this.onGive(this.pressType);
            this.pressType = -1;
            return;
        }

        var slot:int = this.findSlotUnderMouse();
        if (slot != -1 && this.onGiveToSlot != null)
            this.onGiveToSlot(this.dragType, slot);
        else if (slot == -1 && this.onGive != null)
            this.onGive(this.dragType);

        if (this.dragProxy != null && this.dragProxy.parent != null)
            this.dragProxy.parent.removeChild(this.dragProxy);
        this.dragProxy = null;
        this.dragType = -1;
        this.pressType = -1;
    }

    /** Walks whatever is under the cursor looking for an inventory tile. */
    private function findSlotUnderMouse():int {
        var hits:Array = stage.getObjectsUnderPoint(new Point(stage.mouseX, stage.mouseY));
        for (var i:int = hits.length - 1; i >= 0; i--) {
            var node:DisplayObject = hits[i] as DisplayObject;
            while (node != null) {
                if (node is ItemTile)
                    return (node as ItemTile).tileId;
                node = node.parent;
            }
        }
        return -1;
    }

    public function dispose():void {
        this.clearTooltip();
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onStageMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.onStageUp);
        }
        if (this.dragProxy != null && this.dragProxy.parent != null)
            this.dragProxy.parent.removeChild(this.dragProxy);
        this.dragProxy = null;
    }
}
}
