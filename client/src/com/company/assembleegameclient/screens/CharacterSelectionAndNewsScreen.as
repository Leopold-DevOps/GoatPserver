package com.company.assembleegameclient.screens
{
import com.company.assembleegameclient.ui.ClickableText;
import com.company.assembleegameclient.ui.Scrollbar;
import com.company.rotmg.graphics.ScreenGraphic;
import com.company.ui.SimpleText;
import com.company.util.UIUtil;

import flash.display.Bitmap;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import kabam.rotmg.core.model.PlayerModel;
import kabam.rotmg.game.view.CreditDisplay;
import kabam.rotmg.news.view.NewsView;
import kabam.rotmg.ui.UIUtils;
import kabam.rotmg.ui.view.components.ScreenBase;
import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeMappedSignal;

public class CharacterSelectionAndNewsScreen extends Sprite
{


    private const SCROLLBAR_REQUIREMENT_HEIGHT:Number = 400;

    private const DROP_SHADOW:DropShadowFilter = new DropShadowFilter(0,0,0,1,8,8);

    private var model:PlayerModel;

    private var isInitialized:Boolean;

    private var nameText:SimpleText;

    private var nameChooseLink_:ClickableText;

    private var creditDisplay:CreditDisplay;

    private var selectACharacterText:SimpleText;

    private var newsText:SimpleText;

    private var characterList:CharacterList;

    private var characterListHeight:Number;

    private var playButton:TitleMenuOption;

    private var backButton:TitleMenuOption;

    private var classesButton:TitleMenuOption;

    private var lines:Shape;

    private var linesTwoContainer:Sprite;

    private var linesTwo:Sprite;

    private var scrollBar:Scrollbar;

    public var close:Signal;

    public var showClasses:Signal;

    public var newCharacter:Signal;

    public var chooseName:Signal;

    public var playGame:Signal;

    public var graphic:Sprite;

    public var newsView:NewsView;

    /*
     * Bottom menu banner. Geometry is in the banner art's own pixel space
     * (CharSelectBanner.png, 1120x373, authored at 2x); the whole sprite is
     * then scaled down, so these never need touching when the stage resizes.
     * Measured off the art - the two dark wells are at x 270 and x 851, both
     * centred on y 190, and the play medallion spans x 464-655.
     */
    private static const BANNER_W:Number = 1120;
    private static const BANNER_H:Number = 373;
    private static const BANNER_LEFT_X:Number = 270;
    private static const BANNER_RIGHT_X:Number = 851;
    private static const BANNER_LABEL_Y:Number = 190;
    private static const ZONE_PLAY_X0:Number = 464;
    private static const ZONE_PLAY_X1:Number = 655;
    /**
     * Art is 2x, drawn at half size. This is a fixed scale on purpose - the
     * banner keeps the same on-screen size in fullscreen instead of growing
     * with the stage, which is what a min(sw/800, sh/600) fit would do.
     */
    private static const BANNER_ART_SCALE:Number = 0.5;
    /** Sampled from the banner's own gold trim, lifted for legibility. */
    private static const GOLD:uint = 0xE6C88C;
    private static const GOLD_HOVER:uint = 0xFFF2D0;

    /* Kept identical to TitleView's play banner so both hovers feel the same. */
    private static const PLAY_HOVER_GROW:Number = 0.06;
    private static const PLAY_HOVER_LIGHT:Number = 42;
    private static const PLAY_HOVER_EASE:Number = 0.22;

    /** Decorative rule under the player name; art is 2x, drawn at half. */
    private var namePlate:Bitmap;

    private var menuBanner:Sprite;
    private var bannerBitmap:Bitmap;
    private var mainLabel:SimpleText;
    private var classesLabel:SimpleText;
    private var bannerHover:Number = 0;
    private var bannerHoverTarget:Number = 0;
    private var bannerCX:Number = 0;
    private var bannerCY:Number = 0;

    public function CharacterSelectionAndNewsScreen()
    {
        this.playButton = new TitleMenuOption("play",36,true);
        this.backButton = new TitleMenuOption("main",22,false);
        this.classesButton = new TitleMenuOption("classes",22,false);
        this.graphic = makeScreenGraphic();
        this.newCharacter = new Signal();
        this.chooseName = new Signal();
        this.playGame = new Signal();
        super();
        addChild(new ScreenBase(true));
        addChild(new AccountScreen());
        this.close = new NativeMappedSignal(this.backButton,MouseEvent.CLICK);
        this.showClasses = new NativeMappedSignal(this.classesButton,MouseEvent.CLICK);
    }

    public function initialize(model:PlayerModel) : void
    {
        if(this.isInitialized)
        {
            return;
        }
        this.isInitialized = true;
        this.model = model;
        this.createDisplayAssets(model);
    }

    private function createDisplayAssets(model:PlayerModel) : void
    {
        this.createNameText();
        this.createCreditDisplay();
        this.createSelectCharacterText();
        //this.createNewsText();
        //this.createNews();
        this.createBoundaryLines();
        this.createCharacterList();
        if(this.characterListHeight > this.SCROLLBAR_REQUIREMENT_HEIGHT)
            this.createScrollbar();
        this.createButtons();
        this.positionButtons();
    }

    private function createButtons() : void
    {
        /* The three TitleMenuOptions stay off the display list: `close` and
           `showClasses` are NativeMappedSignals bound to their CLICK events,
           so the banner's zones dispatch a click on them rather than the
           signals being rewired. */
        this.createMenuBanner();
        this.addListeners();
        if (WebMain.STAGE)
            WebMain.STAGE.addEventListener("resize", positionButtons);
        this.playButton.addEventListener(MouseEvent.CLICK,this.onPlayClick);
    }

    private function createMenuBanner() : void
    {
        this.menuBanner = new Sprite();
        this.bannerBitmap = new CharSelectBanner();
        this.menuBanner.addChild(this.bannerBitmap);

        this.mainLabel = this.makeBannerLabel("MAIN", BANNER_LEFT_X);
        this.classesLabel = this.makeBannerLabel("CLASSES", BANNER_RIGHT_X);

        /* Zones sit above the labels so they take the mouse; an alpha-0 fill
           still hit-tests in Flash, so nothing has to be drawn. */
        this.addZone(0, ZONE_PLAY_X0, this.onMainZone, this.mainLabel);
        this.addZone(ZONE_PLAY_X0, ZONE_PLAY_X1, this.onPlayZone, null);
        this.addZone(ZONE_PLAY_X1, BANNER_W, this.onClassesZone, this.classesLabel);

        addChild(this.menuBanner);
        this.menuBanner.addEventListener(Event.ENTER_FRAME, this.onBannerFrame);
    }

    private function makeBannerLabel(caption:String, centreX:Number) : SimpleText
    {
        /* Authored at the art's 2x scale and shrunk with the sprite, so the
           embedded font still renders as vectors at full sharpness. */
        var t:SimpleText = new SimpleText(38, GOLD, false, 0, 0);
        t.setBold(true);
        t.text = caption;
        t.updateMetrics();
        t.x = centreX - t.width / 2;
        t.y = BANNER_LABEL_Y - t.height / 2;
        this.menuBanner.addChild(t);
        return t;
    }

    private function addZone(x0:Number, x1:Number, onClick:Function, label:SimpleText) : void
    {
        var z:Sprite = new Sprite();
        z.graphics.beginFill(0, 0);
        z.graphics.drawRect(x0, 0, x1 - x0, BANNER_H);
        z.graphics.endFill();
        z.buttonMode = true;
        z.useHandCursor = true;
        z.addEventListener(MouseEvent.CLICK, onClick);
        if (label != null)
        {
            z.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
                label.setColor(GOLD_HOVER);
            });
            z.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
                label.setColor(GOLD);
            });
        }
        else
        {
            z.addEventListener(MouseEvent.ROLL_OVER, this.onPlayZoneOver);
            z.addEventListener(MouseEvent.ROLL_OUT, this.onPlayZoneOut);
        }
        this.menuBanner.addChild(z);
    }

    private function onPlayZoneOver(e:MouseEvent) : void
    {
        this.bannerHoverTarget = 1;
    }

    private function onPlayZoneOut(e:MouseEvent) : void
    {
        this.bannerHoverTarget = 0;
    }

    /**
     * Eases the play hover. Deliberately mirrors TitleView.onFrame so the two
     * play buttons grow and brighten identically - same grow, same lift, same
     * approach rate, and the same recentre-after-scaling so it swells in place
     * rather than drifting toward the bottom right.
     */
    private function onBannerFrame(e:Event) : void
    {
        this.bannerHover = this.bannerHover
            + (this.bannerHoverTarget - this.bannerHover) * PLAY_HOVER_EASE;
        var s:Number = BANNER_ART_SCALE * (1 + PLAY_HOVER_GROW * this.bannerHover);
        this.menuBanner.scaleX = s;
        this.menuBanner.scaleY = s;
        this.menuBanner.x = this.bannerCX - (BANNER_W * s) / 2;
        this.menuBanner.y = this.bannerCY - (BANNER_H * s) / 2;
        var lift:Number = PLAY_HOVER_LIGHT * this.bannerHover;
        var ct:ColorTransform = this.bannerBitmap.transform.colorTransform;
        ct.redOffset = lift;
        ct.greenOffset = lift;
        ct.blueOffset = lift;
        this.bannerBitmap.transform.colorTransform = ct;
    }

    private function onMainZone(e:MouseEvent) : void
    {
        this.backButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
    }

    private function onClassesZone(e:MouseEvent) : void
    {
        this.classesButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
    }

    private function onPlayZone(e:MouseEvent) : void
    {
        this.playButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
    }

    public function addListeners():void
    {
        this.playButton.addEventListener(MouseEvent.CLICK, removeListener);
        this.backButton.addEventListener(MouseEvent.CLICK, removeListener);
        this.classesButton.addEventListener(MouseEvent.CLICK, removeListener);
    }

    public function removeListener(e:Event):void
    {
        if (WebMain.STAGE)
            WebMain.STAGE.removeEventListener("resize", positionButtons);
        if (this.menuBanner != null)
            this.menuBanner.removeEventListener(Event.ENTER_FRAME, this.onBannerFrame);
        this.playButton.removeEventListener(MouseEvent.CLICK, removeListener);
        this.backButton.removeEventListener(MouseEvent.CLICK, removeListener);
        this.classesButton.removeEventListener(MouseEvent.CLICK, removeListener);
    }

    private function makeScreenGraphic():Sprite
    {
        var box:Sprite = new Sprite();
        var b:Graphics = box.graphics;
        b.clear();
        b.beginFill(0, 0.5);
        b.drawRect(0, 0, 1, 75);
        b.endFill();
        /* Not added to the stage any more - the banner replaced the bar. */
        return box;
    }

    private var duringResizing:Boolean = false;

    private function positionButtons(e:Event = null) : void
    {
        if (e != null)
        {
            if (!duringResizing)
            {
                duringResizing = true;
                WebMain.STAGE.addEventListener(MouseEvent.MOUSE_OUT, redraw);
            }
            ScreenBase.reSize(e);
            AccountScreen.reSize(e);
        }

        var width:int = WebMain.STAGE.stageWidth;
        this.lines.width = width;
        this.creditDisplay.x = width;

        this.characterList.x = UIUtil.centerXAndOffset(this.characterList);
        if (this.scrollBar)
            this.scrollBar.x = this.characterList.x + this.characterList.width + 5;
        this.nameText.x = UIUtil.centerXAndOffset(this.nameText);
        if (this.namePlate != null)
        {
            /* Centred under the name, which sits at y 24 and is ~32 tall. */
            this.namePlate.x = (width - this.namePlate.width) / 2;
            this.namePlate.y = 58;
        }

        var height:int = WebMain.STAGE.stageHeight;
        if (this.menuBanner != null)
        {
            /* Only the centre moves with the stage; the scale is fixed, so the
               banner stays the same on-screen size in fullscreen. onBannerFrame
               applies scale and position so the hover ease is not fought over. */
            this.bannerCX = width / 2;
            this.bannerCY = height * 0.825;
        }
    }

    public function redraw(e:Event):void
    {
        duringResizing = false;
        if (this.characterList)
        {
            removeChild(this.characterList);
            this.createCharacterList();
        }
        if (this.scrollBar)
        {
            removeChild(this.scrollBar);
            this.createScrollbar();
        }
        WebMain.STAGE.removeEventListener(MouseEvent.MOUSE_OUT, redraw);
    }

    private function createScrollbar() : void
    {
        var scrollSize:int = 399 + (WebMain.STAGE.stageHeight - 600);
        this.scrollBar = new Scrollbar(16, scrollSize);
        this.scrollBar.x = this.characterList.x + this.characterList.width + 5;
        this.scrollBar.y = 113;
        this.scrollBar.setIndicatorSize(scrollSize,this.characterList.height);
        this.scrollBar.addEventListener(Event.CHANGE,this.onScrollBarChange);
        addChild(this.scrollBar);
    }

    private function createCharacterList() : void
    {
        this.characterList = new CharacterList(this.model);
        this.characterList.x = WebMain.STAGE.stageWidth / 2 - this.characterList.width / 2;
        this.characterList.y = 105;
        this.characterListHeight = this.characterList.height;
        addChild(this.characterList);
    }

    private function createSelectCharacterText() : void
    {
        this.selectACharacterText = new SimpleText(18,GOLD,false,0,0);
        this.selectACharacterText.setBold(true);
        this.selectACharacterText.text = "Characters";
        this.selectACharacterText.updateMetrics();
        this.selectACharacterText.filters = [this.DROP_SHADOW];
        this.selectACharacterText.x = 34;
        this.selectACharacterText.y = 74;
        addChild(this.selectACharacterText);
    }

    private function createCreditDisplay() : void
    {
        this.creditDisplay = new CreditDisplay();
        this.creditDisplay.draw(this.model.getCredits(),this.model.getFame());
        this.creditDisplay.y = 32;
        addChild(this.creditDisplay);
    }

    private function createNameText() : void
    {
        this.nameText = new SimpleText(26,GOLD,false,0,0);
        this.nameText.setBold(true);
        this.nameText.text = this.model.getName();
        this.nameText.updateMetrics();
        this.nameText.filters = [this.DROP_SHADOW];
        this.nameText.y = 24;
        addChild(this.nameText);

        this.namePlate = new NamePlateLine();
        this.namePlate.scaleX = 0.5;
        this.namePlate.scaleY = 0.5;
        addChild(this.namePlate);
    }

    private function getReferenceRectangle() : Rectangle
    {
        var rectangle:Rectangle = new Rectangle();
        if(stage)
        {
            rectangle = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
        }
        return rectangle;
    }

    private function createBoundaryLines() : void
    {
        /* The rule under the heading is gone - the painted panels give the
           screen its structure now. The Shape is still created because
           positionButtons sizes it on resize. */
        this.lines = new Shape();
        this.lines.graphics.clear();
    }

    private function onChooseName(event:MouseEvent) : void
    {
        this.chooseName.dispatch();
    }

    private function onScrollBarChange(event:Event) : void
    {
        this.characterList.setPos(-this.scrollBar.pos() * (this.characterListHeight - 400));
    }

    private function removeIfAble(object:DisplayObject) : void
    {
        if(object && contains(object))
        {
            removeChild(object);
        }
    }

    private function onPlayClick(event:Event) : void
    {
        if(this.model.getCharacterCount() == 0)
        {
            this.newCharacter.dispatch();
        }
        else
        {
            this.playGame.dispatch();
        }
    }

    public function setName(name:String) : void
    {
        this.nameText.text = name;
        this.nameText.updateMetrics();
        this.nameText.x = (this.getReferenceRectangle().width - this.nameText.width) * 0.5;
        if(this.nameChooseLink_)
        {
            removeChild(this.nameChooseLink_);
            this.nameChooseLink_ = null;
        }
    }
}
}
