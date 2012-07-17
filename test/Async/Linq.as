package Async {
	import flash.geom.Point;
	import flash.utils.Dictionary;
	public class Linq {
		public static function Any(items : *, predicate : Function) : * {
			for each (var item:* in items)
				if (predicate(item))
					return true;
			return false;
		}
		public static function All(items : *, predicate : Function) : * {
			for each (var item:* in items)
				if (!predicate(item))
					return false;
			return true;
		}

		public static function Box(xrange : * , yrange : * ) : Array {
			return MapMany(xrange, function(x:*):* { 
				return Map(yrange, function(y:*):Point { 
					return new Point(x, y); 
				});
			});
		}
		public static function Single(items : *, predicate : Function) : * {
			var result:*;
			var found:Boolean;
			for each (var item:* in items) {
				if (predicate(item)) {
					if (found) throw new ArgumentError("More than a single matching item.");
					found = true;
					result = item;
				}
			}
			if (!found) throw new ArgumentError("No single matching item.");
			return result;
		}
		public static function SingleOrDefault(items : *, predicate : Function, def:* = null) : * {
			var result:*;
			var found:Boolean;
			for each (var item:* in items) {
				if (predicate(item)) {
					if (found) throw new ArgumentError("More than a single matching item.");
					found = true;
					result = item;
				}
			}
			return found ? result : def;
		}

		public static function First(items : *, predicate : Function) : * {
			for each (var item:* in items) {
				if (predicate(item)) {
					return item;
				}
			}
			throw new ArgumentError("No first matching item.");
		}
		public static function FirstOrDefault(items : *, predicate : Function, def:* = null) : * {
			for each (var item:* in items) {
				if (predicate(item)) {
					return item;
				}
			}
			return def;
		}

		public static function Last(items : *, predicate : Function) : * {
			var result:*;
			var found:Boolean;
			for each (var item:* in items) {
				if (predicate(item)) {
					found = true;
					result = item;
				}
			}
			if (!found) throw new ArgumentError("No last matching item.");
			return result;
		}
		public static function LastOrDefault(items : *, predicate : Function, def:* = null) : * {
			var result:*;
			var found:Boolean;
			for each (var item:* in items) {
				if (predicate(item)) {
					found = true;
					result = item;
				}
			}
			return found ? result : def;
		}
		
		public static function Range(length : int) : Array {
			var r : Array = new Array();
			for (var i : int = 0; i < length; i++)
				r.push(i);
			return r;
		}
		public static function Map(items : *, projection : Function) : Array {
			var result:Array = new Array();
			for each (var item:* in items) {
				result.push(projection(item))
			}
			return result;
		}
		public static function SkipNulls(items : * ) : Array {
			return Where(items, function(e:*):Boolean { return e != null; } );
		}
		public static function ConcatMany(items : *) : Array {
			var result:Array = new Array();
			for each (var item:* in items) {
				for each (var projItem:* in item) {
					result.push(projItem)
				}
			}
			return result;
		}
		public static function MapMany(items : *, projection : Function) : Array {
			var result:Array = new Array();
			for each (var item:* in items) {
				for each (var projItem:* in projection(item)) {
					result.push(projItem)
				}
			}
			return result;
		}
		public static function Where(items : *, predicate : Function) : Array {
			var result:Array = new Array();
			for each (var item:* in items) {
				if (predicate(item)) {
					result.push(item);
				}
			}
			return result;
		}
		public static function Distinct(items : *) : Array {
			var d:Dictionary = new Dictionary();
			var r:Array = new Array();
			for each (var item:* in items) {
				if (item in d) continue;
				r.push(item);
				d[item] = true;
			}
			return r;
		}
	}
}
