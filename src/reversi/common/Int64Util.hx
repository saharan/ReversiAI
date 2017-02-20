package reversi.common;
import haxe.macro.Expr;

/**
 * ...
 */
class Int64Util {
	/**
	 * [d1 d0] = s << n
	 */
	macro public static function sll32(d0:Expr, d1:Expr, s:Expr, n:ExprOf<Int>):Expr {
		return macro {
			// m = 0000...0 (n = 0-31)
			//      or
			//     1111...1 (n = 32-63)
			var m:Int = -($n >> 5);
			var k:Int = Int64Util.allBitsOneIfNotZero32($n);
			$d0 = ~m & $s << $n;
			$d1 = ~m & $s >>> 32 - $n & k | (m & $s << $n - 32);
		};
	}

	/**
	 * [d1 d0] = [s1 s0] << n
	 */
	macro public static function sll64(d0:Expr, d1:Expr, s0:Expr, s1:Expr, n:ExprOf<Int>):Expr {
		return macro {
			// m = 0000...0 (n = 0-31)
			//      or
			//     1111...1 (n = 32-63)
			var m:Int = -($n >> 5);
			var k:Int = Int64Util.allBitsOneIfNotZero32($n);
			$d0 = ~m & $s0 << $n;
			$d1 = ~m & ($s0 >>> 32 - $n & k | $s1 << $n) | (m & $s0 << $n - 32);
		};
	}

	/**
	 * [d1 d0] = [s1 s0] >>> n
	 */
	macro public static function slr64(d0:Expr, d1:Expr, s0:Expr, s1:Expr, n:ExprOf<Int>):Expr {
		return macro {
			// m = 0000...0 (n = 0-31)
			//      or
			//     1111...1 (n = 32-63)
			var m:Int = -($n >> 5);
			var k:Int = Int64Util.allBitsOneIfNotZero32($n);
			$d0 = ~m & ($s1 << 32 - $n & k | $s0 >>> $n) | (m & $s1 >>> $n - 32);
			$d1 = ~m & $s1 >>> $n;
		};
	}

	/**
	 * [d1 d0] = [s1 s0] + n
	 */
	macro public static function add32(d0:Expr, d1:Expr, s0:Expr, s1:Expr, n:ExprOf<Int>):Expr {
		// overflow if: s0 | n == 1***...*
		//               and
		//              s0 + n == 0***...*
		return macro $d1 = $s1 + (($s0 | $n) >>> 31 & ~($d0 = $s0 + $n) >>> 31);
	}

	/**
	 * [d1 d0] = [s1 s0] - n
	 */
	macro public static function sub32(d0:Expr, d1:Expr, s0:Expr, s1:Expr, n:ExprOf<Int>):Expr {
		return macro {
			// [s1 s0] - n = [s1 s0] + -[0 n]
			//             = [s1 s0] + [1111...1 ~n] + 1
			//             = [s1 - 1 s0] + ~n + 1
			//             = ([s1 - 1 s0] + ~n) + 1
			$d1 = $s1 - 1 + (($s0 | ~$n) >>> 31 & ~($d0 = $s0 + ~$n) >>> 31); // see add32
			$d1 += $d0 >>> 31 & ~++$d0 >>> 31; // see inc
		};
	}

	/**
	 * [d1 d0] = -[d1 d0]
	 */
	macro public static function neg(d0:Expr, d1:Expr):Expr {
		// -[d1 d0] = ~[d1 d0] + 1
		return macro $d1 = ~$d1 + (~$d0 >>> 31 & ~($d0 = -$d0) >>> 31); // see inc
	}

	/**
	 * [d1 d0]--
	 */
	macro public static function dec(d0:Expr, d1:Expr):Expr {
		// [d1 d0] - 1 = [d1 d0] + -[0 1]
		//             = [d1 d0] + [1111...1 1111...1]
		//             = [d1 - 1 d0] + [0 1111...1]
		//             = [d1 - 1 d0] + 1111...1
		return macro $d1 += -1 + (~--$d0 >>> 31); // see add32
	}

	/**
	 * [d1 d0]++
	 */
	macro public static function inc(d0:Expr, d1:Expr):Expr {
		return macro $d1 += $d0 >>> 31 & ~++$d0 >>> 31; // see add32
	}

	/**
	 * [d1 d0] = (lowest one bit of [s1 s0])
	 */
	macro public static function lowestOneBit(d0:Expr, d1:Expr, s0:Expr, s1:Expr):Expr {
		return macro {
			$d0 = $s0;
			$d1 = $s1;
			$d1 = ~$d1 + (~$d0 >>> 31 & ~($d0 = -$d0) >>> 31); // negate
			$d0 &= $s0;
			$d1 &= $s1;
		};
	}

