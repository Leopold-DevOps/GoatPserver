package com.company.assembleegameclient.screens.charrects
{
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;

   /**
    * One row in the character list, backed by painted panel art.
    *
    * Each subclass passes its own panel: CharSlotExisting for a live
    * character, CharSlotEmpty for a free slot, CharSlotBuy to purchase one.
    * The art is authored at 2x and drawn at half size so it stays sharp when
    * the window is enlarged.
    *
    * Rows are all the same HEIGHT, but not the same width: the existing
    * character panel is wider because its gem diamonds protrude past the bar.
    * Subclasses therefore lay their content out against panelLeft/panelRight
    * rather than against 0/WIDTH.
    */
   public class CharacterRect extends Sprite
   {
      public static const WIDTH:int = 600;
      /** Panel art is 1201x191 at 2x, so 95 drawn, plus a pixel of slack. */
      public static const HEIGHT:int = 96;

      private static const ART_SCALE:Number = 0.5;
      /* Matches the hover lift used on the menu banners. */
      private static const HOVER_LIGHT:Number = 26;

      /** Same gold as the menu banner captions, so the screen reads as one. */
      public static const GOLD:uint = 0xE6C88C;
      /** Dimmer gold for the secondary tagline line. */
      public static const GOLD_DIM:uint = 0xB39A6B;

      /** Left and right edges of the painted panel inside the row. */
      protected var panelLeft:Number = 0;
      protected var panelRight:Number = WIDTH;

      private var panel:Bitmap;
      public var selectContainer:Sprite;

      public function CharacterRect(panelClass:Class)
      {
         super();
         this.panel = new panelClass();
         this.panel.scaleX = ART_SCALE;
         this.panel.scaleY = ART_SCALE;
         this.panel.x = Math.round((WIDTH - this.panel.width) / 2);
         this.panel.y = 0;
         this.panelLeft = this.panel.x;
         this.panelRight = this.panel.x + this.panel.width;
         addChild(this.panel);
         addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
         addEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
      }

      protected function onMouseOver(event:MouseEvent) : void
      {
         this.panel.transform.colorTransform =
            new ColorTransform(1, 1, 1, 1, HOVER_LIGHT, HOVER_LIGHT, HOVER_LIGHT * 0.7, 0);
      }

      protected function onRollOut(event:MouseEvent) : void
      {
         this.panel.transform.colorTransform = new ColorTransform();
      }

      public function makeContainer() : void
      {
         this.selectContainer = new Sprite();
         this.selectContainer.mouseChildren = false;
         this.selectContainer.buttonMode = true;
         /* Alpha-0 fill: still hit-tests in Flash, so the whole row stays
            clickable without drawing anything over the panel art. */
         this.selectContainer.graphics.beginFill(16711935,0);
         this.selectContainer.graphics.drawRect(0,0,WIDTH,HEIGHT);
         addChild(this.selectContainer);
      }
   }
}
