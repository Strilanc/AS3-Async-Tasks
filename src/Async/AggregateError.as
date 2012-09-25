package Async {
	/// An error that is actually multiple errors
	public class AggregateError extends Error {
		public var Causes:Array;
		public function AggregateError(causes:Array) {
			super("AggregateError: " + Summarize(causes));
			this.Causes = causes;
		}
		public function Collapse() : Object {
			if (Causes.length != 1) return this;
			if (Causes[0] is AggregateError) return (Causes[0] as AggregateError).Collapse();
			return Causes[0];
		}
		private static function Summarize(causes:Array, sep:String = ", ") : String {
			var r:String = "";
			for each (var e:* in causes) {
				if (r.length > 0) r += sep;
				r += e + "";
			}
			return r;
		}
		public function toString(): String {
			return "AggregateError:\r\n" + Summarize(Causes, "\r\n");
		}
		public function getStackTraces() : String {
			var r:String = super.getStackTrace() + "\r\n";
			for each (var e:* in Causes) {
				r += "\r\n---\r\n";
				r += e is Error ? (e as Error).getStackTrace() : "(none)";
			}
			return r;			
		}
	}
}