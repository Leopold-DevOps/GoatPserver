package kabam.rotmg.application.impl
{
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.parameters.Parameters;
   import kabam.rotmg.application.api.ApplicationSetup;

   public class ReleaseSetup implements ApplicationSetup
   {
      private const HTTP:String = "http://";
      private const HTTPS:String = "https://"

      private const RELEASE_PORT:String = ":8080";
      private const TESTING_PORT:String = ":8089";

      /* The host comes from the URL the swf was loaded from rather than being
         hardcoded, so one build works against a local server and a remote one
         over the VPN. See AppEngineHost. */
      private function get CDN_APPENGINE():String {
         return HTTP + AppEngineHost.get() + RELEASE_PORT;
      }

      private function get CDN_APPENGINE_S():String {
         return HTTPS + AppEngineHost.get() + TESTING_PORT;
      }

      private function get TESTING_CDN_APPENGINE():String {
         return HTTP + AppEngineHost.get() + TESTING_PORT;
      }

      private const BUILD_LABEL:String = "<font color=\"#4254d6\">release:</font> " + Parameters.GAME_VERSION;
      private const TESTING_BUILD_LABEL:String = "<font color=\"#4254d6\">testing.</font>";

      public function getAppEngineUrl() : String
      {
         return Parameters.TESTING_SERVER ? TESTING_CDN_APPENGINE : CDN_APPENGINE;
      }

      public function getAppEngineUrlEncrypted() : String
      {
         return Parameters.TESTING_SERVER ? TESTING_CDN_APPENGINE : CDN_APPENGINE_S;
      }

      public function getBuildLabel() : String
      {
         return (Parameters.TESTING_SERVER ? TESTING_BUILD_LABEL : BUILD_LABEL);
      }

      public function useProductionDialogs() : Boolean
      {
         return true;
      }

      public function areErrorsReported() : Boolean
      {
         return false;
      }

      public function isDebug():Boolean {
         return false;
      }
   }
}
