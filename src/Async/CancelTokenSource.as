package Async {
	/// A cancel token with manually controlled cancellation.
	public class CancelTokenSource implements CancelToken {
		private var _cancelled:Boolean = false;
		private var _callbacks:Vector.<Function> = new Vector.<Function>();
		
		public function CancelTokenSource() {}
		public function IsCancelled() : Boolean {
			return _cancelled;
		}
		
		/// Cancels the token.
		public function Cancel():void {
			if (_cancelled) return;
			_cancelled = true;
			for each (var c:Function in _callbacks) {
				Util.Defer(c);
			}
			_callbacks = null;
		}
		public function OnCancelled(callback : Function):void {
			if (callback == null) throw new ArgumentError("callback == null");
			if (callback.length != 0) throw new ArgumentError("callback.length != 0");
			if (_cancelled) {
				Util.Defer(callback);
			} else {
				_callbacks.push(callback);
			}
		}

		public function toString():String {
			return _cancelled ? "Cancelled" : "Not Cancelled";
		}
	}
}
