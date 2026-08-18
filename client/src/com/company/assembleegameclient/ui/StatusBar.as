package com.company.assembleegameclient.ui
{
import com.company.assembleegameclient.parameters.Parameters;
import com.company.ui.SimpleText;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

import org.osflash.signals.Signal;

public class StatusBar extends Sprite
{
   public static var barTextSignal:Signal = new Signal(int);

   public const DEFAULT_FILTER:DropShadowFilter = new DropShadowFilter(0,0,0);

   public var w_:int;

   public var h_:int;

   public var color_:uint;

   public var backColor_:uint;

   public var pulseBackColor:uint;

   public var textColor_:uint;

   public var val_:int = -1;

   public var max_:int = -1;

   public var boost_:int = -1;

   public var maxMax_:int = -1;

   public var maxText_:String;

   public var labelText_:SimpleText;

   public var valueText_:SimpleText;

   public var boostText_:SimpleText;

   private var colorSprite:Sprite;

   private var defaultForegroundColor:Number;

   private var defaultBackgroundColor:Number;

   public var mouseOver_:Boolean = false;

   private var isPulsing:Boolean = false;

   private var repetitions:int;

   private var direction:int = -1;

   private var speed:Number = 0.1;

   public var multiplierIcon:Sprite;

   private var multiplierText:SimpleText;

   public var postMax_:int = -1;

   public var level_:int = 0;

   public var forceNumText_:Boolean = false;

   private var isProgressBar_:Boolean = false;

   private var isVert_:Boolean = false;

   private var disableText_:Boolean = false;

   /* Opt-in rounded track + border. Off by default because StatusBar is also
      used for the vault, boost panel and vertical meters, which should keep
      their square styling. Enable with setRoundedStyle(). */
   private var cornerRadius_:Number = 0;

   private var borderColor_:uint = 0;

   private var borderThickness_:Number = 0;

   public function StatusBar(w:int, h:int, color:uint, backColor:uint, label:String = null, forceNumText:Boolean = false, isProgressBar:Boolean = false, vertical:Boolean = false, size:int = 14, visibleLabel:Boolean = true)
   {
      this.isVert_ = vertical;
      this.colorSprite = new Sprite();
      super();
      addChild(this.colorSprite);
      this.forceNumText_ = forceNumText;
      this.isProgressBar_ = isProgressBar;
      this.w_ = w;
      this.h_ = h;
      this.defaultForegroundColor = this.color_ = color;
      this.defaultBackgroundColor = this.backColor_ = backColor;
      this.textColor_ = 16777215;
      if(label != null && label.length != 0)
      {
         this.labelText_ = new SimpleText(size,this.textColor_,false,0,0);
         this.labelText_.setBold(true);
         this.labelText_.text = label;
         this.labelText_.updateMetrics();
         this.labelText_.y = -3;
         this.labelText_.filters = [new DropShadowFilter(0,0,0)];
         this.labelText_.visible = visibleLabel;
         addChild(this.labelText_);
      }
      this.valueText_ = new SimpleText(size,16777215,false,0,0);
      this.valueText_.setBold(true);
      this.valueText_.filters = [new DropShadowFilter(0,0,0)];
      this.valueText_.y = -2;
      this.boostText_ = new SimpleText(size,this.textColor_,false,0,0);
      this.boostText_.setBold(true);
      this.boostText_.alpha = 0.6;
      this.boostText_.y = -1;
      this.boostText_.filters = [new DropShadowFilter(0,0,0)];
      this.multiplierIcon = new Sprite();
      this.multiplierIcon.x = this.w_ - 25;
      this.multiplierIcon.y = -1;
      this.multiplierIcon.graphics.beginFill(16711935,0);
      this.multiplierIcon.graphics.drawRect(0,0,20,20);
      this.multiplierIcon.addEventListener("mouseOver",this.onMultiplierOver,false,0,true);
      this.multiplierIcon.addEventListener("mouseOut",this.onMultiplierOut,false,0,true);
      this.multiplierText = new SimpleText(14, 9493531);
      this.multiplierText.setBold(true);
      this.multiplierText.setText("x2");
      this.multiplierText.filters = [this.DEFAULT_FILTER];
      this.multiplierIcon.addChild(this.multiplierText);
      if(!this.bTextEnabled(Parameters.data_.toggleBarText))
      {
         addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
         addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      }
      barTextSignal.add(this.setBarText);
      if(this.isVert_){
         this.valueText_.x = -3;
         this.valueText_.rotation = 270;
         if(this.labelText_ != null) {
            this.labelText_.rotation = 270;
            this.labelText_.y = this.h_ - 6;
            this.labelText_.x = (this.w_ / 2) - (this.labelText_.width / 2);
         }
         this.boostText_.x = -3;
         this.boostText_.rotation = 270;
      }
   }

   public function setMaxText(text:String):void{
      this.maxText_ = text;
   }

   public function setBarColor(color:uint):void{
      this.color_ = color;
   }

   /**
    * Give the bar a rounded track with a coloured border (used by the HUD
    * hp/mp/xp meters). Radius is clamped to half the bar height so it can't
    * invert on short bars.
    */
   public function setRoundedStyle(cornerRadius:Number, borderColor:uint, borderThickness:Number = 2):void{
      this.cornerRadius_ = Math.min(cornerRadius, this.h_ / 2);
      this.borderColor_ = borderColor;
      this.borderThickness_ = borderThickness;
      this.internalDraw();
   }

   public function disableText(value:Boolean):void{
      this.disableText_ = value;
   }

   public function showMultiplierText() : void
   {
      this.multiplierIcon.mouseEnabled = false;
      this.multiplierIcon.mouseChildren = false;
      addChild(this.multiplierIcon);
      this.startPulse(3,9493531,16777215);
   }

   public function setBarText(param1:int) : void
   {
      this.mouseOver_ = false;
      if(this.bTextEnabled(param1))
      {
         removeEventListener("rollOver",this.onMouseOver);
         removeEventListener("rollOut",this.onMouseOut);
      }
      else
      {
         addEventListener("rollOver",this.onMouseOver);
         addEventListener("rollOut",this.onMouseOut);
      }
      this.internalDraw();
   }

   public function hideMultiplierText() : void
   {
      if(this.multiplierIcon.parent)
      {
         removeChild(this.multiplierIcon);
      }
   }

   private function onMultiplierOver(event:MouseEvent) : void
   {
      dispatchEvent(new Event("MULTIPLIER_OVER"));
   }

   private function onMultiplierOut(event:MouseEvent) : void
   {
      dispatchEvent(new Event("MULTIPLIER_OUT"));
   }

   public function draw(val:int, max:int, boost:int, maxMax:int = -1, postMax:int = -1, level:int = 0) : void
   {
      if(max > 0)
      {
         val = Math.min(max,Math.max(0,val));
      }
      if(val == this.val_ && max == this.max_ && boost == this.boost_ && maxMax == this.maxMax_)
      {
         return;
      }
      this.val_ = val;
      this.max_ = max;
      this.boost_ = boost;
      this.maxMax_ = maxMax;
      this.postMax_ = postMax;
      this.level_ = level;
      this.internalDraw();
   }

   private function setTextColor(textColor:uint) : void
   {
      this.textColor_ = textColor;
      if(this.boostText_ != null)
      {
         this.boostText_.setColor(this.textColor_);
      }
      this.valueText_.setColor(this.textColor_);
   }

   private function internalDraw() : void {
      graphics.clear();
      this.colorSprite.graphics.clear();
      var textColor:uint = 0xFFFFFF;
      if ((((this.maxMax_ > 0)) && (((this.max_ - this.boost_) == this.maxMax_)))) {
         textColor = 0xFCDF00;
      }
      else {
         if (this.boost_ > 0) {
            textColor = 6206769;
         }
      }
      if (this.textColor_ != textColor) {
         this.setTextColor(textColor);
      }
      var r:Number = this.cornerRadius_;
      graphics.beginFill(this.backColor_);
      if (r > 0) {
         graphics.drawRoundRect(0, 0, this.w_, this.h_, r * 2, r * 2);
      } else {
         graphics.drawRect(0, 0, this.w_, this.h_);
      }
      graphics.endFill();
      if (this.isPulsing) {
         this.colorSprite.graphics.beginFill(this.pulseBackColor);
         this.drawTrack(this.colorSprite, this.w_, r);
      }
      this.colorSprite.graphics.beginFill(this.color_);
      if (this.max_ > 0) {
         if (this.isVert_) {
            this.colorSprite.graphics.drawRect(0, this.h_, this.w_, -this.h_ * (this.val_ / this.max_));
         } else {
            this.drawTrack(this.colorSprite, this.w_ * (this.val_ / this.max_), r);
         }
      } else {
         this.drawTrack(this.colorSprite, this.w_, r);
      }
      this.colorSprite.graphics.endFill();
      /* Border last so it sits over the fill rather than being covered by it. */
      if (r > 0 && this.borderThickness_ > 0) {
         graphics.lineStyle(this.borderThickness_, this.borderColor_, 1, true);
         graphics.drawRoundRect(this.borderThickness_ / 2, this.borderThickness_ / 2,
                                this.w_ - this.borderThickness_, this.h_ - this.borderThickness_,
                                r * 2, r * 2);
         graphics.lineStyle();
      }
      if (!this.disableText_) {
         if (this.bTextEnabled(Parameters.data_.toggleBarText) || this.mouseOver_ && this.h_ > 4 || this.forceNumText_) {

            var _loc1_:int = 0;
            var _loc2_:String = "";
            _loc1_ = this.maxMax_ - (this.max_ - this.boost_);
            if (this.level_ >= 20 && _loc1_ > 0) {
               _loc2_ = _loc2_ + ("|" + Math.ceil(_loc1_ * 0.2));
            }
            if (this.max_ > 0) {
               this.valueText_.text = "" + this.val_ + "/" + this.max_ + _loc2_;
            } else {
               this.valueText_.text = "" + this.val_;
            }
            if(this.maxText_ != null && this.val_ == this.max_){
               this.valueText_.text = this.maxText_;
            }
            this.valueText_.updateMetrics();
            if (!contains(this.valueText_)) {
               addChild(this.valueText_);
            }
            if (this.boost_ != 0) {
               this.boostText_.text = " (" + (this.boost_ > 0 ? "+" : "") + this.boost_.toString() + ")";
               this.boostText_.updateMetrics();

               if(this.isVert_){
                  this.boostText_.x = (this.w_ / 2) - (this.boostText_.width / 2);
                  this.valueText_.y = (this.h_ / 2) + (this.valueText_.height / 2);
                  this.valueText_.x = (this.w_ / 2) - (this.valueText_.width / 2);
                  this.boostText_.y = this.valueText_.y - (this.boostText_.height / 2);
               }
               else{
                  this.valueText_.x = this.w_ / 2 - (this.valueText_.width + this.boostText_.width) / 2;
                  this.boostText_.x = this.valueText_.x + this.valueText_.width;
               }
               if (!contains(this.boostText_)) {
                  addChild(this.boostText_);
               }
            } else {
               if(this.isVert_){
                  this.valueText_.y = this.h_ / 2 + this.valueText_.height / 2;
               }
               this.valueText_.x = this.w_ / 2 - this.valueText_.width / 2;
               if (contains(this.boostText_)) {
                  removeChild(this.boostText_);
               }
            }
         } else {
            if (contains(this.valueText_)) {
               removeChild(this.valueText_);
            }
            if (contains(this.boostText_)) {
               removeChild(this.boostText_);
            }
         }
      }
   }

   /**
    * Fill segment of the track. A rounded rect narrower than its own diameter
    * renders as a lens shape, so the radius is clamped to half the segment
    * width - a nearly-empty bar then reads as a small pill instead.
    */
   private function drawTrack(target:Sprite, width:Number, radius:Number) : void
   {
      if (width <= 0) {
         return;
      }
      if (radius <= 0) {
         target.graphics.drawRect(0, 0, width, this.h_);
         return;
      }
      var r:Number = Math.min(radius, width / 2);
      target.graphics.drawRoundRect(0, 0, width, this.h_, r * 2, r * 2);
   }

   public function startPulse(repetitions:Number, foregroundColor:Number, backgroundColor:Number) : void
   {
      this.isPulsing = true;
      this.color_ = foregroundColor;
      this.pulseBackColor = backgroundColor;
      this.repetitions = repetitions;
      this.internalDraw();
      addEventListener(Event.ENTER_FRAME,this.onPulse);
   }

   private function bTextEnabled(param1:int) : Boolean
   {
      return param1 && (param1 == 1 || param1 == 2 && this.isProgressBar_ || param1 == 3 && !this.isProgressBar_);
   }

   private function onPulse(event:Event) : void
   {
      if(this.colorSprite.alpha > 1 || this.colorSprite.alpha < 0)
      {
         this.direction = this.direction * -1;
         if(this.colorSprite.alpha > 1)
         {
            this.repetitions--;
            if(!this.repetitions)
            {
               this.isPulsing = false;
               this.color_ = this.defaultForegroundColor;
               this.backColor_ = this.defaultBackgroundColor;
               this.colorSprite.alpha = 1;
               this.internalDraw();
               removeEventListener(Event.ENTER_FRAME,this.onPulse);
            }
         }
      }
      this.colorSprite.alpha = this.colorSprite.alpha + this.speed * this.direction;
   }

   private function onMouseOver(event:MouseEvent) : void
   {
      this.mouseOver_ = true;
      this.internalDraw();
   }

   private function onMouseOut(event:MouseEvent) : void
   {
      this.mouseOver_ = false;
      this.internalDraw();
   }
}
}
