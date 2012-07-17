package Async {
	import flash.errors.IllegalOperationError;
	/// A Task with manually controlled completion.
	/// For example, a method can create a TaskSource, returning it to the caller, and manually set its result when possible.
	public class TaskSource implements Task {
		/// When set to true exceptions will bubble out of the call stack instead of being propagated into the task source.
		/// Makes it easier to debug exceptions by stopping the debugger at the right time.
		private static const DEBUG_EVAL_WITHOUT_TRYCATCH:Boolean = false;
		
		// When set to true, task sources store a stack trace when they are constructed, to help identify where they came from.
		private static const DEBUGGING_STORE_CREATION_STACK_TRACE:Boolean = false;
		private var DEBUG_CREATION_STACK_TRACE : String;

		/// A count of TaskSource instances that have been created but not yet set.
		/// A TaskSource instance should not be created if it won't be eventually set.
		/// This value can be useful for determining if a bug is due to a task source not being set vs being set incorrectly.
		private static var DEBUG_UNSET_COUNT : int = 0;
		
		/// When set to true, task sources will output faults that appear to have not been handled
		private static const DEBUG_TRACE_PROBABLE_UNHANDLED_FAULTS:Boolean = true;

		private var _result:*;
		private var _state:int = 0;
		private var _callbacks:Vector.<Function> = new Vector.<Function>();
		private var _hasBeenAwaited:Boolean = false;
		
		/// Constructs a new task source.
		public function TaskSource() {
			DEBUG_UNSET_COUNT += 1;
			if (DEBUGGING_STORE_CREATION_STACK_TRACE)
				this.DEBUG_CREATION_STACK_TRACE = new Error().getStackTrace();
		}
		public function IsCompleted() : Boolean {
			return _state == 1;
		}
		public function IsFaulted() : Boolean {
			return _state == -1;
		}
		public function IsCancelled() : Boolean {
			return IsFaulted() && _result is TaskCancelledError;
		}
		public function IsRunning() : Boolean {
			return _state == 0;
		}
		
		public function Result() : * {
			if (this.IsFaulted())
				throw new IllegalOperationError("Task's result can't be accessed because the task faulted. The fault: " + _result);
			if (!this.IsCompleted())
				throw new IllegalOperationError("Task's result can't be accessed because the task is still running.");
			return _result;
		}
		public function Fault() : * {
			if (this.IsCompleted())
				throw new IllegalOperationError("Task's fault can't be accessed because the task completed successfully. The result: " + _result);
			if (!this.IsFaulted())
				throw new IllegalOperationError("Task's fault can't be accessed because the task is still running.");
			return _result;
		}
		
		public function TrySetResult(result : *):Boolean {
			if (!this.IsRunning()) return false;
			_state = 1;
			_result = result;
			RunAndClearCallbacks();
			return true;
		}
		public function TrySetFault(fault : *):Boolean {
			if (!this.IsRunning()) return false;
			_state = -1;
			_result = fault;
			if (DEBUG_TRACE_PROBABLE_UNHANDLED_FAULTS && !_hasBeenAwaited) {
				Util.Defer(function():void { 
					if (!_hasBeenAwaited) {
						trace("Task fault may not have been handled: " + fault);
					}
				});
			}
			RunAndClearCallbacks();
			return true;
		}
		public function TrySetCancelled():Boolean {
			return TrySetFault(new TaskCancelledError());
		}
		private function RunAndClearCallbacks():void {
			DEBUG_UNSET_COUNT -= 1;
			
			for each (var c:Function in _callbacks) {
				c();
			}
			_callbacks = null;
		}
		
		public function SetCancelled():void {
			if (!TrySetCancelled())
				throw new IllegalOperationError("Task is already set.");
		}
		public function SetResult(result : Object):void {
			if (!TrySetResult(result)) 
				throw new IllegalOperationError("Task is already set.");
		}
		public function SetFault(fault : Object):void {
			if (!TrySetFault(fault)) 
				throw new IllegalOperationError("Task is already set.");
		}
		
		/// Evaluates a function, propagating the result or exception into the TaskSource
		private function SetByEval(f:Function):void {
			if (DEBUG_EVAL_WITHOUT_TRYCATCH) {
				SetResult(f());
				return;
			}
			
			try {
				SetResult(f());
			} catch (error:*) {
				SetFault(error);
			}
		}
		/// Copies a task's result or fault into this task source.
		public function SetFromTask(task:Task, assertTaskCompleted:Boolean = false):void {
			if (task.IsCompleted()) {
				SetResult(task.Result());
			} else if (task.IsFaulted()) {
				SetFault(task.Fault());
			} else if (assertTaskCompleted) {
				throw new IllegalOperationError("Task expected to be completed or faulted.");
			} else {
				task.Await(function():void { SetFromTask(task, true); } );
			}
		}

		public function Await(callback : Function):Task {
			if (callback == null) throw new ArgumentError("callback == null");
			if (callback.length != 0) throw new ArgumentError("callback.length != 0");
			_hasBeenAwaited = true;
			var r:TaskSource = new TaskSource();
			var fullCallback:Function = function():void { r.SetByEval(callback); }
			if (IsRunning()) {
				_callbacks.push(fullCallback);
			} else {
				fullCallback();
			}
			return r;
		}
		public function ContinueWith(callback : Function):Task {
			if (callback == null) throw new ArgumentError("callback == null");
			if (callback.length > 1) throw new ArgumentError("callback.length > 1");
				
			var r:TaskSource = new TaskSource();
			Await(function():void {
				if (IsFaulted()) {
					r.SetFault(Fault());
				} else {
					r.SetByEval(function():Object { 
						return callback.length == 0
							   ? callback()
							   : callback(Result());
					});
				}
			});
			return r;
		}
		public function CatchWith(callback : Function):Task {
			if (callback == null) throw new ArgumentError("callback == null");
			if (callback.length > 1) throw new ArgumentError("callback.length > 1");
			
			return Await(function():Object { 
				if (!IsFaulted()) return null;
				return callback.length == 0
					   ? callback()
					   : callback(Fault());
			} );
		}
		
		public function Unwrap():Task {
			var r:TaskSource = new TaskSource();
			Await(function():void { 
				if (IsFaulted()) {
					r.SetFault(Fault());
				} else {
					var t:Task = Result() as Task;
					if (t == null) throw new ArgumentError("Attempted to unwrap a task that did not wrap a task.");
					r.SetFromTask(t);
				}
			});
			return r;
		}
		public function Bind(callback : Function):Task {
			return ContinueWith(callback).Unwrap();
		}

		public function toString():String {
			if (IsFaulted()) return "Faulted Task: " + _result;
			if (IsCompleted()) return "Completed Task: " + _result;
			return "Incomplete Task";
		}
	}
}
