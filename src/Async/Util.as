package Async {
	import Async.TaskSource;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import Async.Task;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.display.*;
    import flash.events.*;
    import flash.net.*;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
	
	internal class Util {
		public static function AddOneTimeEventHandlerTo(obj : Object, event : String, callback : Function) : void {
			var f : Function = function(arg : Object) : void {
				obj.removeEventListener(event, f);
				callback(arg);
			};
			obj.addEventListener(event, f);
		}
		/// Runs the given function after the current execution stack has completed.
		public static function Defer(callback : Function):void {
			Delay(0, callback);
		}
		/// Runs the given function after a given delay.
		public static function Delay(delayMilliseconds : Number, callback : Function):void {
			var t:Timer = new Timer(delayMilliseconds, 1);
			t.start();
			Util.AddOneTimeEventHandlerTo(t, TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void { callback(); });
		}
	}
}
