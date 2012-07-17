package Async {
	import asunit.framework.TestCase;
	import Async.Task;
	import Async.TaskEx;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	public class TestLinq extends TestCase {
		public function TestLinq() { super(null); }
		// note: test methods are recognized by being prefixed with "test" (ps: "Test" won't work)
		
		private var isEven:Function = function(e:int):Boolean { return e % 2 == 0; }

		public function testSingle() : void {
			assertEquals(Linq.Single(new Array(1,3,2), isEven), 2);
			assertEquals(Linq.Single(new Array(4,1,5), isEven), 4);
			assertEquals(Linq.SingleOrDefault(new Array(13,7), isEven, 5), 5);
			assertEquals(Linq.SingleOrDefault(new Array(2,3), isEven, 5), 2);
			assertEquals(Linq.SingleOrDefault(new Array(), isEven, 6), 6);
		}
		public function testFirst() : void {
			assertEquals(Linq.First(new Array(1,3,2,6,3,4), isEven), 2);
			assertEquals(Linq.First(new Array(4,1,5), isEven), 4);
			assertEquals(Linq.FirstOrDefault(new Array(13,7), isEven, 5), 5);
			assertEquals(Linq.FirstOrDefault(new Array(1,1,1,1,1,2), isEven, 5), 2);
			assertEquals(Linq.FirstOrDefault(new Array(), isEven, 6), 6);
		}
		public function testLast() : void {
			assertEquals(Linq.Last(new Array(1,3,2,6,3,4), isEven), 4);
			assertEquals(Linq.Last(new Array(4,1,5), isEven), 4);
			assertEquals(Linq.LastOrDefault(new Array(13,7), isEven, 5), 5);
			assertEquals(Linq.LastOrDefault(new Array(1,1,1,1,1,2), isEven, 5), 2);
			assertEquals(Linq.LastOrDefault(new Array(), isEven, 6), 6);
		}
		public function testMap() : void {
			assertEqualsArrays(Linq.Map(new Array(1,3,2,6,3,4), isEven), new Array(false,false,true,true,false,true));
		}
		public function testWhere() : void {
			assertEqualsArrays(Linq.Where(new Array(1,3,2,6,3,4), isEven), new Array(2,6,4));
		}
		public function testAny() : void {
			assertEquals(Linq.Any(new Array(1,3,2,6,3,4), isEven), true);
			assertEquals(Linq.Any(new Array(1,3,2,3), isEven), true);
			assertEquals(Linq.Any(new Array(1,3,3), isEven), false);
			assertEquals(Linq.Any(new Array(0,2), isEven), true);
			assertEquals(Linq.Any(new Array(), isEven), false);
		}
		public function testAll() : void {
			assertEquals(Linq.All(new Array(1,3,2,6,3,4), isEven), false);
			assertEquals(Linq.All(new Array(1,3,2,3), isEven), false);
			assertEquals(Linq.All(new Array(1,3,3), isEven), false);
			assertEquals(Linq.All(new Array(0,2), isEven), true);
			assertEquals(Linq.All(new Array(), isEven), true);
		}
		public function testDistinct() : void {
			assertEqualsArrays(Linq.Distinct(new Array(1,3,2,6,3,4)), new Array(1,3,2,6,4));
		}
	}
}