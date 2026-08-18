package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.game.GameSprite;
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.ui.panels.Panel;
   import com.company.assembleegameclient.ui.panels.PortalPanel;
   import com.company.util.GraphicsUtil;

   import flash.display.BitmapData;
   import flash.display.GraphicsBitmapFill;
   import flash.display.GraphicsPath;
   import flash.display.IGraphicsData;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;

   import kabam.rotmg.assets.custom.images.EnterButton;
   import kabam.rotmg.constants.GeneralConstants;

   public class Portal extends GameObject implements IInteractiveObject
   {
      /** Gap between the top of the portal art and the bottom of the button. */
      private static const ENTER_MARGIN:int = 6;

      private static var enterBitmap_:BitmapData;

      private static var enterBitmapHover_:BitmapData;

      /**
       * Screen-space (posS_) rect of the plaque as drawn this frame, or null
       * when it is not showing. Used for hit testing - the plaque is drawn
       * geometry rather than a display object, so it has no mouse events of
       * its own and MapUserInput has to test against this.
       */
      public var enterButtonRect_:Rectangle;

      public var nexusPortal_:Boolean;

      public var lockedPortal_:Boolean;

      public var active_:Boolean = true;

      private var enterFill_:GraphicsBitmapFill;

      private var enterPath_:GraphicsPath;

      private var enterVS_:Vector.<Number>;

      public function Portal(objectXML:XML)
      {
         super(objectXML);
         isInteractive_ = true;
         this.nexusPortal_ = objectXML.hasOwnProperty("NexusPortal");
         this.lockedPortal_ = objectXML.hasOwnProperty("LockedPortal");
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         super.draw(graphicsData,camera,time);
         if(this.nexusPortal_)
         {
            drawName(graphicsData,camera);
         }
         this.drawEnterButton(graphicsData);
      }

      /**
       * "Enter" plaque, drawn above the portal while the player is close enough
       * to use it.
       *
       * This goes through graphicsData - the same path the portal sprite and
       * its name plate take - rather than being a display object parented to
       * the map. With hardware acceleration on (Parameters GPURender, the
       * default) the world is rendered by Stage3D on its own layer, whose
       * origin does not match the Map sprite's, so a display-list child sits at
       * a constant offset from the art it is supposed to sit above. Rendering
       * it here keeps it aligned in both the GPU and software paths.
       */
      private function drawEnterButton(graphicsData:Vector.<IGraphicsData>) : void
      {
         this.enterButtonRect_ = null;
         if(this.lockedPortal_ || !this.active_ || map_ == null || map_.player_ == null)
         {
            return;
         }
         if(posS_ == null || posS_.length < 5 || this.drawnHeight_ <= 0)
         {
            return;
         }
         var dx:Number = this.x_ - map_.player_.x_;
         var dy:Number = this.y_ - map_.player_.y_;
         if(dx * dx + dy * dy > GeneralConstants.MAXIMUM_INTERACTION_DISTANCE * GeneralConstants.MAXIMUM_INTERACTION_DISTANCE)
         {
            return;
         }
         if(enterBitmap_ == null)
         {
            enterBitmap_ = new EnterButton().bitmapData;
            /* Brightened copy for the hover state - cheaper than filtering the
               fill every frame, and it only has to be built once. */
            enterBitmapHover_ = enterBitmap_.clone();
            enterBitmapHover_.colorTransform(enterBitmapHover_.rect,
               new ColorTransform(1.25, 1.25, 1.25, 1, 18, 18, 10, 0));
         }
         if(this.enterFill_ == null)
         {
            this.enterFill_ = new GraphicsBitmapFill(null,new Matrix(),false,false);
            this.enterPath_ = new GraphicsPath(GraphicsUtil.QUAD_COMMANDS,new Vector.<Number>());
            this.enterVS_ = this.enterPath_.data;
         }
         var w:Number = enterBitmap_.width;
         var h:Number = enterBitmap_.height;
         /* Centre on the portal's visible pixels, not its texture box - source
            art is frequently off-centre inside its own cell. */
         var cx:Number = posS_[3] + this.drawnContentOffsetX_;
         var bottom:Number = posS_[4] - this.drawnHeight_ + this.drawnContentTop_ - ENTER_MARGIN;
         var left:Number = cx - w / 2;
         var top:Number = bottom - h;
         this.enterButtonRect_ = new Rectangle(left,top,w,h);
         var hovered:Boolean = this.enterButtonRect_.contains(map_.mouseX,map_.mouseY);
         this.enterVS_.length = 0;
         this.enterVS_.push(left,top,left + w,top,left + w,bottom,left,bottom);
         this.enterFill_.bitmapData = hovered ? enterBitmapHover_ : enterBitmap_;
         this.enterFill_.matrix.identity();
         this.enterFill_.matrix.translate(left,top);
         graphicsData.push(this.enterFill_);
         graphicsData.push(this.enterPath_);
         graphicsData.push(GraphicsUtil.END_FILL);
      }

      public function getPanel(gs:GameSprite) : Panel
      {
         return new PortalPanel(gs,this);
      }
   }
}
