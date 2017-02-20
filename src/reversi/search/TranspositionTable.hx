package reversi.search;
import haxe.ds.Vector;

/**
 * ...
 */
class TranspositionTable {
	public static inline var NUM:Int = 0x80000;
	public static inline var MASK:Int = NUM - 1;
	var keys:Vector<Vector<Int>>;
	var values:Vector<Vector<Float>>;

	public function new() {
		keys = new Vector<Vector<Int>>(NUM);
		values = new Vector<Vector<Float>>(NUM);
		for (i in 0...NUM) {
			keys[i] = new Vector<Int>(5);
			values[i] = new Vector<Float>(2);
		}
	}

	@:extern
	public inline function clear():Void {
		for (i in 0...NUM) {
			keys[i][0] = 0;
			keys[i][1] = 0;
			keys[i][2] = 0;
			keys[i][3] = 0;
			keys[i][4] = 0;
			values[i][0] = 0;
			values[i][1] = 0;
		}
	}

	@:extern
	public inline function count():Int {
		var c = 0;
		for (i in 0...NUM) {
			if (values[i][0] != 0 || values[i][1] != 0) {
				c++;
			}
		}
		return c;
	}

	@:extern
	public inline function get(index:Int, b0:Int, b1:Int, w0:Int, w1:Int, turnAndLookahead:Int):Vector<Float> {
		var key:Vector<Int> = keys[index];
		if (key[0] == b0 && key[1] == b1 && key[2] == w0 && key[3] == w1 && key[4] == turnAndLookahead) {
			return values[index]; // data exists
		}
		return null;
	}

	@:extern
	public inline function set(index:Int, b0:Int, b1:Int, w0:Int, w1:Int, turnAndLookahead:Int, lower:Float, upper:Float):Void {
		var key:Vector<Int> = keys[index];
		var value:Vector<Float> = values[index];
		key[0] = b0;
		key[1] = b1;
		key[2] = w0;
		key[3] = w1;
		key[4] = turnAndLookahead;
		value[0] = lower;
		value[1] = upper;
	}

	@:extern
	public static inline function index(b0:Int, b1:Int, w0:Int, w1:Int, turnAndLookahead:Int):Int {
		var t:Int = 17;
		t = (t << 5) - t + b0;
		t = (t << 5) - t + b1;
		t = (t << 5) - t + w0;
		t = (t << 5) - t + w1;
		t = (t << 5) - t + turnAndLookahead;
		return t % 326894275 & MASK;
	}

}
