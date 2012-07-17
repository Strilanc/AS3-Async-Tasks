package Async {
	import flash.errors.IllegalOperationError;
	public interface Task {
		/// Determines if the task has completed successfully.
		function IsCompleted() : Boolean;
		/// Determines if the task has 'completed' due to an error.
		function IsFaulted() : Boolean;
		/// Determines if the task has faulted due to cancellation.
		function IsCancelled() : Boolean;
		/// Determines if the task has not yet completed or faulted.
		function IsRunning() : Boolean;
		
		/// Returns the task's result. Fails if the task has not completed successfully.
		function Result() : *;
		/// Returns the task's fault. Fails if the task has not faulted.
		function Fault() : *;
		
		/// Runs a callback after the given task completes or faults, returning the callback's eventual result as a task.
		/// The callback must take 0 arguments.
		/// If the given task has already completed then the callback may be run synchronously.
		function Await(callback : Function) : Task;
		
		/// Runs a callback using the result of the given task, returning the callback's eventual result as a task.
		/// The callback must take 0 arguments or 1 argument for the task's result.
		/// If the given task faults then the fault is propagated into the resulting task, and the callback is not run.
		/// If the given task has already completed then the callback may be run synchronously.
		function ContinueWith(callback : Function) : Task;
		
		/// Returns a Task<T> with result equivalent to the eventual Task<T> resulting from this Task<Task<T>>.
		/// Intuitively, it transforms this Task<Task<T>> into a Task<T> in the reasonable way.
		/// If either this Task<Task<T>> or its resulting Task<T> fault, the returned Task<T> will also fault.
		function Unwrap() : Task;
		
		/// Runs a callback using the unwrapped result of the given task, returning the callback's eventual result as a task.
		/// Equivalent to ContinueWith(callback).Unwrap()
		function Bind(callback : Function) : Task;
		
		/// Runs a callback based on the failure of the given task, returning the callback's eventual result as a task.
		/// The callback must take 0 arguments or 1 argument for the task's fault.
		/// If the given task does not fault, the resulting task will contain a null result.
		/// If the given task has already completed then the callback may be run synchronously.
		function CatchWith(callback : Function) : Task;
	}
}
