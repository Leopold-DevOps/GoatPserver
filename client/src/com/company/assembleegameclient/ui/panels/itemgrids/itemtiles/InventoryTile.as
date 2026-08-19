package com.company.assembleegameclient.ui.panels.itemgrids.itemtiles
{
   import com.company.assembleegameclient.ui.panels.itemgrids.ItemGrid;
   import com.company.ui.SimpleText;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   
   public class InventoryTile extends InteractiveItemTile
   {
       
      
      public var hotKey:int;
      
      private var hotKeyBMP:Bitmap;
      
      public function InventoryTile(id:int, parentGrid:ItemGrid, isInteractive:Boolean)
      {
         super(id,parentGrid,isInteractive);
      }
      
      public function addTileNumber(tileNumber:int) : void
      {
         this.hotKey = tileNumber;
         this.buildHotKeyBMP();
      }
      
      public function buildHotKeyBMP() : void
      {
         /* Dark brown (was 0x363636 grey) to match the wooden slot recesses.
            Font and bitmap are sized from the tile rather than fixed at 26/30:
            the old values were chosen for the larger 51x41 tiles and overflowed
            the 33px cells, and centring by text width against a fixed-width
            bitmap left the numeral off-centre. */
         var tempText:SimpleText = new SimpleText(Math.max(10, HEIGHT * 0.5), 0x3A2718, false, 0, 0);
         tempText.text = String(this.hotKey);
         tempText.setBold(true);
         tempText.updateMetrics();
         var bw:int = Math.max(1, Math.ceil(tempText.width));
         var bh:int = Math.max(1, Math.ceil(tempText.height));
         var bmpData:BitmapData = new BitmapData(bw, bh, true, 0);
         bmpData.draw(tempText);
         this.hotKeyBMP = new Bitmap(bmpData);
         this.hotKeyBMP.x = (WIDTH - bw) / 2;
         this.hotKeyBMP.y = (HEIGHT - bh) / 2;
         addChildAt(this.hotKeyBMP,0);
      }
      
      override public function setItemSprite(newItemSprite:ItemTileSprite) : void
      {
         super.setItemSprite(newItemSprite);
         newItemSprite.setDim(false);
      }
      
      override public function setItem(itemId:int, itemData:Object) : Boolean
      {
         var changed:Boolean = super.setItem(itemId, itemData);
         if(changed)
         {
            this.hotKeyBMP.visible = itemSprite.itemId <= 0;
         }
         return changed;
      }
      
      override protected function beginDragCallback() : void
      {
         this.hotKeyBMP.visible = true;
      }
      
      override protected function endDragCallback() : void
      {
         this.hotKeyBMP.visible = itemSprite.itemId <= 0;
      }
   }
}
