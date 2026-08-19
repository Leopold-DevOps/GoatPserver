package kabam.rotmg.ui.view.components
{
   import com.company.assembleegameclient.objects.ObjectLibrary;
   import com.company.assembleegameclient.util.TextureRedrawer;
   import com.company.ui.SimpleText;
   import com.company.util.AssetLibrary;
   import com.company.util.GraphicsUtil;
   import com.company.util.MoreColorUtil;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.DropShadowFilter;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import org.osflash.signals.Signal;
   import org.osflash.signals.natives.NativeSignal;
   
   public class PotionSlotView extends Sprite
   {
      /* Square slots sized to the recesses in the top-left HUD panel art. */
      public static var BUTTON_WIDTH:int = 29;
      private static var BUTTON_HEIGHT:int = 25;
      /** Count turns red once the player is carrying a full stack. */
      public static var MAX_POTIONS:int = 6;
      /** How far the count creeps back over the potion art. */
      private static const TEXT_OVERLAP:int = 3;
      private static var SMALL_SIZE:int = 4;
      private static var CENTER_ICON_X:int = 13;
      private static var LEFT_ICON_X:int = -6;
      private static const DOUBLE_CLICK_PAUSE:uint = 250;
      private static const DRAG_DIST:int = 3;
      
      public var position:int;
      public var objectType:int;
      public var click:NativeSignal;
      public var buyUse:Signal;
      public var drop:Signal;
      private var lightGrayFill:GraphicsSolidFill;
      private var midGrayFill:GraphicsSolidFill;
      private var darkGrayFill:GraphicsSolidFill;
      private var outerPath:GraphicsPath;
      private var innerPath:GraphicsPath;
      private var useGraphicsData:Vector.<IGraphicsData>;
      private var buyOuterGraphicsData:Vector.<IGraphicsData>;
      private var buyInnerGraphicsData:Vector.<IGraphicsData>;
      private var text:SimpleText;
      private var textTwo:SimpleText;
      private var potionIconDraggableSprite:Sprite;
      private var potionIcon:Bitmap;
      private var bg:Sprite;
      private var grayscaleMatrix:ColorMatrixFilter;
      private var available:Boolean = false;
      private var doubleClickTimer:Timer;
      private var dragStart:Point;
      private var pendingSecondClick:Boolean;
      private var isDragging:Boolean;
      private var showPots:Boolean;
      
      public function PotionSlotView(cuts:Array, position:int)
      {
         /* Alpha 0 - the pane art already paints the potion recesses. Same
            trick as ItemTile: a zero-alpha fill still hit-tests, so the slot
            keeps its mouse target for click, drag and buy. */
         this.lightGrayFill = new GraphicsSolidFill(0x6B4A2B,0);
         this.midGrayFill = new GraphicsSolidFill(0x4A3421,0);
         this.darkGrayFill = new GraphicsSolidFill(0x2B1D11,0);
         this.outerPath = new GraphicsPath(new Vector.<int>(),new Vector.<Number>());
         this.innerPath = new GraphicsPath(new Vector.<int>(),new Vector.<Number>());
         this.useGraphicsData = new <IGraphicsData>[this.lightGrayFill,this.outerPath,GraphicsUtil.END_FILL];
         this.buyOuterGraphicsData = new <IGraphicsData>[this.midGrayFill,this.outerPath,GraphicsUtil.END_FILL];
         this.buyInnerGraphicsData = new <IGraphicsData>[this.darkGrayFill,this.innerPath,GraphicsUtil.END_FILL];
         super();
         mouseChildren = false;
         this.position = position;
         this.grayscaleMatrix = new ColorMatrixFilter(MoreColorUtil.greyscaleFilterMatrix);
         /* Just the amount, tucked into the corner - no "/6" limit label. */
         this.text = new SimpleText(11,0xFFFFFF,false,BUTTON_HEIGHT,BUTTON_WIDTH);
         this.text.setBold(true);
         this.text.filters = [new DropShadowFilter(0, 0, 0, 1, 4, 4, 2)];
         this.textTwo = new SimpleText(11,0xb3b3b3,false,BUTTON_HEIGHT,BUTTON_WIDTH);
         this.bg = new Sprite();
         GraphicsUtil.clearPath(this.outerPath);
         GraphicsUtil.drawCutEdgeRect(0,0,BUTTON_WIDTH,BUTTON_HEIGHT,4,cuts,this.outerPath);
         GraphicsUtil.drawCutEdgeRect(2,2,BUTTON_WIDTH - SMALL_SIZE,BUTTON_HEIGHT - SMALL_SIZE,4,cuts,this.innerPath);
         this.bg.graphics.drawGraphicsData(this.buyOuterGraphicsData);
         this.bg.graphics.drawGraphicsData(this.buyInnerGraphicsData);
         addChild(this.bg);
         addChild(this.text);
         this.potionIconDraggableSprite = new Sprite();
         this.doubleClickTimer = new Timer(DOUBLE_CLICK_PAUSE,1);
         this.doubleClickTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onDoubleClickTimerComplete);
         addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
         addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
         addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
         addEventListener(Event.REMOVED_FROM_STAGE,this.onRemovedFromStage);
         this.click = new NativeSignal(this,MouseEvent.CLICK,MouseEvent);
         this.buyUse = new Signal();
         this.drop = new Signal(DisplayObject);
      }

      public function setData(potions:int, available:Boolean, objectType:int = -1):void
      {
         var iconX:int;
         var iconBD:BitmapData;
         var potionIconBig:Bitmap;
         if (objectType != -1)
         {
            this.objectType = objectType;
            if (this.potionIcon != null)
            {
               removeChild(this.potionIcon);
            }
            iconBD = ObjectLibrary.getRedrawnTextureFromType(objectType, 40, false);
            this.potionIcon = new Bitmap(iconBD);
            addChild(this.potionIcon);
            /* Re-add so the count stays above the potion it overlaps - the icon
               is created here, after the text was added in the constructor. */
            addChild(this.text);
            iconBD = ObjectLibrary.getRedrawnTextureFromType(objectType, 80, true);
            potionIconBig = new Bitmap(iconBD);
            potionIconBig.x = potionIconBig.x - 20;
            potionIconBig.y = potionIconBig.y - 30;
            this.potionIconDraggableSprite.addChild(potionIconBig);
         }
         this.setTextString(String(potions));
         this.bg.graphics.clear();
         this.bg.graphics.drawGraphicsData(this.useGraphicsData);
         if (this.potionIcon != null && this.potionIcon.bitmapData != null) {
            /* Centre on the icon's visible pixels: getRedrawnTextureFromType
               pads the bitmap asymmetrically, so centring the bitmap box leaves
               the potion visibly off-centre in its recess. */
            var ib:Rectangle = this.potionIcon.bitmapData.getColorBoundsRect(0xFF000000, 0x00000000, false);
            if (ib == null || ib.width <= 0 || ib.height <= 0) {
               ib = new Rectangle(0, 0, this.potionIcon.bitmapData.width, this.potionIcon.bitmapData.height);
            }
            this.potionIcon.x = (BUTTON_WIDTH - ib.width) / 2 - ib.x;
            this.potionIcon.y = (BUTTON_HEIGHT - ib.height) / 2 - ib.y;
            /* Count sits on the potion's lower-right, overlapping it slightly
               rather than floating in the slot corner. */
            this.text.x = this.potionIcon.x + ib.x + ib.width - this.text.width + TEXT_OVERLAP;
            this.text.y = this.potionIcon.y + ib.y + ib.height - this.text.height + TEXT_OVERLAP;
         } else {
            this.text.x = BUTTON_WIDTH - this.text.width - 1;
            this.text.y = BUTTON_HEIGHT - this.text.height - 1;
         }
         this.text.setColor(potions >= MAX_POTIONS ? 0xE04A4A : 0xFFFFFF);
      }

      public function setTextString(_arg1:String):void
      {
         this.text.setText(_arg1);
         this.text.updateMetrics();
      }
      
      private function onMouseOut(e:MouseEvent) : void
      {
         this.setPendingDoubleClick(false);
      }
      
      private function onMouseUp(e:MouseEvent) : void
      {
         if(this.isDragging)
         {
            return;
         }
         if(e.shiftKey)
         {
            this.setPendingDoubleClick(false);
            this.buyUse.dispatch();
         }
         else if(!this.pendingSecondClick)
         {
            this.setPendingDoubleClick(true);
         }
         else
         {
            this.setPendingDoubleClick(false);
            this.buyUse.dispatch();
         }
      }
      
      private function onMouseDown(e:MouseEvent) : void
      {
         if(showPots)
         {
            this.beginDragCheck(e);
         }
      }
      
      private function setPendingDoubleClick(isPending:Boolean) : void
      {
         this.pendingSecondClick = isPending;
         if(this.pendingSecondClick)
         {
            this.doubleClickTimer.reset();
            this.doubleClickTimer.start();
         }
         else
         {
            this.doubleClickTimer.stop();
         }
      }
      
      private function beginDragCheck(e:MouseEvent) : void
      {
         this.dragStart = new Point(e.stageX,e.stageY);
         addEventListener(MouseEvent.MOUSE_MOVE,this.onMouseMoveCheckDrag);
         addEventListener(MouseEvent.MOUSE_OUT,this.cancelDragCheck);
         addEventListener(MouseEvent.MOUSE_UP,this.cancelDragCheck);
      }
      
      private function cancelDragCheck(e:MouseEvent) : void
      {
         removeEventListener(MouseEvent.MOUSE_MOVE,this.onMouseMoveCheckDrag);
         removeEventListener(MouseEvent.MOUSE_OUT,this.cancelDragCheck);
         removeEventListener(MouseEvent.MOUSE_UP,this.cancelDragCheck);
      }
      
      private function onMouseMoveCheckDrag(e:MouseEvent) : void
      {
         var dx:Number = e.stageX - this.dragStart.x;
         var dy:Number = e.stageY - this.dragStart.y;
         var distance:Number = Math.sqrt(dx * dx + dy * dy);
         if(distance > DRAG_DIST)
         {
            this.cancelDragCheck(null);
            this.setPendingDoubleClick(false);
            this.beginDrag();
         }
      }
      
      private function onDoubleClickTimerComplete(e:TimerEvent) : void
      {
         this.setPendingDoubleClick(false);
      }
      
      private function beginDrag() : void
      {
         this.isDragging = true;
         this.potionIconDraggableSprite.startDrag(true);
         stage.addChild(this.potionIconDraggableSprite);
         this.potionIconDraggableSprite.addEventListener(MouseEvent.MOUSE_UP,this.endDrag);
      }
      
      private function endDrag(e:MouseEvent) : void
      {
         this.isDragging = false;
         this.potionIconDraggableSprite.stopDrag();
         this.potionIconDraggableSprite.x = this.dragStart.x;
         this.potionIconDraggableSprite.y = this.dragStart.y;
         stage.removeChild(this.potionIconDraggableSprite);
         this.potionIconDraggableSprite.removeEventListener(MouseEvent.MOUSE_UP,this.endDrag);
         this.drop.dispatch(this.potionIconDraggableSprite.dropTarget);
      }
      
      private function onRemovedFromStage(e:Event) : void
      {
         this.setPendingDoubleClick(false);
         this.cancelDragCheck(null);
         if(this.isDragging)
         {
            this.potionIconDraggableSprite.stopDrag();
         }
      }
   }
}
