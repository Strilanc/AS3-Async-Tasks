package {
	import flash.display.Sprite;
	import flash.events.Event;
	import Async.Task;
	
	public class Main extends Sprite {
		public function Main() {			
			AllTests.RunShowAsync(stage).ContinueWith(init);
		}
		private function init():void {
			trace("done");
		}
	}
}
