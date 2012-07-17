package Async {
	import asunit.framework.TestCase;
	import Async.Task;
	import Async.TaskSource;
	import Async.TaskEx;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	public class TestAsync extends TestCase {
		public function TestAsync() { super(null); }
		// note: test methods are recognized by being prefixed with "test" (ps: "Test" won't work)

		private function testableAwaitCallback(func : Function) : Function {
			var x:Function = this.addAsync(func);
			if (func.length > 0) return x;
			return function():* { return x(); };
		}
		private function assertTaskWillBe(task : Task, result : Object, timeoutMillis:Number = DEFAULT_TIMEOUT) : void {
			task.Await(testableAwaitCallback(function():void {
				assertEquals(task.IsCompleted(), true);
				assertEquals(task.Result(), result);
			}));
		}
		private function assertTaskWillBeArray(task : Task, result : Array, timeoutMillis:Number = DEFAULT_TIMEOUT) : void {
			task.Await(testableAwaitCallback(function():void {
				assertEquals(task.IsCompleted(), true);
				assertEqualsArrays(task.Result(), result);
			}));
		}
		private function assertTaskWillFault(task : Task, fault : Object = null, timeoutMillis:Number = DEFAULT_TIMEOUT) : void {
			task.Await(testableAwaitCallback(function():void {
				assertEquals(task.IsFaulted(), true);
				if (fault != null) assertEquals(task.Fault(), fault);
			}));
		}
		private function assertTaskWillHangFor(task : Task, hangMillis:int = 50) : void {
			var t:Timer = new Timer(hangMillis, 1);
			t.start();
			t.addEventListener(TimerEvent.TIMER, this.addAsync(function():void {
				assertEquals(task.IsCompleted(), false);
				assertEquals(task.IsFaulted(), false);
			}));
		}
		
		public function testWrap() : void {
			assertEquals(TaskEx.Wrap(null).IsCompleted(), true);
			assertEquals(TaskEx.Wrap(null).Result(), null);
			assertEquals(TaskEx.Wrap(5).Result(), 5);
			assertEquals(TaskEx.Wrap(6, true).IsCompleted(), false);
			assertTaskWillBe(TaskEx.Wrap(6, true), 6);
		}
		public function testWrapFault() : void {
			assertEquals(TaskEx.WrapFault(null, true).IsFaulted(), false);
			assertEquals(TaskEx.WrapFault(null, false).IsFaulted(), true);
			assertTaskWillFault(TaskEx.WrapFault(null, true));
			assertEquals(TaskEx.WrapFault(null, false).Fault(), null);
			assertEquals(TaskEx.WrapFault(5, false).Fault(), 5);
		}
		public function testDefer() : void {
			assertEquals(TaskInterop.Defer().IsCompleted(), false);
			assertEquals(TaskInterop.Defer(4).IsCompleted(), false);
			assertTaskWillBe(TaskInterop.Defer(4), 4, 200);
			assertTaskWillBe(TaskInterop.Defer(3), 3, 200);
		}
		public function testDelay() : void {
			var t:Task = TaskInterop.Delay(500, true);
			assertTaskWillHangFor(t, 25);
			assertTaskWillBe(t, true);
			var t2:Task = TaskInterop.Delay(0, 5);
			assertEquals(t2.IsCompleted(), false);
			assertTaskWillBe(t2, 5);
		}
		public function testAwaitAll() : void {
			assertTaskWillBeArray(TaskEx.AwaitAll(new Array(TaskEx.Wrap("test"))), new Array("test"));
			assertTaskWillBeArray(TaskEx.AwaitAll(new Array()), new Array());
			assertTaskWillBeArray(TaskEx.AwaitAll(new Array(TaskEx.Wrap(1), TaskEx.Wrap(2))), new Array(1, 2));
			assertTaskWillFault(TaskEx.AwaitAll(new Array(TaskEx.WrapFault(new Error()), TaskEx.Wrap(2))));
			assertTaskWillHangFor(TaskEx.AwaitAll(new Array(new TaskSource(), TaskEx.WrapFault(new Error()), TaskEx.Wrap(1))))
		}
	}
}