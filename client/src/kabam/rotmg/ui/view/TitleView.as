package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.constants.ScreenTypes;
import com.company.assembleegameclient.screens.AccountScreen;
import com.company.assembleegameclient.screens.TitleMenuOption;
import com.company.assembleegameclient.ui.SoundIcon;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;

import kabam.rotmg.ui.model.EnvironmentData;
import kabam.rotmg.ui.view.components.DarkenFactory;
import org.osflash.signals.Signal;

/**
 * Title screen: parallax background, floating logo, single play banner.
 *
 * Layout is authored against an 800x600 design space and mapped onto the real
 * stage in positionButtons(). Two uniform scales are used deliberately:
 *
 *   cover = max(sw/800, sh/600)  background, so it always fills the stage
 *   ui    = min(sw/800, sh/600)  logo and play, so they fit rather than
 *                                balloon on a wide window
 *
 * Both apply the same factor to x and y. Separate scaleX/scaleY is what
 * stretched the logo in fullscreen.
 *
 * Parallax is an offset about each element resting centre, so with the mouse
 * in the middle of the screen everything sits exactly centred. The previous
 * version eased toward -mouseX * k, which is zero only at the extreme left
 * edge, so the logo could never actually centre.
 */
public class TitleView extends Sprite
{
   private static const COPYRIGHT:String = "betterSkillys :)";

   /** Logo and play art are authored at 2x so they stay sharp when enlarged. */
   private static const ART_SCALE:Number = 0.5;

   /* Pixels of travel per pixel of mouse offset from centre. Logo and play
      share one factor so they track together as a single foreground plane,
      moving faster than the background so both float in front of it. */
   private static const PARALLAX_BG:Number = 0.020;
   private static const PARALLAX_FOREGROUND:Number = 0.035;
   /** Per-frame approach rate for every eased value here. */
   private static const EASE:Number = 0.08;

   /** Scrim over the background so the logo and banner carry the eye. */
   private static const DARKEN:Number = 0.35;

   private static const PLAY_HOVER_GROW:Number = 0.06;
   private static const PLAY_HOVER_LIGHT:Number = 42;

   public var playClicked:Signal;
   public var serversClicked:Signal;
   public var creditsClicked:Signal;
   public var accountClicked:Signal;
   public var legendsClicked:Signal;
   public var editorClicked:Signal;

   private var bgLayer:Bitmap;
   private var bgDarken:Shape;
   private var logoBanner:Sprite;
   private var playBanner:Sprite;
   private var playBitmap:Bitmap;

   private var bgRestX:Number = 0;
   private var bgRestY:Number = 0;
   private var logoCX:Number = 0;
   private var logoCY:Number = 0;
   private var playCX:Number = 0;
   private var playCY:Number = 0;
   private var uiScale:Number = ART_SCALE;

   private var offX:Number = 0;
   private var offY:Number = 0;

   private var playHover:Number = 0;
   private var playHoverTarget:Number = 0;

   private var container:Sprite;
   private var playButton:TitleMenuOption;
   private var serversButton:TitleMenuOption;
   private var creditsButton:TitleMenuOption;
   private var accountButton:TitleMenuOption;
   private var legendsButton:TitleMenuOption;
   private var editorButton:TitleMenuOption;

   private var versionText:SimpleText;
   private var copyrightText:SimpleText;
   private var darkenFactory:DarkenFactory;
   private var data:EnvironmentData;

   public function TitleView()
   {
      this.darkenFactory = new DarkenFactory();
      super();
      this.bgLayer = new TitleView_BackgroundLayer();
      addChild(this.bgLayer);

      /* Sits above the background but below the logo, so only the backdrop
         is dimmed - the parallax still shows through it. */
      this.bgDarken = new Shape();
      addChild(this.bgDarken);

      this.logoBanner = new Sprite();
      this.logoBanner.addChild(new TitleView_LogoLayer());
      this.logoBanner.mouseEnabled = false;
      this.logoBanner.mouseChildren = false;
      addChild(this.logoBanner);

      this.makePlayBanner();
      addChild(new AccountScreen());
      this.makeChildren();
      addChild(new SoundIcon());
      addEventListener(Event.ENTER_FRAME, this.onFrame);
   }

   private function makePlayBanner() : void
   {
      this.playBanner = new Sprite();
      this.playBitmap = new TitleView_PlayButton();
      this.playBanner.addChild(this.playBitmap);
      this.playBanner.buttonMode = true;
      this.playBanner.useHandCursor = true;
      this.playBanner.mouseChildren = false;
      this.playBanner.addEventListener(MouseEvent.ROLL_OVER, this.onPlayOver);
      this.playBanner.addEventListener(MouseEvent.ROLL_OUT, this.onPlayOut);
      this.playBanner.addEventListener(MouseEvent.CLICK, this.onPlayClick);
      addChild(this.playBanner);
   }

   private function onPlayOver(e:MouseEvent) : void
   {
      this.playHoverTarget = 1;
   }

   private function onPlayOut(e:MouseEvent) : void
   {
      this.playHoverTarget = 0;
   }

   private function onPlayClick(e:MouseEvent) : void
   {
      this.removeListener(e);
      this.playBanner.mouseEnabled = false;
      /* The same signal the old text button dispatched, so TitleMediator does
         not need to know the title screen was reskinned. */
      this.playClicked.dispatch();
   }

