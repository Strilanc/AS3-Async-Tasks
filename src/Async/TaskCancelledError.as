package Async {
	/// An error indicating a task has no result because it was cancelled.
	public class TaskCancelledError extends Error {
		public function TaskCancelledError() {
			super("Task Cancelled");
		}
	}
}
