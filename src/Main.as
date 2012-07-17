package {
	import Async.TaskEx;
	import Async.TaskInterop;
	import flash.display.Sprite;
	import flash.events.Event;
	import Async.Task;
	import flash.media.Sound;
	
	public class Main extends Sprite {
		public function Main() {			
			AllTests.RunShowAsync(stage).ContinueWith(init);
		}
		private function init():void {
			trace("done");
		}
		private function ExampleLoadPlaySoundsAsync(paths : Vector.<String>) : Task {
			// start loading sounds
			var loadedSoundsAsync:Task = TaskEx.StartMany(paths, TaskInterop.LoadSound);
			
			// when the sounds are loaded, start playing them
			var allSoundsPlayedAsync:Task = loadedSoundsAsync.Bind(function(sounds:Array):Task {
				var x:* = loadedSoundsAsync;
				// loop over the sounds, playing them one by one
				var i:int = -1;
				return TaskEx.DoWhile(function():Task {
					// check for end of loop
					i += 1;
					if (i >= sounds.length) return TaskEx.Wrap(false);
					
					// play the current sound then continue the loop
					var sound:Sound = sounds[i];
					var playSoundAsync:Task = TaskInterop.PlaySound(sound);
					var trueAfterPlayedSoundAsync:Task = playSoundAsync.ContinueWith(function():Boolean { 
						return true; 
					});
					return trueAfterPlayedSoundAsync;
				});
			});
			
			return allSoundsPlayedAsync;
		}
	}
}