   private function onFrame(e:Event) : void
   {
      if (stage == null)
      {
         return;
      }
      var tx:Number = stage.stageWidth / 2 - mouseX;
      var ty:Number = stage.stageHeight / 2 - mouseY;
      this.offX = this.offX + (tx - this.offX) * EASE;
      this.offY = this.offY + (ty - this.offY) * EASE;

      this.bgLayer.x = this.bgRestX + this.offX * PARALLAX_BG;
      this.bgLayer.y = this.bgRestY + this.offY * PARALLAX_BG;

      this.logoBanner.x = this.logoCX - this.logoBanner.width / 2 + this.offX * PARALLAX_FOREGROUND;
      this.logoBanner.y = this.logoCY - this.logoBanner.height / 2 + this.offY * PARALLAX_FOREGROUND;

      this.playHover = this.playHover + (this.playHoverTarget - this.playHover) * 0.22;
      var s:Number = this.uiScale * (1 + PLAY_HOVER_GROW * this.playHover);
      this.playBanner.scaleX = s;
      this.playBanner.scaleY = s;
      /* Recentre after scaling so it swells in place, then apply the same
         parallax offset the logo uses so the two move as one unit. */
      this.playBanner.x = this.playCX - this.playBanner.width / 2 + this.offX * PARALLAX_FOREGROUND;
      this.playBanner.y = this.playCY - this.playBanner.height / 2 + this.offY * PARALLAX_FOREGROUND;
      var lift:Number = PLAY_HOVER_LIGHT * this.playHover;
      var ct:ColorTransform = this.playBitmap.transform.colorTransform;
      ct.redOffset = lift;
      ct.greenOffset = lift;
      ct.blueOffset = lift;
      this.playBitmap.transform.colorTransform = ct;
   }

   private function makeChildren() : void
   {
      /* These still exist because TitleMediator binds to their clicked
         signals; only the play banner is actually on screen. */
      this.container = new Sprite();
      this.playButton = new TitleMenuOption(ScreenTypes.PLAY,36,true);
      this.playClicked = this.playButton.clicked;
      this.serversButton = new TitleMenuOption(ScreenTypes.SERVERS,22,false);
      this.serversClicked = this.serversButton.clicked;
      this.creditsButton = new TitleMenuOption(ScreenTypes.CREDITS,22,false);
      this.creditsClicked = this.creditsButton.clicked;
      this.accountButton = new TitleMenuOption(ScreenTypes.ACCOUNT,22,false);
      this.accountClicked = this.accountButton.clicked;
      this.legendsButton = new TitleMenuOption(ScreenTypes.LEGENDS,22,false);
      this.legendsClicked = this.legendsButton.clicked;
      /* The only remaining route to the map editor: the bottom row it used
         to live in was removed with the title screen rework. Small and in the
         corner so it stays out of the way of the logo and play banner. */
      this.editorButton = new TitleMenuOption(ScreenTypes.EDITOR,18,false);
      this.editorButton.setTextColor(0xE6C88C);
      this.editorClicked = this.editorButton.clicked;
      this.versionText = new SimpleText(12,0xaaaaaa,false,0,0);
      this.versionText.filters = [new DropShadowFilter(0,0,0)];
      this.copyrightText = new SimpleText(12,0xaaaaaa,false,0,0);
      this.copyrightText.text = COPYRIGHT;
      this.copyrightText.updateMetrics();
      this.copyrightText.filters = [new DropShadowFilter(0,0,0)];
   }

   public function addListeners():void
   {
      this.playButton.addEventListener(MouseEvent.CLICK, removeListener);
   }

   public function removeListener(e:Event):void
   {
      if (stage)
      {
         stage.removeEventListener("resize", positionButtons);
      }
      this.playButton.removeEventListener(MouseEvent.CLICK, removeListener);
   }

   public function initialize(data:EnvironmentData) : void
   {
      this.data = data;
      this.updateVersionText();
      this.positionButtons();
      addChild(this.container);
      addChild(this.editorButton);
      this.addListeners();
      if (stage)
      {
         stage.addEventListener("resize", positionButtons);
      }
   }

   private function updateVersionText() : void
   {
      this.versionText.htmlText = this.data.buildLabel;
      this.versionText.updateMetrics();
   }

   public function positionButtons(e:Event = null) : void
   {
      if (stage == null)
      {
         return;
      }
      if (e != null)
      {
         AccountScreen.reSize(e);
      }
      var sw:Number = stage.stageWidth;
      var sh:Number = stage.stageHeight;

      /* Uniform cover scale, centred: the 880x680 art always overhangs the
         stage so parallax cannot expose an edge. */
      this.bgDarken.graphics.clear();
      this.bgDarken.graphics.beginFill(0, DARKEN);
      this.bgDarken.graphics.drawRect(0, 0, sw, sh);
      this.bgDarken.graphics.endFill();

      var cover:Number = Math.max(sw / 800, sh / 600);
      this.bgLayer.scaleX = cover;
      this.bgLayer.scaleY = cover;
      this.bgRestX = (sw - 880 * cover) / 2;
      this.bgRestY = (sh - 680 * cover) / 2;

      /* Uniform fit scale, held at the proportional heights they were laid
         out at in the 800x600 design space. */
      this.uiScale = Math.min(sw / 800, sh / 600) * ART_SCALE;
      this.logoBanner.scaleX = this.uiScale;
      this.logoBanner.scaleY = this.uiScale;
      this.logoCX = sw / 2;
      this.logoCY = sh * (175 / 600);
      this.playCX = sw / 2;
      this.playCY = sh * (466 / 600);

      this.editorButton.x = 14;
      this.editorButton.y = sh - this.editorButton.height - 10;
   }
}
}
