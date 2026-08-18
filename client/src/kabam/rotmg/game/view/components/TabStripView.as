package kabam.rotmg.game.view.components
{
import com.company.assembleegameclient.game.GameSprite;
import com.company.util.GraphicsUtil;
   import flash.display.Bitmap;
   import flash.display.Graphics;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import org.osflash.signals.Signal;
   
   public class TabStripView extends Sprite
   {
      public static const TAB_WIDTH:Number = 29;
      public static const TAB_HEIGHT:Number = 35;
      public static const TAB_CORNER_RADIUS:int = 9;
      public static const CONTENT_CORNER_RADIUS:int = 25;
      public static const TAB_TOP_OFFSET:int = 27;
      public static const TAB_X_PADDING:Number = 9;
      public static const TAB_Y_PADDING:Number = 8;
      public static const BACKGROUND_COLOR:uint = 2368034;
      /** Brown plate behind non-inventory tab content. */
      public static const CONTENT_PANEL_COLOR:uint = 0x4A3421;
      public static const TAB_COLOR:uint = 7039594;

      public var gs_:GameSprite;

      public var tabs:Vector.<TabView>;
      private var contents:Vector.<Sprite>;
      private var tabSprite:Sprite;
      private var bgSprite:Sprite;
      private var containerSprite:Sprite;
      public var w:Number;
      public var h:Number;
      public var currentTabIndex:int;
      public const tabSelected:Signal = new Signal(String);

      public function TabStripView(w:Number, h:Number, gs:GameSprite)
      {
         super();
         this.w = w;
         this.h = h;
         this.gs_ = gs;

         this.tabs = new Vector.<TabView>();
         this.contents = new Vector.<Sprite>();
         this.tabSprite = new Sprite();
         /* Line the tabs up with the recesses carved into the pane art. */
         this.tabSprite.x = 5;
         this.tabSprite.addEventListener(MouseEvent.CLICK,this.onTabSelected);
         addChild(this.tabSprite);
         this.containerSprite = new Sprite();
         this.containerSprite.y = TAB_TOP_OFFSET;
         addChild(this.containerSprite);
         this.drawBackground();
      }
      
      private function onTabSelected(e:MouseEvent) : void
      {
         var current:TabView = null;
         var tab:TabView = e.target.parent as TabView;
         if(tab)
         {
            current = this.tabs[this.currentTabIndex];
            if(current.index != tab.index)
            {
               current.setSelected(false);
               tab.setSelected(true);
               this.showContent(tab.index);
               this.tabSelected.dispatch(this.contents[tab.index].name);
            }
         }
      }

      public function setSelectedTab(index:uint):void {
         this.selectTab(this.tabs[index]);
      }

      private function selectTab(view:TabView):void {
         var tabFromIndex:TabView;
         if (view) {
            tabFromIndex = this.tabs[this.currentTabIndex];
            if (tabFromIndex.index != view.index) {
               tabFromIndex.setSelected(false);
               view.setSelected(true);
               this.showContent(view.index);
               this.tabSelected.dispatch(this.contents[view.index].name);
            }
         }
      }
      
      public function drawBackground() : void
      {
         this.bgSprite = new Sprite();
         var g:Graphics = this.bgSprite.graphics;
         g.clear();
         /* Solid brown plate for tabs that draw their own content (stats,
            admin). The inventory tab hides it so the recesses painted into the
            pane art show through - see updateContentBackground(). */
         var contentFill:GraphicsSolidFill = new GraphicsSolidFill(CONTENT_PANEL_COLOR,1);
         var contentPath:GraphicsPath = new GraphicsPath(new Vector.<int>(),new Vector.<Number>());
         var contentGraphicsData:Vector.<IGraphicsData> = new <IGraphicsData>[contentFill,contentPath,GraphicsUtil.END_FILL];
         GraphicsUtil.drawCutEdgeRect(0,0,this.w,this.h - TAB_TOP_OFFSET,6,[1,1,1,1],contentPath);
         g.drawGraphicsData(contentGraphicsData);
         this.bgSprite.visible = false;
         this.containerSprite.addChild(this.bgSprite);
      }
      
      public function addTab(icon:Bitmap, content:Sprite) : void
      {
         var tabBG:Sprite = new Sprite();
         tabBG.name = "tabBG";
         var g:Graphics = tabBG.graphics;
         /* Alpha 0: the pane art carves the tab recesses. The fill is kept so
            the tab still has a hit area, and TabView tints it on selection. */
         g.beginFill(TAB_COLOR,0);
         g.drawRoundRect(0,0,TAB_WIDTH,TAB_HEIGHT,TAB_CORNER_RADIUS,TAB_CORNER_RADIUS);
         g.endFill();
         var index:int = this.tabs.length;
         var tabView:TabView = new TabView(index,tabBG,icon);
         tabView.x = index * (TAB_WIDTH + TAB_X_PADDING);
         tabView.y = TAB_Y_PADDING;
         this.tabs.push(tabView);
         this.contents.push(content);
         this.tabSprite.addChild(tabView);
         this.containerSprite.addChild(content);
         if(index > 0)
         {
            content.visible = false;
         }
         else
         {
            tabView.setSelected(true);
            this.showContent(0);
            this.tabSelected.dispatch(content.name);
         }
      }
      
      private function showContent(index:int) : void
      {
         var previousContent:Sprite = null;
         var currentContent:Sprite = null;
         if(index != this.currentTabIndex)
         {
            previousContent = this.contents[this.currentTabIndex];
            previousContent.visible = false;
            currentContent = this.contents[index];
            currentContent.visible = true;
            this.currentTabIndex = index;
            this.updateContentBackground();
         }
      }

      /**
       * Tab 0 is the inventory, which sits on recesses painted into the pane
       * art - it must stay transparent. Every other tab draws its own content
       * and would otherwise appear to float over those recesses.
       */
      private function updateContentBackground() : void
      {
         if(this.bgSprite)
         {
            this.bgSprite.visible = this.currentTabIndex != 0;
         }
      }
   }
}
