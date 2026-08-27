package {
import com.company.assembleegameclient.map.Camera;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.util.AssetLoader;
import com.company.assembleegameclient.util.StageProxy;
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.events.UncaughtErrorEvent;
import flash.text.TextField;
import kabam.rotmg.util.Diag;
import flash.display.StageScaleMode;
import flash.events.Event;
import kabam.lib.net.NetConfig;
import kabam.rotmg.account.AccountConfig;
import kabam.rotmg.appengine.AppEngineConfig;
import kabam.rotmg.application.impl.AppEngineHost;
import kabam.rotmg.application.ApplicationConfig;
import kabam.rotmg.assets.AssetsConfig;
import kabam.rotmg.characters.CharactersConfig;
import kabam.rotmg.classes.ClassesConfig;
import kabam.rotmg.core.CoreConfig;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.death.DeathConfig;
import kabam.rotmg.dialogs.DialogsConfig;
import kabam.rotmg.errors.ErrorConfig;
import kabam.rotmg.fame.FameConfig;
import kabam.rotmg.game.GameConfig;
import kabam.rotmg.hud.HUDConfig;
import kabam.rotmg.language.LanguageConfig;
import kabam.rotmg.legends.LegendsConfig;
import kabam.rotmg.maploading.MapLoadingConfig;
import kabam.rotmg.minimap.MiniMapConfig;
import kabam.rotmg.news.NewsConfig;
import kabam.rotmg.servers.ServersConfig;
import kabam.rotmg.stage3D.Renderer;
import kabam.rotmg.stage3D.Stage3DConfig;
import kabam.rotmg.startup.StartupConfig;
import kabam.rotmg.startup.control.StartupSignal;
import kabam.rotmg.tooltips.TooltipsConfig;
import kabam.rotmg.ui.UIConfig;
import robotlegs.bender.bundles.mvcs.MVCSBundle;
import robotlegs.bender.extensions.signalCommandMap.SignalCommandMapExtension;
import robotlegs.bender.framework.api.IContext;
import robotlegs.bender.framework.api.LogLevel;

[SWF(frameRate="60", backgroundColor="#000000", width="800", height="600")]
public class WebMain extends Sprite {

    public static var sWidth:Number = 800;
    public static var sHeight:Number = 600;

    public static var STAGE:Stage;

    public function WebMain() {
        if (stage) {
            stage.addEventListener("resize", this.onStageResize, false, 0, true);
            this.setup();
        }
        else {
            addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        }
    }

    protected var context:IContext;

    private function setup():void {
        // must run before anything asks ReleaseSetup for the account server URL
        AppEngineHost.initFromSwfUrl(loaderInfo != null ? loaderInfo.url : null);
        this.hackParameters();
        this.installErrorReporter();
        this.createContext();
        new AssetLoader().load();
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        var startup:StartupSignal = this.context.injector.getInstance(StartupSignal);
        startup.dispatch();
        STAGE = stage;
        //stage.vsyncEnabled = false;
    }

    /**
     * Draws uncaught exceptions on screen.
     *
     * A release Flash Player swallows them silently, which is why a failure
     * during map load shows up as nothing but a black screen. Without the
     * debugger player there is no flashlog.txt to read either, so the client
     * has to report its own errors.
     */
    private function installErrorReporter():void {
        if (loaderInfo == null || loaderInfo.uncaughtErrorEvents == null)
            return;

        loaderInfo.uncaughtErrorEvents.addEventListener(
                UncaughtErrorEvent.UNCAUGHT_ERROR, this.onUncaughtError);
    }

    private function onUncaughtError(event:UncaughtErrorEvent):void {
        var message:String;
        if (event.error is Error) {
            var error:Error = event.error as Error;
            var trace:String = error.getStackTrace();
            // a release player returns null here regardless of how the SWF was
            // compiled, which is what the Diag breadcrumb is for
            message = error.name + ": " + error.message
                    + "\n\nlast step: " + Diag.step
                    + "\n\n" + (trace == null ? "(no stack trace in release player)" : trace);
        } else {
            message = String(event.error) + "\n\nlast step: " + Diag.step;
        }

        if (errorReport == null) {
            errorReport = new TextField();
            errorReport.width = 900;
            errorReport.height = 560;
            errorReport.multiline = true;
            errorReport.wordWrap = true;
            errorReport.selectable = true;
            errorReport.background = true;
            errorReport.backgroundColor = 0x330000;
            errorReport.textColor = 0xFFCCCC;
            errorReport.mouseEnabled = true;
        }

        // Keep several: the first error is often an unrelated screen glitch,
        // while the one that matters (eg. the failure during map load) comes
        // later. Each carries the breadcrumb from when it was thrown.
        if (errorCount < 6) {
            errorCount++;
            errorReport.appendText((errorReport.text.length == 0 ? "" : "\n------\n")
                    + "#" + errorCount + "  " + message);
        }

        if (stage != null && errorReport.parent == null)
            stage.addChild(errorReport);
    }

    private static var errorReport:TextField;
    private static var errorCount:int = 0;

    private function hackParameters():void {
        Parameters.root = stage.root;
    }

    private function createContext():void {
        var stageProxy:StageProxy = new StageProxy(this);
        this.context = new StaticInjectorContext();
        this.context.injector.map(LoaderInfo).toValue(root.stage.root.loaderInfo);
        this.context.injector.map(StageProxy).toValue(stageProxy);
        this.context
                .extend(MVCSBundle)
                .extend(SignalCommandMapExtension)
                .configure(StartupConfig)
                .configure(NetConfig)
                .configure(AssetsConfig)
                .configure(DialogsConfig)
                .configure(ApplicationConfig)
                .configure(AppEngineConfig)
                .configure(AccountConfig)
                .configure(ErrorConfig)
                .configure(CoreConfig)
                .configure(DeathConfig)
                .configure(CharactersConfig)
                .configure(ServersConfig)
                .configure(GameConfig)
                //.configure(ConsoleConfig)
                .configure(UIConfig)
                .configure(MiniMapConfig)
                .configure(LanguageConfig)
                .configure(LegendsConfig)
                .configure(NewsConfig)
                .configure(FameConfig)
                .configure(TooltipsConfig)
                .configure(MapLoadingConfig)
                .configure(ClassesConfig)
                .configure(Stage3DConfig)
                .configure(HUDConfig)
                .configure(this);
        this.context.logLevel = LogLevel.DEBUG;
    }

    public function onStageResize(_arg_1:Event):void {
        if (Renderer.inGame) {
            this.scaleX = (stage.stageWidth / 800);
            this.scaleY = (stage.stageHeight / 600);
            this.x = ((800 - stage.stageWidth) / 2);
            this.y = ((600 - stage.stageHeight) / 2);
        }
        else {
            this.scaleX = 1;
            this.scaleY = 1;
            this.x = 0;
            this.y = 0;
        }
        sWidth = stage.stageWidth;
        sHeight = stage.stageHeight;
        Camera.adjustDimensions();
        Stage3DConfig.Dimensions();
    }

    private function onAddedToStage(event:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        this.setup();
    }
}
}
