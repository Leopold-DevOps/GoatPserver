package kabam.rotmg.ui.view
{
   import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.objects.Player;
   import com.company.assembleegameclient.ui.TradePanel;
   import com.company.assembleegameclient.ui.panels.InteractPanel;
   import com.company.assembleegameclient.ui.panels.itemgrids.EquippedGrid;
   import com.company.assembleegameclient.util.TextureRedrawer;
   import com.company.util.AssetLibrary;
   import com.company.util.GraphicsUtil;
   import com.company.util.MoreColorUtil;
   import com.company.util.SpriteUtil;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;

import kabam.rotmg.constants.UiMetrics;
import kabam.rotmg.game.view.components.TabStripView;
   import kabam.rotmg.messaging.impl.incoming.TradeAccepted;
   import kabam.rotmg.messaging.impl.incoming.TradeChanged;
   import kabam.rotmg.messaging.impl.incoming.TradeStart;
   import kabam.rotmg.minimap.view.MiniMap;

   public class HUDView extends Sprite
   {


      private const BG_POSITION:Point = new Point(0, 0);
      private const MAP_POSITION:Point = new Point(UiMetrics.HUD_MINIMAP_X, UiMetrics.HUD_MINIMAP_Y);
      /* x 36 so the class portrait (drawn at -2 inside the view) lands on
         HUD_BAR_X and the name row lines up with the bars and item grids
         below it, instead of hanging off the pane's left frame. */
      private const CHARACTER_DETAIL_PANEL_POSITION:Point = new Point(36, UiMetrics.HUD_DETAILS_Y);
      private const STAT_METERS_POSITION:Point = new Point(UiMetrics.HUD_BAR_X, UiMetrics.HUD_STAT_METERS_Y);
      private const EQUIPMENT_INVENTORY_POSITION:Point = new Point(UiMetrics.ITEM_GRID_X, UiMetrics.HUD_EQUIPMENT_Y);
      private const TAB_STRIP_POSITION:Point = new Point(UiMetrics.ITEM_GRID_X - UiMetrics.HUD_CONTENT_INSET, UiMetrics.HUD_TAB_STRIP_Y);
      /* Centred: the panel is 200 wide inside a HUD_DESIGN_WIDTH (286) pane. */
      private const INTERACT_PANEL_POSITION:Point = new Point(43, UiMetrics.HUD_INTERACT_Y);
      private const NEXUS_INDICATOR_POSITION:Point = new Point(200, 355);

      private var background:CharacterWindowBackground;

      public var miniMap:MiniMap;

      private var equippedGrid:EquippedGrid;

      private var tabStrip:TabStripView;

      private var statMeters:StatMetersView;

      private var characterDetails:CharacterDetailsView;

      public var interactPanel:InteractPanel;

      public var tradePanel:TradePanel;

      private var equippedGridBG:Sprite;

      private var nexusIndicatorBitmap_:Bitmap;

      private var gs_:GameSprite;

      public function HUDView(gs:GameSprite)
      {
         super();
         this.gs_ = gs;
         this.createAssets();
         this.addAssets();
         this.positionAssets();
      }

      public function triggerNexus() : void
      {
         this.nexusIndicatorBitmap_.transform.colorTransform = MoreColorUtil.greenCT;
      }

      private function createAssets() : void
      {
         this.background = new CharacterWindowBackground();
         this.miniMap = new MiniMap(UiMetrics.HUD_MINIMAP_WIDTH,UiMetrics.HUD_MINIMAP_HEIGHT);
         this.tabStrip = new TabStripView(UiMetrics.gridWidth(UiMetrics.ITEM_GRID_COLUMNS) + UiMetrics.HUD_CONTENT_INSET * 2,UiMetrics.HUD_TAB_STRIP_HEIGHT, this.gs_);
         this.characterDetails = new CharacterDetailsView();
         this.statMeters = new StatMetersView();
         var bitmapData:BitmapData = AssetLibrary.getImageFromSet("lofiInterfaceBig",6);
         this.nexusIndicatorBitmap_ = new Bitmap(TextureRedrawer.redraw(bitmapData, 320 / bitmapData.width, true, 0));
         this.nexusIndicatorBitmap_.transform.colorTransform = MoreColorUtil.redCT;
      }

      private function addAssets() : void
      {
         addChild(this.background);
         addChild(this.miniMap);
         //addChild(new Bitmap(new MinimapOverlay().bitmapData));
         addChild(this.tabStrip);
         addChild(this.characterDetails);
         addChild(this.statMeters);
         //addChild(this.nexusIndicatorBitmap_);
      }

      private function positionAssets() : void
      {
         this.background.x = this.BG_POSITION.x;
         this.background.y = this.BG_POSITION.y;
         this.miniMap.x = this.MAP_POSITION.x;
         this.miniMap.y = this.MAP_POSITION.y;
         this.tabStrip.x = this.TAB_STRIP_POSITION.x;
         this.tabStrip.y = this.TAB_STRIP_POSITION.y;
         this.characterDetails.x = this.CHARACTER_DETAIL_PANEL_POSITION.x;
         this.characterDetails.y = this.CHARACTER_DETAIL_PANEL_POSITION.y;
         this.statMeters.x = this.STAT_METERS_POSITION.x;
         this.statMeters.y = this.STAT_METERS_POSITION.y;
         this.nexusIndicatorBitmap_.x = this.NEXUS_INDICATOR_POSITION.x - this.nexusIndicatorBitmap_.width - 2;
         this.nexusIndicatorBitmap_.y = this.NEXUS_INDICATOR_POSITION.y - 14;
      }

      public function setPlayerDependentAssets(gs:GameSprite) : void
      {
         var player:Player = gs.map.player_;

         /* The pane art already paints the equipment recesses. */
         this.createEquippedGridBackground();
         this.equippedGrid = new EquippedGrid(player, player.slotTypes_, player);
         this.equippedGrid.x = this.EQUIPMENT_INVENTORY_POSITION.x;
         this.equippedGrid.y = this.EQUIPMENT_INVENTORY_POSITION.y;
         addChild(this.equippedGrid);
         this.interactPanel = new InteractPanel(gs,player,200,100);
         this.interactPanel.x = this.INTERACT_PANEL_POSITION.x;
         this.interactPanel.y = this.INTERACT_PANEL_POSITION.y;
         addChild(this.interactPanel);
      }

      private function createEquippedGridBackground():void
      {
         var box1:Vector.<IGraphicsData>;
         var box2:Vector.<IGraphicsData>;

         var fill:GraphicsSolidFill = new GraphicsSolidFill(0x676767, 1);
         var path:GraphicsPath = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());

         box1 = new <IGraphicsData>[fill, path, GraphicsUtil.END_FILL];
         GraphicsUtil.drawCutEdgeRect(0, 0, 178, 46, 6, [1, 1, 1, 1], path);

         path = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
         fill = new GraphicsSolidFill(0x454545, 1);
         box2 = new <IGraphicsData>[fill, path, GraphicsUtil.END_FILL];
         GraphicsUtil.drawCutEdgeRect(3, 3, 172, 40, 6, [1, 1, 1, 1], path);

         this.equippedGridBG = new Sprite();
         this.equippedGridBG.x = (this.EQUIPMENT_INVENTORY_POSITION.x - 3);
         this.equippedGridBG.y = (this.EQUIPMENT_INVENTORY_POSITION.y - 3);
         this.equippedGridBG.graphics.drawGraphicsData(box1);
         this.equippedGridBG.graphics.drawGraphicsData(box2);
         /* Kept for the code that toggles its visibility, but the pane art
            paints the equipment recesses so it must not draw over them. */
         this.equippedGridBG.alpha = 0;
         addChild(this.equippedGridBG);
      }

      public function draw() : void
      {
         if(this.equippedGrid)
         {
            this.equippedGrid.draw();
         }
         if(this.interactPanel)
         {
            this.interactPanel.draw();
         }
      }

      public function startTrade(gs:GameSprite, tradeStart:TradeStart) : void
      {
         if(this.tradePanel != null)
         {
            return;
         }
         this.tradePanel = new TradePanel(gs,tradeStart);
         this.tradePanel.y = 200;
         this.tradePanel.addEventListener(Event.CANCEL,this.onTradeCancel);
         addChild(this.tradePanel);
         this.characterDetails.visible = false;
         this.statMeters.visible = false;
         this.tabStrip.visible = false;
         this.equippedGrid.visible = false;
         this.equippedGridBG.visible = false;
         this.interactPanel.visible = false;
      }

      public function tradeChanged(tradeChaged:TradeChanged) : void
      {
         if(this.tradePanel == null)
         {
            return;
         }
         this.tradePanel.setYourOffer(tradeChaged.offer_);
      }

      public function tradeDone() : void
      {
         this.removeTradePanel();
      }

      public function tradeAccepted(tradeAccepted:TradeAccepted) : void
      {
         if(this.tradePanel == null)
         {
            return;
         }
         this.tradePanel.youAccepted(tradeAccepted.myOffer_,tradeAccepted.yourOffer_);
      }

      private function onTradeCancel(event:Event) : void
      {
         this.removeTradePanel();
      }

      private function removeTradePanel() : void
      {
         if(this.tradePanel != null)
         {
            this.tradePanel.removeEventListener(Event.CANCEL,this.onTradeCancel);
            SpriteUtil.safeRemoveChild(this,this.tradePanel);
            this.tradePanel = null;
            this.characterDetails.visible = true;
            this.statMeters.visible = true;
            this.tabStrip.visible = true;
            this.equippedGrid.visible = true;
            this.equippedGridBG.visible = true;
            this.interactPanel.visible = true;
         }
      }
   }
}
