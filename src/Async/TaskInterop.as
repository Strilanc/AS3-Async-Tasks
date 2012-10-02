package Async {
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.SecurityErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.events.IOErrorEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService; 
	import mx.rpc.AbstractOperation;
	import flash.net.URLLoaderDataFormat;
	import flash.media.SoundChannel;

	/// Utility methods for creating tasks
	public class TaskInterop {
		/// Returns a Task<*> that completes immediately, but not synchronously.
		/// This is useful for running something after the current method, and its callers, finish.
		public static function Defer(result : * = null):Task {
			var r:TaskSource = new TaskSource();
			Util.Defer(function():void { r.SetResult(result); } );
			return r;
		}
		/// Returns a Task<*> that completes with the given result after the given delay.
		public static function Delay(delayMilliseconds : Number, result : * = null):Task {
			var r:TaskSource = new TaskSource();
			Util.Delay(delayMilliseconds, function():void { r.SetResult(result); } );
			return r;
		}
		
		/// A task that completes when the given object raises the given event.
		/// The task's result is the event argument.
		/// If a cancel token is given and is cancelled before the event fires, the task cancels.
		public static function ListenForEvent(obj : Object, event : String, ct : CancelToken = null) : Task {
			var r : TaskSource = new TaskSource();
			obj.addEventListener(event, r.TrySetResult);
			r.Await(function():void { obj.removeEventListener(event, r.TrySetResult); } );
			if (ct != null) ct.OnCancelled(r.TrySetCancelled);
			return r;
		}
		/// A task that faults when the given object raises the given event.
		/// The task's fault is the event argument.
		/// If a cancel token is given and is cancelled before the event fires, the task cancels.
		public static function ListenForErrorEvent(obj : Object, event : String, ct : CancelToken = null) : Task {
			var r : TaskSource = new TaskSource();
			obj.addEventListener(event, r.TrySetFault);
			r.Await(function():void { obj.removeEventListener(event, r.TrySetFault); } );
			if (ct != null) ct.OnCancelled(r.TrySetCancelled);
			return r;
		}
		/// A task that completes when the given object raises a given event matching the given condition.
		/// The task's result is the matching event argument.
		/// If a cancel token is given and is cancelled before the event fires, the task cancels.
		public static function ListenForEventWhere(obj : Object, event : String, condition:Function, ct : CancelToken = null) : Task {
			if (condition == null) throw new ArgumentError("condition == null");
			if (condition.length != 1) throw new ArgumentError("condition.length != 1");
			var r : TaskSource = new TaskSource();
			var f:Function = function(e:*):void {
				if (condition(e)) {
					r.TrySetResult(e);
				}
			};
			obj.addEventListener(event, f);
			r.Await(function():void { obj.removeEventListener(event, f); } );
			if (ct != null) ct.OnCancelled(r.TrySetCancelled);
			return r;
		}
		/// A task that completes when the given object raises one of the given success or error events.
		/// The task's result is the event argument.
		/// The task completes if the success event happens first and faults if any of the error events happen first.
		/// If a cancel token is given and is cancelled before any of the events fire, the task cancels.
		public static function ListenForEventOrErrorEvents(obj:Object, successEvent:String, errorEvents:*, ct : CancelToken = null) : Task {
			var cleanupToken : CancelTokenSource = new CancelTokenSource();
			
			var tasks:Vector.<Task> = new Vector.<Task>();
			tasks.push(ListenForEvent(obj, successEvent, cleanupToken));
			for each (var ev : String in errorEvents)
				tasks.push(ListenForErrorEvent(obj, ev, cleanupToken));
				
			var r:Task = TaskEx.AwaitAny(tasks);
			if (ct != null) ct.OnCancelled(cleanupToken.Cancel);
			r.Await(cleanupToken.Cancel);
			return r;
		}
		
		/// Returns a task that completes when the given clip enters the given frame.
		public static function ListenForEnterFrame(clip:MovieClip, frame : int, ct : CancelToken = null):Task {
			return ListenForEventWhere(clip, Event.ENTER_FRAME, function(e:*):Boolean { return clip.currentFrame == frame; }, ct);
		}
		/// Returns a task that completes when the given clip exits the given frame.
		public static function ListenForExitFrame(clip:MovieClip, frame : int, ct : CancelToken = null):Task {
			return ListenForEventWhere(clip, Event.EXIT_FRAME, function(e:*):Boolean { return clip.currentFrame == frame; }, ct);
		}
		/// Returns a task that completes when the given clip enters its ending frame.
		public static function ListenForEnterEndFrame(clip:MovieClip, ct : CancelToken = null):Task {
			return ListenForEnterFrame(clip, clip.totalFrames, ct);
		}
		/// Returns a task that completes when the given clip exits its ending frame.
		public static function ListenForExitEndFrame(clip:MovieClip, ct : CancelToken = null):Task {
			return ListenForExitFrame(clip, clip.totalFrames, ct);
		}
		
		/// Returns a Task<Loader> for a loader containing content pointed to by a URL.
		/// The task completes when the content has been loaded.
		public static function Load(url:String, ct : CancelToken = null):Task {
			var loader: Loader = new Loader();
			var r:Task = ListenForEventOrErrorEvents(loader.contentLoaderInfo, Event.COMPLETE, new Array(IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR), ct);
			loader.load(new URLRequest(url));
			if (ct != null) { ct.OnCancelled(loader.close); }
			return r.ContinueWith(function():Loader { return loader; } );
		}
		/// Returns a Task<Loader> for a loader containing content serialized by a byte array.
		/// The task completes when the content has been loaded.
		public static function LoadFromBytes(data:ByteArray, ct : CancelToken = null):Task {
			var loader: Loader = new Loader();
			var r:Task = ListenForEventOrErrorEvents(loader.contentLoaderInfo, Event.COMPLETE, new Array(IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR), ct);
			loader.loadBytes(data);
			if (ct != null) { ct.OnCancelled(loader.close); }
			return r.ContinueWith(function():Loader { return loader; } );
		}
		/// Returns a Task<String> containing the text pointed to by a URL.
		/// The task completes when the content has been loaded.
		public static function LoadText(url:String, ct : CancelToken = null):Task {
			var loader: URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var r:Task = ListenForEventOrErrorEvents(loader, Event.COMPLETE, new Array(IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR), ct);
			loader.load(new URLRequest(url));
			if (ct != null) { ct.OnCancelled(loader.close); }
			return r.ContinueWith(function():String { return loader.data; });
		}
		
		/// Asynchronously connects to a web service, returning a Task<WebService>.
		public static function ConnectToSOAPWebService(url:String):Task {
			var r:TaskSource = new TaskSource();
			var ws:WebService = new WebService();
			var fs:Function;
			var fe:Function;
			var cleanup:Function = function():void {
				ws.removeEventListener(LoadEvent.LOAD, fs);
				ws.removeEventListener(FaultEvent.FAULT, fe);				
			};
			fs = function(event:LoadEvent):void {
				cleanup();
				r.SetResult(ws);
			};
			fe = function(fault:FaultEvent):void {
				cleanup();
				r.SetFault(fault);
			};
			ws.addEventListener(LoadEvent.LOAD, fs);
			ws.addEventListener(FaultEvent.FAULT, fe);
			ws.loadWSDL(url);
			return r;
		}
		/// Asynchronously invokes a web service's method, returning a Task<*> containing the eventual result.
		public static function InvokeWebServiceMethod(ws:WebService, name:String, ... args):Task {
			var r:TaskSource = new TaskSource();
			var op:AbstractOperation = ws.getOperation(name);
			op.arguments = args;
			op.addEventListener(mx.rpc.events.FaultEvent.FAULT, function(e:Object):void { r.TrySetFault(e.fault); } );
			op.addEventListener(mx.rpc.events.ResultEvent.RESULT, function(e:Object):void { r.TrySetResult(e.result); } );
			op.send();
			return r;
		}
		
		/// Starts playing the given sound, returning a Task<void> for when it completes.
		/// Playback can be stopped by canceling the given cancel token.
		public static function PlaySound(sound : Sound, ct : CancelToken = null) : Task {
			var channel:SoundChannel = sound.play();
			var r:Task = ListenForEvent(channel, Event.SOUND_COMPLETE, ct);
			if (ct != null) { ct.OnCancelled(channel.stop); }
			return r;
		}
		
		/// Starts loading a sound from the given url, returning a Task<Sound> for when it completes or fails.
		/// Loading can be stopped by canceling the given cancel token.
		public static function LoadSound(url : String, ct : CancelToken = null) : Task {
			var sound:Sound = new Sound();
			var r:Task = ListenForEventOrErrorEvents(sound, Event.COMPLETE, new Array(IOErrorEvent.IO_ERROR), ct).ContinueWith(function():Sound {
				return sound;
			});
			sound.load(new URLRequest(url));
			if (ct != null) { ct.OnCancelled(sound.close); }
			return r;
		}
	}
}
