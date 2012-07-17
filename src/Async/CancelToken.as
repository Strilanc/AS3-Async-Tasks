package Async {
	import flash.errors.IllegalOperationError;
	public interface CancelToken {
		/// Provides a callback to run when the token has been cancelled.
		/// If the token is already canceled then the callback may be run defered or run synchronously
		function OnCancelled(callback : Function) : void;
		
		/// Determines if the token has already been cancelled
		function IsCancelled() : Boolean;
	}
}
