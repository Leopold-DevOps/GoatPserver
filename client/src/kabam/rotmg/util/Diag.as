package kabam.rotmg.util {

/**
 * Breadcrumb trail for locating uncaught errors.
 *
 * A release Flash Player returns null from Error.getStackTrace() no matter how
 * the SWF was compiled, so an uncaught #1009 arrives with no location at all.
 * Recording the last step reached gives the error report something to point at.
 */
public class Diag {

    public static var step:String = "(nothing recorded)";

    public static function at(where:String):void {
        step = where;
    }
}
}
