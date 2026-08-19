package com.company.assembleegameclient.screens.charrects
{
   import com.company.assembleegameclient.appengine.SavedCharacter;
   import com.company.assembleegameclient.objects.ObjectLibrary;
   import com.company.assembleegameclient.util.AnimatedChar;
   import com.company.assembleegameclient.util.FameUtil;
   import com.company.rotmg.graphics.StarGraphic;
   import com.company.ui.SimpleText;
   import com.company.util.BitmapUtil;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.filters.DropShadowFilter;
   import flash.geom.ColorTransform;
   import kabam.rotmg.core.model.PlayerModel;
   import kabam.rotmg.util.Diag;
   
   public class CreateNewCharacterRect extends CharacterRect
   {
       
      
      private var bitmap_:Bitmap;
      
      private var classNameText_:SimpleText;
      
      private var taglineIcon_:Sprite;
      
      private var taglineText_:SimpleText;
      
      public function CreateNewCharacterRect(model:PlayerModel)
      {
         super(5526612,7829367);
         makeContainer();
         var pickIndex:int = int(ObjectLibrary.playerChars_.length * Math.random());
         Diag.at("CreateNewCharacterRect: picking " + pickIndex + " of " + ObjectLibrary.playerChars_.length);
         var playerXML:XML = ObjectLibrary.playerChars_[pickIndex];
         Diag.at("CreateNewCharacterRect: playerXML " + (playerXML == null ? "NULL" : "ok"));
         var bd:BitmapData = SavedCharacter.getImage(null,playerXML,AnimatedChar.RIGHT,AnimatedChar.STAND,0,false,false);
         Diag.at("CreateNewCharacterRect: getImage returned " + (bd == null ? "NULL" : "ok"));
         bd = BitmapUtil.cropToBitmapData(bd,6,6,bd.width - 12,bd.height - 6);
         Diag.at("CreateNewCharacterRect: cropped ok, selectContainer="
                 + (selectContainer == null ? "NULL" : "ok") + " model=" + (model == null ? "NULL" : "ok"));
         this.bitmap_ = new Bitmap();
         this.bitmap_.bitmapData = bd;
         this.bitmap_.x = 3;
         selectContainer.addChild(this.bitmap_);
         Diag.at("CreateNewCharacterRect: bitmap added");
         this.classNameText_ = new SimpleText(18,16777215,false,0,0);
         this.classNameText_.setBold(true);
         this.classNameText_.text = "New Character";
         this.classNameText_.updateMetrics();
         this.classNameText_.filters = [new DropShadowFilter(0,0,0,1,8,8)];
         this.classNameText_.x = 58;
         this.classNameText_.y = 5;
         selectContainer.addChild(this.classNameText_);
         Diag.at("CreateNewCharacterRect: name text added, calling model.getNumStars()");
         if(model.getNumStars() != FameUtil.maxStars())
         {
            Diag.at("CreateNewCharacterRect: building tagline");
            this.taglineIcon_ = new StarGraphic();
            this.taglineIcon_.transform.colorTransform = new ColorTransform(179 / 255,179 / 255,179 / 255);
            this.taglineIcon_.scaleX = 1.2;
            this.taglineIcon_.scaleY = 1.2;
            this.taglineIcon_.x = 58;
            this.taglineIcon_.y = 31;
            this.taglineIcon_.filters = [new DropShadowFilter(0,0,0)];
            selectContainer.addChild(this.taglineIcon_);
            Diag.at("CreateNewCharacterRect: tagline icon added");
            this.taglineText_ = new SimpleText(14,11776947,false,0,0);
            this.taglineText_.text = FameUtil.maxStars() - model.getNumStars() + " Class quests not yet completed";
            this.taglineText_.updateMetrics();
            this.taglineText_.filters = [new DropShadowFilter(0,0,0,1,8,8)];
            this.taglineText_.x = 58 + this.taglineIcon_.width + 2;
            this.taglineText_.y = 31;
            selectContainer.addChild(this.taglineText_);
            Diag.at("CreateNewCharacterRect: tagline text added");
         }
         Diag.at("CreateNewCharacterRect: constructor complete");
      }
   }
}
