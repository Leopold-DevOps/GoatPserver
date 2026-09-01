package com.company.assembleegameclient.ui.tooltip
{
   import com.company.assembleegameclient.appengine.CharacterStats;
   import com.company.assembleegameclient.objects.ObjectLibrary;
   import com.company.assembleegameclient.objects.Player;
   import com.company.assembleegameclient.ui.GameObjectListItem;
   import com.company.assembleegameclient.ui.LineBreakDesign;
   import com.company.assembleegameclient.ui.StatusBar;
   import com.company.assembleegameclient.ui.panels.itemgrids.EquippedGrid;
   import com.company.assembleegameclient.ui.panels.itemgrids.InventoryGrid;
   import com.company.assembleegameclient.util.FameUtil;
   import com.company.ui.SimpleText;
   import flash.filters.DropShadowFilter;
   import kabam.rotmg.assets.services.CharacterFactory;
   import kabam.rotmg.classes.model.CharacterClass;
   import kabam.rotmg.classes.model.CharacterSkin;
   import kabam.rotmg.classes.model.ClassesModel;
   import kabam.rotmg.constants.GeneralConstants;
   import kabam.rotmg.core.StaticInjectorContext;
   import kabam.rotmg.util.Diag;
import kabam.rotmg.core.model.PlayerModel;
import kabam.rotmg.game.model.GameModel;
import kabam.rotmg.game.view.components.StatsView;

public class MyPlayerToolTip extends ToolTip
   {
       
      
      private var factory:CharacterFactory;
      
      private var classes:ClassesModel;
      
      public var player_:Player;
      
      private var playerPanel_:GameObjectListItem;
      
      private var hpBar_:StatusBar;
      
      private var mpBar_:StatusBar;
      
      private var lineBreak_:LineBreakDesign;
      
      private var bestLevel_:SimpleText;
      
      private var nextClassQuest_:SimpleText;
      
      private var eGrid:EquippedGrid;
      
      private var iGrid:InventoryGrid;

      private var bGrid:InventoryGrid;

      private var stats_:StatsView;
      
      public function MyPlayerToolTip(accountName:String, charXML:XML, charStats:CharacterStats)
      {
         super(3552822,1,16777215,1);
         var _loc3_:* = NaN;
         this.factory = StaticInjectorContext.getInjector().getInstance(CharacterFactory);
         this.classes = StaticInjectorContext.getInjector().getInstance(ClassesModel);
         var objectType:int = int(charXML.ObjectType);
         var playerXML:XML = ObjectLibrary.xmlLibrary_[objectType];
         this.player_ = Player.fromPlayerXML(accountName,charXML);
         /* Every dereference below has been seen null in the wild for a custom
            class, and each one throws #1009 with no stack trace in the release
            player - so they are guarded and breadcrumbed individually. */
         var char:CharacterClass = this.classes.getCharacterClass(this.player_.objectType_);
         Diag.at("MyPlayerToolTip: charClass=" + (char == null ? "NULL" : "ok")
                 + " objectType=" + this.player_.objectType_);
         var skin:CharacterSkin = char == null ? null : char.skins.getSkin(charXML.Texture);
         if (char != null && (skin == null || skin.template == null))
         {
            skin = char.skins.getDefaultSkin();
         }
         Diag.at("MyPlayerToolTip: skin=" + (skin == null ? "NULL" : "ok")
                 + " template=" + (skin == null || skin.template == null ? "NULL" : "ok"));
         if (skin != null && skin.template != null)
         {
            this.player_.animatedChar_ = this.factory.makeCharacter(skin.template);
         }
         Diag.at("MyPlayerToolTip: animatedChar="
                 + (this.player_.animatedChar_ == null ? "NULL" : "ok"));
         var model:PlayerModel = StaticInjectorContext.getInjector().getInstance(PlayerModel);
         Diag.at("MyPlayerToolTip: charList=" + (model == null || model.charList == null ? "NULL" : "ok"));
         if (model != null && model.charList != null)
         {
            this.player_.accountId_ = model.charList.accountId_;
            this.player_.fame_ = model.charList.fame_;
         }
         Diag.at("MyPlayerToolTip: building panel");
         this.playerPanel_ = new GameObjectListItem(11776947,true,this.player_, false, true, true);
         addChild(this.playerPanel_);
         Diag.at("MyPlayerToolTip: panel ok");
         _loc3_ = 40;
         this.hpBar_ = new StatusBar(176,16,14693428,5526612,"HP");
         this.hpBar_.x = 6;
         this.hpBar_.y = _loc3_ + 2;
         addChild(this.hpBar_);
         _loc3_ = Number(_loc3_ + 24);
         this.mpBar_ = new StatusBar(176,16,6325472,5526612,"MP");
         this.mpBar_.x = 6;
         this.mpBar_.y = _loc3_;
         this.mpBar_.visible = true;
         addChild(this.mpBar_);
         Diag.at("MyPlayerToolTip: bars ok");
         _loc3_ = Number(_loc3_ + 24);
         this.stats_ = new StatsView(188, 45);
         Diag.at("MyPlayerToolTip: stats draw");
         this.stats_.draw(this.player_);
         Diag.at("MyPlayerToolTip: stats ok");
         this.stats_.x = 6;
         this.stats_.y = _loc3_ - 3;
         addChild(this.stats_);
         _loc3_ = Number(_loc3_ + 48);
         Diag.at("MyPlayerToolTip: eGrid slotTypes="
                 + (this.player_.slotTypes_ == null ? "NULL" : "ok")
                 + " equipment=" + (this.player_.equipment_ == null ? "NULL" : "ok")
                 + " equipData=" + (this.player_.equipData_ == null ? "NULL" : "ok"));
         this.eGrid = new EquippedGrid(null,this.player_.slotTypes_,this.player_);
         this.eGrid.x = 8;
         this.eGrid.y = _loc3_;
         addChild(this.eGrid);
         this.eGrid.setItems(this.player_.equipment_, this.player_.equipData_);
         Diag.at("MyPlayerToolTip: eGrid ok");
         _loc3_ = Number(_loc3_ + 48);
         this.iGrid = new InventoryGrid(null,this.player_,GeneralConstants.NUM_EQUIPMENT_SLOTS);
         this.iGrid.x = 8;
         this.iGrid.y = _loc3_;
         addChild(this.iGrid);
         this.iGrid.setItems(this.player_.equipment_, this.player_.equipData_);
         Diag.at("MyPlayerToolTip: iGrid ok");
         _loc3_ = Number(_loc3_ + 92);
         if(this.player_.hasBackpack_)
         {
            this.bGrid = new InventoryGrid(null,this.player_, 4+8);
            this.bGrid.x = 8;
            this.bGrid.y = _loc3_;
            addChild(this.bGrid);
            this.bGrid.setItems(this.player_.equipment_, this.player_.equipData_);
            _loc3_ = Number(_loc3_ + 92);
         }
         _loc3_ = Number(_loc3_ + 8);
         Diag.at("MyPlayerToolTip: grids done");
         this.lineBreak_ = new LineBreakDesign(175,0x151515);
         this.lineBreak_.x = 7;
         this.lineBreak_.y = _loc3_ - 7;
         addChild(this.lineBreak_);
         Diag.at("MyPlayerToolTip: lineBreak ok, charStats="
                 + (charStats == null ? "NULL" : "ok"));
         var numStars:int = charStats == null?int(0):int(charStats.numStars());
         Diag.at("MyPlayerToolTip: numStars=" + numStars);
         this.bestLevel_ = new SimpleText(14,6206769,false,0,0);
         this.bestLevel_.text = numStars + " of 5 Class Quests Completed\n" + "Best Level Achieved: " + (charStats != null?charStats.bestLevel():0).toString() + "\n" + "Best Fame Achieved: " + (charStats != null?charStats.bestFame():0).toString();
         this.bestLevel_.updateMetrics();
         this.bestLevel_.filters = [new DropShadowFilter(0,0,0)];
         this.bestLevel_.x = 6;
         this.bestLevel_.y = height;
         addChild(this.bestLevel_);
         Diag.at("MyPlayerToolTip: bestLevel ok");
         var nextStarFame:int = FameUtil.nextStarFame(charStats == null?int(0):int(charStats.bestFame()),0);
         Diag.at("MyPlayerToolTip: nextStarFame=" + nextStarFame
                 + " playerXML=" + (playerXML == null ? "NULL" : "ok"));
         if(nextStarFame > 0)
         {
            this.nextClassQuest_ = new SimpleText(13,16549442,false,174,0);
            this.nextClassQuest_.text = "Next Goal: Earn " + nextStarFame + " Fame\n" + "  with a " + playerXML.@id;
            this.nextClassQuest_.updateMetrics();
            this.nextClassQuest_.filters = [new DropShadowFilter(0,0,0)];
            this.nextClassQuest_.x = 8;
            this.nextClassQuest_.y = height - 2;
            addChild(this.nextClassQuest_);
            Diag.at("MyPlayerToolTip: nextClassQuest ok");
         }
      }
      
      override public function draw() : void
      {
         this.hpBar_.draw(this.player_.hp_,this.player_.maxHP_,this.player_.maxHPBoost_,this.player_.maxHPMax_);
         this.mpBar_.draw(this.player_.mp_,this.player_.maxMP_,this.player_.maxMPBoost_,this.player_.maxMPMax_);
         this.lineBreak_.setWidthColor(175,1842204);
         super.draw();
      }
   }
}