	/**
	 * [d1 d0] = (highest one bit of [s1 s0])
	 */
	macro public static function highestOneBit(d0:Expr, d1:Expr, s0:Expr, s1:Expr):Expr {
		return macro {
			$d0 = $s0 | $s0 >>> 1;
			$d1 = $s1 | $s1 >>> 1;
			$d0 |= -(($d1 | -$d1) >>> 31); // -1 if t1 != 0
			$d0 |= $d0 >>> 2;
			$d1 |= $d1 >>> 2;
			$d0 |= $d0 >>> 4;
			$d1 |= $d1 >>> 4;
			$d0 |= $d0 >>> 8;
			$d1 |= $d1 >>> 8;
			$d0 |= $d0 >>> 16;
			$d1 |= $d1 >>> 16;
			$d0 = $d0 ^ ($d0 >>> 1 | $d1 << 31);
			$d1 = $d1 ^ $d1 >>> 1;
		};
	}

	@:extern
	public static inline function countBits32(a:Int):Int {
		a = (a & 0x55555555) + (a >>> 1 & 0x55555555);
		a = (a & 0x33333333) + (a >>> 2 & 0x33333333);
		a = (a & 0x0f0f0f0f) + (a >>> 4 & 0x0f0f0f0f);
		a = (a & 0x00ff00ff) + (a >>> 8 & 0x00ff00ff);
		return a = (a & 0x0000ffff) + (a >>> 16 & 0x0000ffff);
	}

	@:extern
	public static inline function countBits64(b0:Int, b1:Int):Int {
		b0 = (b0 & 0x55555555) + (b0 >>> 1 & 0x55555555);
		b1 = (b1 & 0x55555555) + (b1 >>> 1 & 0x55555555);
		b0 = (b0 & 0x33333333) + (b0 >>> 2 & 0x33333333);
		b1 = (b1 & 0x33333333) + (b1 >>> 2 & 0x33333333);
		// b0:      00000aaa00000bbb00000ccc00000ddd
		// b1:      00000eee00000fff00000ggg00000hhh
		// b0 + b1: 0000iiii0000jjjj0000kkkk0000llll
		b0 += b1;
		b0 = (b0 & 0x0f0f0f0f) + (b0 >>> 4 & 0x0f0f0f0f);
		b0 = (b0 & 0x00ff00ff) + (b0 >>> 8 & 0x00ff00ff);
		return b0 = (b0 & 0x0000ffff) + (b0 >>> 16 & 0x0000ffff);
	}

	/**
	 * a == 0 -> 0
	 * a != 0 -> 1
	 */
	@:extern
	public static inline function oneIfNotZero32(a:Int):Int {
		// a == 0 => (a | -a) >>> 31 == 0
		// a != 0 => (a | -a) >>> 31 == 1
		return (a | -a) >>> 31;
	}

	/**
	 * [b1 b0] == 0 -> 0
	 * [b1 b0] != 0 -> 1
	 */
	@:extern
	public static inline function oneIfNotZero64(b0:Int, b1:Int):Int {
		// see oneIfNotZero32
		return ((b0 |= b1) | -b0) >>> 31;
	}

	/**
	 * a == 0 -> 00000000000000000000000000000000
	 * a != 0 -> 11111111111111111111111111111111
	 */
	@:extern
	public static inline function allBitsOneIfNotZero32(a:Int):Int {
		// -0 == 000...0
		// -1 == 111...1
		return -((a | -a) >>> 31);
	}

	/**
	 * [b1 b0] == 0 -> 00000000000000000000000000000000
	 * [b1 b0] != 0 -> 11111111111111111111111111111111
	 */
	@:extern
	public static inline function allBitsOneIfNotZero64(b0:Int, b1:Int):Int {
		// -0 == 000...0
		// -1 == 111...1
		return -(((b0 |= b1) | -b0) >>> 31);
	}

	public static inline function trace32(a:Int):Void {
		var str = "";
		var cnt:Int = 0;
		for (i in 0...32) {
			str = (a & 1) + str;
			if (++cnt & 7 == 0) str = " " + str;
			a >>>= 1;
		}
		trace(str.substr(1));
	}

	public static inline function trace64(a0:Int, a1:Int):Void {
		trace32(a1);
		trace32(a0);
	}
}
