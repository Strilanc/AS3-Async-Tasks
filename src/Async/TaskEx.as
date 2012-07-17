package Async {
	import flash.errors.IllegalOperationError;
	
	/// Utility methods for working with tasks
	public class TaskEx {
		/// Returns a completed task whose result is the given value.
		/// The 'deferred' argument determine if the task is returned completed or defers completion.
		public static function Wrap(value : Object, deferred : Boolean = false) : Task {
			var r:TaskSource = new TaskSource();
			if (deferred) {
				Util.Defer(function():void { r.SetResult(value); });
			} else {
				r.SetResult(value)
			}
			return r;
		}
		/// Returns a faulted task whose error is the given value.
		/// The 'deferred' argument determine if the task is returned faulted or defers faulting.
		public static function WrapFault(error : Object, deferred : Boolean = true) : Task {
			var r:TaskSource = new TaskSource();
			if (deferred) {
				Util.Defer(function():void { r.SetFault(error); });
			} else {
				r.SetFault(error)
			}
			return r;
		}
		
		/// Starts tasks based on items from a sequence, returning a task containing the array of results of the started tasks.
		public static function StartMany(inputs:*, taskStarter:Function):Task {
			var tasks:Array = new Array();
			for each (var e:Object in inputs)
				tasks.push(taskStarter(e));
			return AwaitAll(tasks);
		}
		
		/// Awaits all the tasks in a sequence and passes them each as individualarguments to the given callback function.
		/// The resulting task is the eventual result of the callback, or the fault(s) from awaiting the sequence of tasks.
		public static function ContinueWithMany(tasks:*, callback:Function):Task {
			return AwaitAll(tasks).ContinueWith(function(v:Array):* {
				return callback.apply(null, v);
			});
		}
		/// Awaits all the tasks in a sequence and passes them each as individualarguments to the given callback function.
		/// The resulting task is the unwrapped eventual result of the callback, or the fault(s) from awaiting the sequence of tasks.
		public static function BindMany(tasks:*, callback:Function):Task {
			return AwaitAll(tasks).Bind(function(v:Array):Task {
				return callback.apply(null, v);
			});
		}

		/// Returns a Task<T> with the same result except it faults if the given task doesn't complete within the timeout.
		public static function WithTimeout(t:Task, timeoutMilliseconds : Number):Task {
			var r:TaskSource = new TaskSource();
			t.Await(function():void {
				if (r.IsRunning()) r.SetFromTask(t, true);
			} );
			TaskInterop.Delay(timeoutMilliseconds).Await(function():void { 
				if (r.IsRunning()) r.SetFault(new IllegalOperationError("Timeout"));
			} );
			return r;
		}
		
		/// Returns a Task<Array<T>> that completes with the results of the tasks in the given sequence of Task<T> once they are ready.
		/// If one or many of the tasks fault, the resulting task faults with an aggregate error.
		public static function AwaitAll(tasks:*):Task {
			if (tasks == null) throw new ArgumentError("tasks == null");
			var r:TaskSource = new TaskSource();
			if (tasks.length == 0) r.SetResult(new Array(0));
			var L:Array = new Array();
			var n:int = 0;
			var E:Array = new Array();
			for (var i:int = 0; i < tasks.length; i++) {
				var g:Function = function():void {
					var i_:int = i;
					var t:Task = tasks[i_];
					L.push(null);
					t.Await(function():void {
						n += 1;
						if (t.IsFaulted()) E.push(t.Fault());
						if (t.IsCompleted()) L[i_] = t.Result();
						if (n == tasks.length) {
							if (E.length == 0) {
								r.SetResult(L);
							} else {
								r.SetFault(new AggregateError(E).Collapse());
							}
						}
					});
				};
				g();
			}
			return r;
		}
		
		/// Returns a Task<T> that completes with the result or fault of one of the tasks in the given Array<Task<T>>.
		/// Does not prioritize results over faults.
		/// Throws an error when given 0 tasks.
		public static function AwaitAny(tasks:*):Task {
			if (tasks == null) throw new ArgumentError("tasks == null");
			if (tasks.length == 0) throw new ArgumentError("tasks.length == 0");
			var r:TaskSource = new TaskSource();
			for each (var t:Task in tasks) {
				if (!r.IsRunning()) break;
				var f:Function = function():void {
					var t_:Task = t;
					t.Await(function():void {
						if (r.IsRunning()) r.SetFromTask(t_, true);
					});
				};
				f();
			}
			return r;
		}

		/// Returns a list of tasks with the same results, but re-ordered so that idle tasks do not delay iteration.
		/// Completed tasks will be ordered before incomplete tasks.
		/// The ordering amongst already completed tasks is not defined.
		public static function OrderedByCompletion(tasks:Array) : Vector.<Task> {
			if (tasks == null) throw new ArgumentError("tasks == null");
			var r:Array = new Array();
			var i:int = 0;
			for each (var t:Task in tasks) {
				r.push(new TaskSource());
				var f:Function = function(t_:Task):void {
					t_.Await(function():void {
						r[i].SetFromTask(t_, true);
						i += 1;
					});
				};
				f(t);
			}
			return Vector.<Task>(r);
		}
		
		/// Repeatedly evaluates a condition function until its eventual result is not true.
		/// The resulting task completes when the condition function's eventual result is false, or faults if the condition function's result faults.
		/// The loopBodyCondition function should return a Task<Boolean>
		public static function DoWhile(loopBodyCondition : Function) : Task {
			var f:Function = function():Task {
				var t:Task = loopBodyCondition();
				return t.Bind(function(cont:Boolean):Task {
					if (!cont) return TaskEx.Wrap(false);
					return f();
				});
			}
			return f();
		}
	}
}
