package Async {
	/// A cancel token that will never be cancelled.
	/// Callbacks passed to OnCancelled will never be run.
	public class NeverCancelToken implements CancelToken {
		public function NeverCancelToken() { }
		public function IsCancelled() : Boolean { return false; }
		public function OnCancelled(callback : Function):void { }
		public function toString():String { return "Never Cancelled"; }
	}
}
