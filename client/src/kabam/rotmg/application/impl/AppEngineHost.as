package kabam.rotmg.application.impl {

/**
 * Where the account server lives, derived from the URL the client itself was
 * loaded from.
 *
 * ReleaseSetup used to hardcode 127.0.0.1, which meant a client built for a
 * local server could not talk to a remote one without editing the source and
 * recompiling. Since the account server is what serves client.swf in the first
 * place, the host it was fetched from is the account server by definition -
 * so loading the swf from http://10.0.0.1:8080/client.swf points the client at
 * that box automatically, and a locally served swf still resolves to
 * 127.0.0.1.
 *
 * Only the host is taken. The port stays whatever ReleaseSetup asks for, so
 * the release/testing port split still works.
 */
public class AppEngineHost {

    private static const DEFAULT_HOST:String = "127.0.0.1";

    private static var host:String = DEFAULT_HOST;

    /**
     * Called once at startup with loaderInfo.url. Anything that is not an
     * http(s) URL - a swf opened straight off disk, say - leaves the default
     * in place rather than producing a nonsense host.
     */
    public static function initFromSwfUrl(url:String):void {
        if (url == null)
            return;

        var scheme:int = url.indexOf("://");
        if (scheme == -1)
            return;

        var protocol:String = url.substring(0, scheme).toLowerCase();
        if (protocol != "http" && protocol != "https")
            return;

        var rest:String = url.substring(scheme + 3);

        // strip path, query and fragment, then the port
        var cut:int = rest.length;
        var marks:Array = [rest.indexOf("/"), rest.indexOf("?"), rest.indexOf("#")];
        for (var i:int = 0; i < marks.length; i++)
            if (marks[i] != -1 && marks[i] < cut)
                cut = marks[i];

        var authority:String = rest.substring(0, cut);

        // drop any credentials, then the port
        var at:int = authority.lastIndexOf("@");
        if (at != -1)
            authority = authority.substring(at + 1);

        if (authority.charAt(0) == "[") {
            // IPv6 literal: the colons inside the brackets are part of the
            // address, so only a colon after the closing bracket is a port
            var close:int = authority.indexOf("]");
            if (close != -1)
                authority = authority.substring(0, close + 1);
        }
        else {
            var colon:int = authority.lastIndexOf(":");
            if (colon != -1)
                authority = authority.substring(0, colon);
        }

        if (authority.length > 0)
            host = authority;
    }

    public static function get():String {
        return host;
    }
}
}
