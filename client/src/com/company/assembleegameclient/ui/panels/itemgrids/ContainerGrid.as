package com.company.assembleegameclient.ui.panels.itemgrids
{
   import com.company.assembleegameclient.objects.GameObject;
   import com.company.assembleegameclient.objects.Player;
   import com.company.assembleegameclient.ui.panels.itemgrids.itemtiles.InteractiveItemTile;
   
   public class ContainerGrid extends ItemGrid
   {
       
      
      private const NUM_SLOTS:uint = 8;
      
      /* Stacked 2 wide x 4 tall rather than the inventory's 4x2: the plaque the
         bag draws over is 132 wide, and a 4-wide grid is 158. */
      private static const COLUMNS:uint = 2;
      private static const ROWS:uint = 4;
      /* Tighter than the inventory's 13 so four rows clear the plaque. */
      private static const PADDING_Y:uint = 7;
      
      /* The pane's own wood colour, so the slots read as part of the frame
         rather than as black holes punched in the parchment. */
      private static const SLOT_COLOR:uint = 0x422911;
      private static const SLOT_ALPHA:Number = 0.72;
      
      private var tiles:Vector.<InteractiveItemTile>;
      
      public function ContainerGrid(gridOwner:GameObject, currentPlayer:Player)
      {
         var tile:InteractiveItemTile = null;
         super(gridOwner,currentPlayer,0);
         rowLength = COLUMNS;
         paddingY = PADDING_Y;
         this.tiles = new Vector.<InteractiveItemTile>(this.NUM_SLOTS);
         for(var i:int = 0; i < this.NUM_SLOTS; i++)
         {
            tile = new InteractiveItemTile(i + indexOffset,this,interactive);
            /* Must precede addToGrid - that is what calls drawBackground. */
            tile.setBackgroundFill(SLOT_COLOR,SLOT_ALPHA);
            addToGrid(tile,ROWS,i);
            this.tiles[i] = tile;
         }
      }
      
      override public function setItems(items:Vector.<int>, datas:Vector.<Object>, itemIndexOffset:int = 0) : void
      {
         var numItems:int = 0;
         var i:int = 0;
         if(items)
         {
            numItems = items.length;
            for(i = 0; i < this.NUM_SLOTS; i++)
            {
               if(i + indexOffset < numItems)
               {
                  this.tiles[i].setItem(items[i + indexOffset], datas[i + indexOffset]);
               }
               else
               {
                  this.tiles[i].setItem(-1, null);
               }
            }
         }
      }
   }
}
