package com.company.assembleegameclient.screens
{
   import com.company.assembleegameclient.appengine.SavedCharactersList;
   import com.company.assembleegameclient.objects.ObjectLibrary;
   import com.company.rotmg.graphics.ScreenGraphic;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;

import io.decagames.rotmg.ui.buttons.SliceScalingButton;
import io.decagames.rotmg.ui.defaults.DefaultLabelFormat;
import io.decagames.rotmg.ui.sliceScaling.SliceScalingBitmap;
import io.decagames.rotmg.ui.texture.TextureParser;

import kabam.rotmg.core.model.PlayerModel;
import kabam.rotmg.util.Diag;
   import kabam.rotmg.game.view.CreditDisplay;
   import kabam.rotmg.ui.view.components.ScreenBase;
   import org.osflash.signals.Signal;

   public class NewCharacterScreen extends Sprite
   {
      private var backButton_:TitleMenuOption;
      private var creditDisplay_:CreditDisplay;

      /** Same gold as the character screen and menu banners. */
      private static const GOLD:uint = 0xE6C88C;
      /** Decorative rule under the title; art is 2x, drawn at half. */
      private var titleDivider:Bitmap;
      /** Plate behind the back button label. */
      private var backPlate:Bitmap;

      /* Eased hover on the back button, matching the play banners and the
         class boxes so every button on the screen behaves the same. */
      private static const HOVER_GROW:Number = 0.06;
      private static const HOVER_LIGHT:Number = 42;
      private static const HOVER_EASE:Number = 0.22;
      private var backHover:Number = 0;
      private var backHoverTarget:Number = 0;
      private var backPlateCX:Number = 0;
      private var backPlateCY:Number = 0;
      private var backPlateScale:Number = 1;
      /** Room the divider needs before the first row of class boxes. */
      private static const CLASS_GRID_TOP:int = 130;
      private var boxes_:Object;
      public var tooltip:Signal;
      public var close:Signal;
      public var selected:Signal;
      private var title:SimpleText;
      private var graphic:Sprite;
      private var lines:Sprite;
      private var container:Sprite;

      private var isInitialized:Boolean = false;

      public function NewCharacterScreen()
      {
         this.boxes_ = {};
         super();
         this.tooltip = new Signal(Sprite);
         this.selected = new Signal(int);
         this.close = new Signal();
         addChild(new ScreenBase(true));
         addChild(new AccountScreen());
      }

      private function makeTitleText() : void
      {
         this.title = new SimpleText(32,GOLD,false,0,0);
         this.title.setBold(true);
         this.title.text = "Classes";
         this.title.updateMetrics();
         this.title.filters = [new DropShadowFilter(0,0,0,1,8,8)];
         this.title.x = 400 - this.title.width / 2;
         this.title.y = 24;
         addChild(this.title);

         this.titleDivider = new ClassesDivider();
         this.titleDivider.scaleX = 0.5;
         this.titleDivider.scaleY = 0.5;
         addChild(this.titleDivider);
      }

      private function positionButtons(e:Event = null) : void
      {
         if (e != null)
         {
            ScreenBase.reSize(e);
            AccountScreen.reSize(e);
         }

         var width:int = WebMain.STAGE.stageWidth;
         var height:int = WebMain.STAGE.stageHeight;
         this.container.x = (width / 2) - (this.container.width / 2);
         this.creditDisplay_.x = width;
         this.title.x = (width / 2) - (this.title.width / 2);
         if (this.titleDivider != null)
         {
            /* Centred under the title, which sits at y 24 and is ~40 tall. */
            /* Sized to the window so it reads as the rule it replaces, and
               capped at its authored width so it never upscales past 1:1. */
            var dw:Number = Math.min(430, width - 80);
            var ds:Number = dw / 1760;
            this.titleDivider.scaleX = ds;
            this.titleDivider.scaleY = ds;
            this.titleDivider.x = (width / 2) - (this.titleDivider.width / 2);
            this.titleDivider.y = 68;
         }
         this.backButton_.x = (width / 2) - (this.backButton_.width / 2);
         /* The plate centres on the button, so this moves both together. */
         this.backButton_.y = height - 115;
         if (this.backPlate != null)
         {
            /* Must follow the button: this reads backButton_.y, which is only
               assigned on the two lines above. Sized around the label rather
               than a fixed width so the text sits inside the plate. */
            var pw:Number = this.backButton_.width + 280;
            this.backPlateScale = pw / 500;
            this.backPlateCX = width / 2;
            this.backPlateCY = this.backButton_.y + this.backButton_.height / 2;
            this.applyBackHover();
         }
      }

      private function drawLines():Sprite
      {
         /* The grey rule is replaced by the divider bitmap. This still returns
            a Sprite because `lines` is referenced elsewhere, but it draws
            nothing and is NOT added to the stage - it used to addChild itself,
            which is why removing the caller's addChild left it on screen. */
         return new Sprite();
      }

      public function initialize(model:PlayerModel) : void
      {
         var playerXML:XML = null;
         var objectType:int = 0;
         var characterType:String = null;
         var overrideIsAvailable:Boolean = false;
         var charBox:CharacterBox = null;
         var shown:int = 0;
         if(this.isInitialized)
         {
            return;
         }
         this.isInitialized = true;
         /* The black bottom bar is gone - the back button has its own plate.
            makeBar used to addChild itself, so dropping the caller's addChild
            was not enough; the method is removed outright. */
         this.makeTitleText();
         this.backPlate = new BackButtonPlate();
         this.backPlate.scaleX = 0.5;
         this.backPlate.scaleY = 0.5;
         addChild(this.backPlate);
         this.backButton_ = new TitleMenuOption("back",36,false);
         this.backButton_.setTextColor(GOLD);
         this.backButton_.addEventListener(MouseEvent.CLICK,this.onBackClick);
         this.backButton_.addEventListener(MouseEvent.ROLL_OVER,this.onBackOver);
         this.backButton_.addEventListener(MouseEvent.ROLL_OUT,this.onBackOut);
         addEventListener(Event.ENTER_FRAME, this.onBackHoverFrame);
         addChild(this.backButton_);
         this.creditDisplay_ = new CreditDisplay();
         this.creditDisplay_.draw(model.getCredits(),model.getFame());
         addChild(this.creditDisplay_);
         this.creditDisplay_.y = 32;
         this.container = new Sprite();
         addChild(this.container);
         for(var i:int = 0; i < ObjectLibrary.playerChars_.length; i++)
         {
            playerXML = ObjectLibrary.playerChars_[i];
            objectType = int(playerXML.@type);
            characterType = playerXML.@id;
            if(!model.isClassAvailability(characterType,SavedCharactersList.UNAVAILABLE))
            {
               overrideIsAvailable = model.isClassAvailability(characterType,SavedCharactersList.UNRESTRICTED);
               charBox = new CharacterBox(playerXML,model.getCharStats()[objectType],model,overrideIsAvailable);
               /* Lay out by how many boxes have actually been drawn, not by the
                  index into the full class list. Hidden classes leave gaps in i,
                  which used to push the grid off to the right - with only one
                  class visible its box landed in the old slot's position and
                  the container centering below could not correct for it. */
               charBox.x = 120 * int(shown % 6);
               if (shown > 11)
                   charBox.x += 120;
               charBox.y = CLASS_GRID_TOP + 152 * int(shown / 6);
               shown++;
               this.boxes_[objectType] = charBox;
               charBox.addEventListener(MouseEvent.ROLL_OVER,this.onCharBoxOver);
               charBox.addEventListener(MouseEvent.ROLL_OUT,this.onCharBoxOut);
               charBox.characterSelectClicked_.add(this.onCharBoxClick);
               this.container.addChild(charBox);
            }
         }

         /* drawLines' grey rule is replaced by the divider bitmap. */
         this.lines = drawLines();

         this.positionButtons();
         if (WebMain.STAGE)
             WebMain.STAGE.addEventListener(Event.RESIZE, positionButtons);
      }

      private function onBackOver(event:MouseEvent) : void
      {
         this.backHoverTarget = 1;
      }

      private function onBackOut(event:MouseEvent) : void
      {
         this.backHoverTarget = 0;
      }

      private function onBackHoverFrame(event:Event) : void
      {
         if(this.backHover == this.backHoverTarget)
         {
            return;
         }
         this.backHover = this.backHover
                        + (this.backHoverTarget - this.backHover) * HOVER_EASE;
         if(Math.abs(this.backHoverTarget - this.backHover) < 0.002)
         {
            this.backHover = this.backHoverTarget;
         }
         this.applyBackHover();
      }

      /** Grows plate and label together about their shared centre. */
      private function applyBackHover() : void
      {
         if(this.backPlate == null || this.backButton_ == null)
         {
            return;
         }
         var g:Number = 1 + HOVER_GROW * this.backHover;
         var lift:Number = HOVER_LIGHT * this.backHover;
         var ct:ColorTransform = new ColorTransform(1, 1, 1, 1, lift, lift, lift, 0);

         this.backPlate.scaleX = this.backPlateScale * g;
         this.backPlate.scaleY = this.backPlateScale * g;
         this.backPlate.x = this.backPlateCX - this.backPlate.width / 2;
         this.backPlate.y = this.backPlateCY - this.backPlate.height / 2;
         this.backPlate.transform.colorTransform = ct;

         this.backButton_.scaleX = g;
         this.backButton_.scaleY = g;
         this.backButton_.x = this.backPlateCX - this.backButton_.width / 2;
         this.backButton_.y = this.backPlateCY - this.backButton_.height / 2;
      }

      private function onBackClick(event:Event) : void
      {
         this.close.dispatch();
      }

      private function onCharBoxOver(event:MouseEvent) : void
      {
         var charBox:CharacterBox = event.currentTarget as CharacterBox;
         charBox.setOver(true);
         Diag.at("NewCharacterScreen.onCharBoxOver: building tooltip");
         this.tooltip.dispatch(charBox.getTooltip());
      }

      private function onCharBoxOut(event:MouseEvent) : void
      {
         var charBox:CharacterBox = event.currentTarget as CharacterBox;
         charBox.setOver(false);
         this.tooltip.dispatch(null);
      }

      private function onCharBoxClick(event:MouseEvent) : void
      {
         this.tooltip.dispatch(null);
         var charBox:CharacterBox = event.currentTarget.parent as CharacterBox;
         if(!charBox.available_)
         {
            return;
         }
         var objectType:int = charBox.objectType();
         var displayId:String = ObjectLibrary.typeToDisplayId_[objectType];
         this.selected.dispatch(objectType);
      }

      public function updateCreditsAndFame(credits:int, fame:int) : void
      {
         this.creditDisplay_.draw(credits,fame);
      }

      public function update(model:PlayerModel) : void
      {
         var playerXML:XML = null;
         var objectType:int = 0;
         var characterType:String = null;
         var overrideIsAvailable:Boolean = false;
         var charBox:CharacterBox = null;
         for(var i:int = 0; i < ObjectLibrary.playerChars_.length; i++)
         {
            playerXML = ObjectLibrary.playerChars_[i];
            objectType = int(playerXML.@type);
            characterType = String(playerXML.@id);
            if(!model.isClassAvailability(characterType,SavedCharactersList.UNAVAILABLE))
            {
               overrideIsAvailable = model.isClassAvailability(characterType,SavedCharactersList.UNRESTRICTED);
               charBox = this.boxes_[objectType];
               if(charBox)
               {
                  if(overrideIsAvailable || model.isLevelRequirementsMet(objectType))
                  {
                     charBox.unlock();
                  }
               }
            }
         }
      }
   }
}
