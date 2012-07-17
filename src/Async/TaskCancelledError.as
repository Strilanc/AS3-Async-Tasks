package Async {
	public class TaskCancelledError extends Error {
		public function TaskCancelledError() {
			super("Task Cancelled");
		}
	}
}
