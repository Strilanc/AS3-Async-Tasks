package {
	import asunit.framework.TestResult;
	import asunit.framework.TestSuite;
	import asunit.textui.TestRunner;
	import Async.Task;
	import Async.TaskSource;
	import Async.TaskEx;
	import Async.TaskInterop;
	import Async.TestAsync;
	import flash.display.Stage;
	import flash.errors.IllegalOperationError;

	public class AllTests extends TestSuite {
		private static var HACKY_LAST_INSTANCE:AllTests;
		public function AllTests() {
			super();
			addTest(new TestAsync());
			HACKY_LAST_INSTANCE = this;
		}
		public static function RunShowAsync(stage : Stage) :Task {
			var r:TaskSource = new TaskSource();
			var testRunner:TestRunner = new TestRunner();
			stage.addChild(testRunner);
			var testResult:TestResult = testRunner.start(AllTests, null, TestRunner.SHOW_TRACE);
			var allTests:AllTests = HACKY_LAST_INSTANCE;
			
			var queryResultLooper:Function = function():void {
				if (!allTests.getIsComplete()) {
					TaskInterop.Delay(100).Await(queryResultLooper);
					return;
				}
				if (testResult.failureCount() > 0 || testResult.errorCount() > 0) {
					r.SetFault(new IllegalOperationError("Test Failures"));
				} else {
					r.SetResult(null);
					stage.removeChild(testRunner);		
				}
			}
			queryResultLooper();
			
			return r;
		}
	}
}
