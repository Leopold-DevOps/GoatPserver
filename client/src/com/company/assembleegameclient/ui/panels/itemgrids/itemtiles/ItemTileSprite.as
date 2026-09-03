package com.company.assembleegameclient.ui.panels.itemgrids.itemtiles
{
   import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.ui.SimpleText;
import com.company.util.AssetLibrary;

import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Sprite;
import flash.events.TimerEvent;
import flash.filters.ColorMatrixFilter;
   import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.Timer;

import kabam.rotmg.constants.ItemConstants;
import kabam.rotmg.constants.UiMetrics;
   
   public class ItemTileSprite extends Sprite
   {
      
      protected static const DIM_FILTER:Array = [new ColorMatrixFilter([0.4,0,0,0,0,0,0.4,0,0,0,0,0,0.4,0,0,0,0,0,1,0])];

      /** How much bigger Adventurer gear's icon renders than a normal item. */
      private static const ADVENTURER_GEAR_SCALE:Number = 1.5;
      
      private static const DOSE_MATRIX:Matrix = function():Matrix
      {
         var m:* = new Matrix();
         m.translate(10,5);
         return m;
      }();
       
      
      public var itemId:int;

      public var itemData:Object;
      
      public var itemBitmap:Bitmap;
      
      public function ItemTileSprite()
      {
         super();
         this.itemBitmap = new Bitmap();
         addChild(this.itemBitmap);
         this.itemId = -1;
         this.itemData = null;
      }
      
      public function setDim(dim:Boolean) : void
      {
         filters = dim?DIM_FILTER:null;
      }
      
      public function setType(displayedItemType:int, data:Object) : void
      {
         var texture:BitmapData = null;
         var eqXML:XML = null;
         var tempText:SimpleText = null;
         /* setType can be called repeatedly on the same tile as the item in a
            slot changes (equip/unequip, pickup). The previous animated item's
            Timer was never stopped - it kept ticking and overwriting
            itemBitmap.bitmapData with frames of whatever item used to be
            here, silently corrupting the tile's icon the next time it
            displayed a non-animated item. Stop unconditionally, first. */
         if (this.animTimer != null)
         {
            this.animTimer.stop();
            this.animTimer.removeEventListener(TimerEvent.TIMER, this.makeAnimation);
            this.animTimer = null;
         }
         this.itemId = displayedItemType;
         this.itemData = data;
         if(this.itemId != ItemConstants.NO_ITEM)
         {
            eqXML = ObjectLibrary.xmlLibrary_[this.itemId];
            /* Adventurer gear reads bigger than an ordinary item icon - it is
               meant to stand out, and the pulsing glow needs real pixel
               budget of its own rather than squeezing the blade down to fit
               inside the same footprint as a plain sword. Everything else
               keeps the standard size unchanged. */
            this.iconSizeOverride = (eqXML != null && eqXML.hasOwnProperty("AdventurerGear"))
               ? UiMetrics.ITEM_ICON_SIZE * ADVENTURER_GEAR_SCALE
               : UiMetrics.ITEM_ICON_SIZE;
            texture = ObjectLibrary.getRedrawnTextureFromType(this.itemId,this.iconSizeOverride,true);

             if(eqXML == null){
                 this.itemId = -1;
             }

            if(this.itemData != null && this.itemData.Stack > 0)
            {
               texture = texture.clone();
               tempText = new SimpleText(12,16777215,false,0,0);
               tempText.text = String(this.itemData.Stack);
               tempText.updateMetrics();
               texture.draw(tempText,DOSE_MATRIX);
            }
            else if(eqXML && eqXML.hasOwnProperty("Doses"))
            {
               texture = texture.clone();
               tempText = new SimpleText(12,16777215,false,0,0);
               tempText.text = String(eqXML.Doses);
               tempText.updateMetrics();
               texture.draw(tempText,DOSE_MATRIX);
            }
            else if(eqXML && eqXML.hasOwnProperty("Quantity"))
            {
               texture = texture.clone();
               tempText = new SimpleText(12,16777215,false,0,0);
               tempText.text = String(eqXML.Quantity);
               tempText.updateMetrics();
               texture.draw(tempText,DOSE_MATRIX);
            }
             var spriteFile:String = null;
             var spriteArray:Array = null;
             var spritePeriod:Number = -1;
             var first:Number = -1;
             var last:Number = -1;
             var next:Number = -1;
             var makeAnimation:Function;
             var hasPeriod:Boolean = !eqXML ? false : eqXML.hasOwnProperty("@spritePeriod");
             var hasFile:Boolean = !eqXML ? false : eqXML.hasOwnProperty("@spriteFile");
             var hasArray:Boolean = !eqXML ? false : eqXML.hasOwnProperty("@spriteArray");
             var hasAnimatedSprites:Boolean = hasPeriod && hasFile && hasArray;

             if (hasPeriod)
                 spritePeriod = 1000 / eqXML.attribute("spritePeriod");

             if (hasFile)
                 spriteFile = eqXML.attribute("spriteFile");

             if (hasArray) {
                 spriteArray = String(eqXML.attribute("spriteArray")).split('-');
                 first = Parameters.parse(spriteArray[0]);
                 last = Parameters.parse(spriteArray[1]);
             }

             this.itemBitmap.bitmapData = texture;
            this.centreOnContent(texture);

             if (hasAnimatedSprites && spritePeriod != -1 && spriteFile != null && spriteArray != null && first != -1 && last != -1) {
                 this.spriteFile = spriteFile;
                 this.first = first;
                 this.last = last;
                 this.next = this.first;
                 this.animTimer = new Timer(spritePeriod);
                 this.animTimer.addEventListener(TimerEvent.TIMER, this.makeAnimation);
                 this.animTimer.start();
             } else {
                 this.spriteFile = null;
                 this.first = this.last = this.next = -1;
             }

             visible = true;
         }
         else
         {
            visible = false;
         }
      }
       private var spriteFile:String;
       private var first:Number;
       private var last:Number;
       private var next:Number;
       private var animTimer:Timer;
       /** Set in setType() so makeAnimation() sizes its frames the same way. */
       private var iconSizeOverride:Number = UiMetrics.ITEM_ICON_SIZE;

       private function makeAnimation(event:TimerEvent = null):void {
           if (this.spriteFile == null)
               return;

           var frame:BitmapData = AssetLibrary.getImageFromSet(this.spriteFile, this.next);

           /* This never went through getRedrawnTextureFromType's height-based
              scale correction - it drew every frame at a hardcoded iconSize
              of 60 with the redraw scale pinned to 5, so a high-resolution
              frame (anything past the old 8x8/16x16 convention) rendered at
              5 * (60/100) * frame.width px: for a 176px square frame that is
              528px, filling most of the screen rather than one inventory
              slot. No existing content used spritePeriod, so this was never
              exercised until now.

              Mirror the static icon's normalisation instead (see
              ObjectLibrary.getRedrawnTextureFromType): scale down by the
              frame's own height once it exceeds 16px, and size against
              UiMetrics.ITEM_ICON_SIZE so an animated icon lands at the same
              on-screen size as a static one. This holds exactly when the
              frame canvas is square - any square size cancels out in the
              width formula - which is how the glow-frame sheets are built. */
           var scale:Number = 5;
           if (frame.height > 16)
           {
               scale = (scale * 8) / frame.height;
           }
           var bitmapData:BitmapData = TextureRedrawer.redraw(frame, this.iconSizeOverride, true, 0, true, scale);

           this.itemBitmap.bitmapData = bitmapData;
           this.centreOnContent(bitmapData);

           this.next++;

           if (this.next > this.last)
               this.next = this.first;
       }

       /**
        * Centre the icon on its visible pixels rather than on the bitmap.
        *
        * TextureRedrawer pads asymmetrically - resize() offsets the art by
        * `magic` (12) on the top/left but only adds 1px at the bottom when the
        * symmetric flag is off, and outlineGlow() adds its own margin. Centring
        * the raw bitmap therefore parks the artwork a few pixels off inside the
        * slot. Measuring the opaque bounds is immune to whatever padding the
        * redraw chain happened to add.
        */
       private function centreOnContent(bmp:BitmapData) : void
       {
           var bounds:Rectangle = bmp.getColorBoundsRect(0xFF000000, 0x00000000, false);
           if (bounds == null || bounds.width <= 0 || bounds.height <= 0)
           {
               this.itemBitmap.x = -bmp.width / 2;
               this.itemBitmap.y = -bmp.height / 2;
               return;
           }
           this.itemBitmap.x = -(bounds.x + bounds.width / 2);
           this.itemBitmap.y = -(bounds.y + bounds.height / 2);
       }
   }
}
