package reversi.evaluation;
import haxe.ds.Vector;
import haxe.macro.Expr;
import reversi.common.Int64Util;
import reversi.common.Turn;
import reversi.core.Board;

/**
 * ...
 */
class Features {
	static var horVert2Index:Vector<Int> = new Vector<Int>(6561);
	static var horVert3Index:Vector<Int> = new Vector<Int>(6561);
	static var horVert4Index:Vector<Int> = new Vector<Int>(6561);
	static var diag4Index:Vector<Int> = new Vector<Int>(81);
	static var diag5Index:Vector<Int> = new Vector<Int>(243);
	static var diag6Index:Vector<Int> = new Vector<Int>(729);
	static var diag7Index:Vector<Int> = new Vector<Int>(2187);
	static var diag8Index:Vector<Int> = new Vector<Int>(6561);
	static var edge2XIndex:Vector<Int> = new Vector<Int>(59049);
	static var corner25Index:Vector<Int> = new Vector<Int>(59049);
	static var corner33Index:Vector<Int> = new Vector<Int>(19683);

	public static inline var NUM_PATTERN_FEATURES:Int = 46;
	public static inline var NUM_NON_PATTERN_FEATURES:Int = 7;
	public static inline var NUM_TOTAL_FEATURES:Int = NUM_PATTERN_FEATURES + NUM_NON_PATTERN_FEATURES;

	// 0-45: patterns
	// 46:   diff of mobility
	// 47:   parity of number of squares both players can put on (odd: +1, even: -1)
	// 48:   diff of num even holes players cannot put on
	// 49:   diff of num odd holes players cannot put on
	// 50:   diff of disks
	// 51:   diff of num X-squares without corresponding corners
	// 52:   diff of corners
	public static var features(default, null):Vector<Int> = new Vector<Int>(NUM_TOTAL_FEATURES);

	public static var numPatterns(default, null):Int;

	public static function computeIndices():Void {
		numPatterns = 0;

		var computeIndex:String -> Vector<Int> -> Int -> (Int -> Int) -> Void = function(name:String, idx:Vector<Int>, num:Int, computeAnotherIndex:Int -> Int):Void {
			if (numPatterns == 0) {
				// null pattern (its score should be 0.0)
				numPatterns++;
			}
			for (i in 0...num) {
				var j:Int = reverseColor(i);
				var i2:Int = computeAnotherIndex(i);

				if (j == i2) {
					// this pattern is absolutely "fair"
					// e.g.
					//     BBBBWWWW,
					//     .B....W.,
					//     WBWBWBWB,
					//     ...BW..., etc...
					//
					// FIXME: this turned out to be WRONG
					//        e.g. (edge2X)
					//            W    B
					//           .BBBWWW.
					idx[i] = 0;
					continue;
				}
				if (i <= i2) {
					// new pattern found
					idx[i] = numPatterns;
					numPatterns++;
				} else {
					// a symmetrical pattern appeared in the past, use the old index
					idx[i] = idx[i2];
				}
			}
		};

		numPatterns = 0;

		computeIndex("horVert2", horVert2Index, 6561, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int;
			extract8(i, b0, b1, b2, b3, b4, b5, b6, b7);
			return computeRawIndex(0, 0, b7, b6, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("horVert3", horVert3Index, 6561, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int;
			extract8(i, b0, b1, b2, b3, b4, b5, b6, b7);
			return computeRawIndex(0, 0, b7, b6, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("horVert4", horVert4Index, 6561, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int;
			extract8(i, b0, b1, b2, b3, b4, b5, b6, b7);
			return computeRawIndex(0, 0, b7, b6, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("diag4", diag4Index, 81, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int;
			extract4(i, b0, b1, b2, b3);
			return computeRawIndex(0, 0, 0, 0, 0, 0, b3, b2, b1, b0);
		});

		computeIndex("diag5", diag5Index, 243, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int;
			extract5(i, b0, b1, b2, b3, b4);
			return computeRawIndex(0, 0, 0, 0, 0, b4, b3, b2, b1, b0);
		});

		computeIndex("diag6", diag6Index, 729, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int;
			extract6(i, b0, b1, b2, b3, b4, b5);
			return computeRawIndex(0, 0, 0, 0, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("diag7", diag7Index, 2187, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int;
			extract7(i, b0, b1, b2, b3, b4, b5, b6);
			return computeRawIndex(0, 0, 0, b6, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("diag8", diag8Index, 6561, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int;
			extract8(i, b0, b1, b2, b3, b4, b5, b6, b7);
			return computeRawIndex(0, 0, b7, b6, b5, b4, b3, b2, b1, b0);
		});

		computeIndex("edge2X", edge2XIndex, 59049, function(i) {
			var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int, x0:Int, x1:Int;
			extract10(i, b0, b1, b2, b3, b4, b5, b6, b7, x0, x1);
			return computeRawIndex(b7, b6, b5, b4, b3, b2, b1, b0, x1, x0);
		});

		computeIndex("corner25", corner25Index, 59049, function(i) {
			return i; // no symmetrical patterns in this pattern type
		});

		computeIndex("corner33", corner33Index, 19683, function(i) {
			var b00:Int, b01:Int, b02:Int, b10:Int, b11:Int, b12:Int, b20:Int, b21:Int, b22:Int;
			extract9(i, b00, b01, b02, b10, b11, b12, b20, b21, b22);
			return computeRawIndex(0, b00, b10, b20, b01, b11, b21, b02, b12, b22);
		});
	}

	//@:extern
	static inline function reverseColor(i:Int):Int {
		var b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int, b8:Int, b9:Int;
		extract10(i, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9);
		b0 = b0 << 1 | b0 >>> 1 & 3;
		b1 = b1 << 1 | b1 >>> 1 & 3;
		b2 = b2 << 1 | b2 >>> 1 & 3;
		b3 = b3 << 1 | b3 >>> 1 & 3;
		b4 = b4 << 1 | b4 >>> 1 & 3;
		b5 = b5 << 1 | b5 >>> 1 & 3;
		b6 = b6 << 1 | b6 >>> 1 & 3;
		b7 = b7 << 1 | b7 >>> 1 & 3;
		b8 = b8 << 1 | b8 >>> 1 & 3;
		b9 = b9 << 1 | b9 >>> 1 & 3;
		return computeRawIndex(b0, b1, b2, b3, b4, b5, b6, b7, b8, b9);
	}

	static macro function extract10(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr, b5:Expr, b6:Expr, b7:Expr, b8:Expr, b9:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b9 = k % 3;
			$b8 = (k = Std.int(k / 3)) % 3;
			$b7 = (k = Std.int(k / 3)) % 3;
			$b6 = (k = Std.int(k / 3)) % 3;
			$b5 = (k = Std.int(k / 3)) % 3;
			$b4 = (k = Std.int(k / 3)) % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract9(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr, b5:Expr, b6:Expr, b7:Expr, b8:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b8 = k % 3;
			$b7 = (k = Std.int(k / 3)) % 3;
			$b6 = (k = Std.int(k / 3)) % 3;
			$b5 = (k = Std.int(k / 3)) % 3;
			$b4 = (k = Std.int(k / 3)) % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract8(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr, b5:Expr, b6:Expr, b7:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b7 = k % 3;
			$b6 = (k = Std.int(k / 3)) % 3;
			$b5 = (k = Std.int(k / 3)) % 3;
			$b4 = (k = Std.int(k / 3)) % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract7(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr, b5:Expr, b6:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b6 = k % 3;
			$b5 = (k = Std.int(k / 3)) % 3;
			$b4 = (k = Std.int(k / 3)) % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract6(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr, b5:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b5 = k % 3;
			$b4 = (k = Std.int(k / 3)) % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract5(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr, b4:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b4 = k % 3;
			$b3 = (k = Std.int(k / 3)) % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	static macro function extract4(i:Expr, b0:Expr, b1:Expr, b2:Expr, b3:Expr):Expr {
		return macro {
			var k:Int = $i;
			$b3 = k % 3;
			$b2 = (k = Std.int(k / 3)) % 3;
			$b1 = (k = Std.int(k / 3)) % 3;
			$b0 = (Std.int(k / 3)) % 3;
		};
	}

	@:extern
	static inline function computeIndexHorVert2(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		return horVert2Index[index];
	}

	@:extern
	static inline function computeIndexHorVert3(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		return horVert3Index[index];
	}

	@:extern
	static inline function computeIndexHorVert4(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		return horVert4Index[index];
	}

	@:extern
	static inline function computeIndexDiag4(b0:Int, b1:Int, b2:Int, b3:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		return diag4Index[index];
	}

	@:extern
	static inline function computeIndexDiag5(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		return diag5Index[index];
	}

	@:extern
	static inline function computeIndexDiag6(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		return diag6Index[index];
	}

	@:extern
	static inline function computeIndexDiag7(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		return diag7Index[index];
	}

	@:extern
	static inline function computeIndexDiag8(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		return diag8Index[index];
	}

	@:extern
	static inline function computeIndexEdge2X(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int, x0:Int, x1:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		index = (index << 1) + index + x0;
		index = (index << 1) + index + x1;
		return edge2XIndex[index];
	}

	@:extern
	static inline function computeIndexCorner33(b00:Int, b01:Int, b02:Int, b10:Int, b11:Int, b12:Int, b20:Int, b21:Int, b22:Int):Int {
		var index:Int = (b00 << 1) + b00 + b01;
		index = (index << 1) + index + b02;
		index = (index << 1) + index + b10;
		index = (index << 1) + index + b11;
		index = (index << 1) + index + b12;
		index = (index << 1) + index + b20;
		index = (index << 1) + index + b21;
		index = (index << 1) + index + b22;
		return corner33Index[index];
	}

	@:extern
	static inline function computeIndexCorner25(b00:Int, b01:Int, b02:Int, b03:Int, b04:Int, b10:Int, b11:Int, b12:Int, b13:Int, b14:Int):Int {
		var index:Int = (b00 << 1) + b00 + b01;
		index = (index << 1) + index + b02;
		index = (index << 1) + index + b03;
		index = (index << 1) + index + b04;
		index = (index << 1) + index + b10;
		index = (index << 1) + index + b11;
		index = (index << 1) + index + b12;
		index = (index << 1) + index + b13;
		index = (index << 1) + index + b14;
		return corner25Index[index];
	}

	@:extern
	static inline function computeRawIndex(b0:Int, b1:Int, b2:Int, b3:Int, b4:Int, b5:Int, b6:Int, b7:Int, b8:Int, b9:Int):Int {
		var index:Int = (b0 << 1) + b0 + b1;
		index = (index << 1) + index + b2;
		index = (index << 1) + index + b3;
		index = (index << 1) + index + b4;
		index = (index << 1) + index + b5;
		index = (index << 1) + index + b6;
		index = (index << 1) + index + b7;
		index = (index << 1) + index + b8;
		index = (index << 1) + index + b9;
		return index;
	}

	@:extern
	public static inline function extract(b:Board, turn:Int):Void {
		var reversed:Bool = turn == Turn.WHITE;
		if (reversed) {
			b.reverseColors();
		}

		b.computeBlackMoility();
		b.computeWhiteMoility();
		var bm0:Int = b.blackMobility[0];
		var bm1:Int = b.blackMobility[1];
		var wm0:Int = b.whiteMobility[0];
		var wm1:Int = b.whiteMobility[1];
		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var e0:Int = ~(b0 | w0);
		var e1:Int = ~(b1 | w1);

		// 77 76 75 74 73 72 71 70
		// 67 66 65 64 63 62 61 60
		// 57 56 55 54 53 52 51 50
		// 47 46 45 44 43 42 41 40
		// 37 36 35 34 33 32 31 30
		// 27 26 25 24 23 22 21 20
		// 17 16 15 14 13 12 11 10
		// 07 06 05 04 03 02 01 00

		var b00:Int, b01:Int, b02:Int, b03:Int, b04:Int, b05:Int, b06:Int, b07:Int;
		var b10:Int, b11:Int, b12:Int, b13:Int, b14:Int, b15:Int, b16:Int, b17:Int;
		var b20:Int, b21:Int, b22:Int, b23:Int, b24:Int, b25:Int, b26:Int, b27:Int;
		var b30:Int, b31:Int, b32:Int, b33:Int, b34:Int, b35:Int, b36:Int, b37:Int;
		var b40:Int, b41:Int, b42:Int, b43:Int, b44:Int, b45:Int, b46:Int, b47:Int;
		var b50:Int, b51:Int, b52:Int, b53:Int, b54:Int, b55:Int, b56:Int, b57:Int;
		var b60:Int, b61:Int, b62:Int, b63:Int, b64:Int, b65:Int, b66:Int, b67:Int;
		var b70:Int, b71:Int, b72:Int, b73:Int, b74:Int, b75:Int, b76:Int, b77:Int;

		var tmpb0:Int = b0;
		var tmpb1:Int = b1;
		var tmpw0:Int = w0;
		var tmpw1:Int = w1;

		b00 = b0 & 1;          b01 = (b0 >>>= 1) & 1; b02 = (b0 >>>= 1) & 1; b03 = (b0 >>>= 1) & 1; b04 = (b0 >>>= 1) & 1; b05 = (b0 >>>= 1) & 1; b06 = (b0 >>>= 1) & 1; b07 = (b0 >>>= 1) & 1;
		b10 = (b0 >>>= 1) & 1; b11 = (b0 >>>= 1) & 1; b12 = (b0 >>>= 1) & 1; b13 = (b0 >>>= 1) & 1; b14 = (b0 >>>= 1) & 1; b15 = (b0 >>>= 1) & 1; b16 = (b0 >>>= 1) & 1; b17 = (b0 >>>= 1) & 1;
		b20 = (b0 >>>= 1) & 1; b21 = (b0 >>>= 1) & 1; b22 = (b0 >>>= 1) & 1; b23 = (b0 >>>= 1) & 1; b24 = (b0 >>>= 1) & 1; b25 = (b0 >>>= 1) & 1; b26 = (b0 >>>= 1) & 1; b27 = (b0 >>>= 1) & 1;
		b30 = (b0 >>>= 1) & 1; b31 = (b0 >>>= 1) & 1; b32 = (b0 >>>= 1) & 1; b33 = (b0 >>>= 1) & 1; b34 = (b0 >>>= 1) & 1; b35 = (b0 >>>= 1) & 1; b36 = (b0 >>>= 1) & 1; b37 = (b0 >>>= 1) & 1;
		b40 = b1 & 1;          b41 = (b1 >>>= 1) & 1; b42 = (b1 >>>= 1) & 1; b43 = (b1 >>>= 1) & 1; b44 = (b1 >>>= 1) & 1; b45 = (b1 >>>= 1) & 1; b46 = (b1 >>>= 1) & 1; b47 = (b1 >>>= 1) & 1;
		b50 = (b1 >>>= 1) & 1; b51 = (b1 >>>= 1) & 1; b52 = (b1 >>>= 1) & 1; b53 = (b1 >>>= 1) & 1; b54 = (b1 >>>= 1) & 1; b55 = (b1 >>>= 1) & 1; b56 = (b1 >>>= 1) & 1; b57 = (b1 >>>= 1) & 1;
		b60 = (b1 >>>= 1) & 1; b61 = (b1 >>>= 1) & 1; b62 = (b1 >>>= 1) & 1; b63 = (b1 >>>= 1) & 1; b64 = (b1 >>>= 1) & 1; b65 = (b1 >>>= 1) & 1; b66 = (b1 >>>= 1) & 1; b67 = (b1 >>>= 1) & 1;
		b70 = (b1 >>>= 1) & 1; b71 = (b1 >>>= 1) & 1; b72 = (b1 >>>= 1) & 1; b73 = (b1 >>>= 1) & 1; b74 = (b1 >>>= 1) & 1; b75 = (b1 >>>= 1) & 1; b76 = (b1 >>>= 1) & 1; b77 = (b1 >>>= 1) & 1;

		b00 |= w0 << 1 & 2;     b01 |= w0 & 2;          b02 |= (w0 >>>= 1) & 2; b03 |= (w0 >>>= 1) & 2; b04 |= (w0 >>>= 1) & 2; b05 |= (w0 >>>= 1) & 2; b06 |= (w0 >>>= 1) & 2; b07 |= (w0 >>>= 1) & 2;
		b10 |= (w0 >>>= 1) & 2; b11 |= (w0 >>>= 1) & 2; b12 |= (w0 >>>= 1) & 2; b13 |= (w0 >>>= 1) & 2; b14 |= (w0 >>>= 1) & 2; b15 |= (w0 >>>= 1) & 2; b16 |= (w0 >>>= 1) & 2; b17 |= (w0 >>>= 1) & 2;
		b20 |= (w0 >>>= 1) & 2; b21 |= (w0 >>>= 1) & 2; b22 |= (w0 >>>= 1) & 2; b23 |= (w0 >>>= 1) & 2; b24 |= (w0 >>>= 1) & 2; b25 |= (w0 >>>= 1) & 2; b26 |= (w0 >>>= 1) & 2; b27 |= (w0 >>>= 1) & 2;
		b30 |= (w0 >>>= 1) & 2; b31 |= (w0 >>>= 1) & 2; b32 |= (w0 >>>= 1) & 2; b33 |= (w0 >>>= 1) & 2; b34 |= (w0 >>>= 1) & 2; b35 |= (w0 >>>= 1) & 2; b36 |= (w0 >>>= 1) & 2; b37 |= (w0 >>>= 1) & 2;
		b40 |= w1 << 1 & 2;     b41 |= w1 & 2;          b42 |= (w1 >>>= 1) & 2; b43 |= (w1 >>>= 1) & 2; b44 |= (w1 >>>= 1) & 2; b45 |= (w1 >>>= 1) & 2; b46 |= (w1 >>>= 1) & 2; b47 |= (w1 >>>= 1) & 2;
		b50 |= (w1 >>>= 1) & 2; b51 |= (w1 >>>= 1) & 2; b52 |= (w1 >>>= 1) & 2; b53 |= (w1 >>>= 1) & 2; b54 |= (w1 >>>= 1) & 2; b55 |= (w1 >>>= 1) & 2; b56 |= (w1 >>>= 1) & 2; b57 |= (w1 >>>= 1) & 2;
		b60 |= (w1 >>>= 1) & 2; b61 |= (w1 >>>= 1) & 2; b62 |= (w1 >>>= 1) & 2; b63 |= (w1 >>>= 1) & 2; b64 |= (w1 >>>= 1) & 2; b65 |= (w1 >>>= 1) & 2; b66 |= (w1 >>>= 1) & 2; b67 |= (w1 >>>= 1) & 2;
		b70 |= (w1 >>>= 1) & 2; b71 |= (w1 >>>= 1) & 2; b72 |= (w1 >>>= 1) & 2; b73 |= (w1 >>>= 1) & 2; b74 |= (w1 >>>= 1) & 2; b75 |= (w1 >>>= 1) & 2; b76 |= (w1 >>>= 1) & 2; b77 |= (w1 >>>= 1) & 2;

		b0 = tmpb0;
		b1 = tmpb1;
		w0 = tmpw0;
		w1 = tmpw1;

		var c:Int = 0;

		// compute pattern indices

		features[c++] = computeIndexHorVert2(b10, b11, b12, b13, b14, b15, b16, b17);
		features[c++] = computeIndexHorVert3(b20, b21, b22, b23, b24, b25, b26, b27);
		features[c++] = computeIndexHorVert4(b30, b31, b32, b33, b34, b35, b36, b37);
		features[c++] = computeIndexHorVert4(b40, b41, b42, b43, b44, b45, b46, b47);
		features[c++] = computeIndexHorVert3(b50, b51, b52, b53, b54, b55, b56, b57);
		features[c++] = computeIndexHorVert2(b60, b61, b62, b63, b64, b65, b66, b67);

		features[c++] = computeIndexHorVert2(b01, b11, b21, b31, b41, b51, b61, b71);
		features[c++] = computeIndexHorVert3(b02, b12, b22, b32, b42, b52, b62, b72);
		features[c++] = computeIndexHorVert4(b03, b13, b23, b33, b43, b53, b63, b73);
		features[c++] = computeIndexHorVert4(b04, b14, b24, b34, b44, b54, b64, b74);
		features[c++] = computeIndexHorVert3(b05, b15, b25, b35, b45, b55, b65, b75);
		features[c++] = computeIndexHorVert2(b06, b16, b26, b36, b46, b56, b66, b76);

		features[c++] = computeIndexDiag4(b03, b12, b21, b30);
		features[c++] = computeIndexDiag5(b04, b13, b22, b31, b40);
		features[c++] = computeIndexDiag6(b05, b14, b23, b32, b41, b50);
		features[c++] = computeIndexDiag7(b06, b15, b24, b33, b42, b51, b60);
		features[c++] = computeIndexDiag8(b07, b16, b25, b34, b43, b52, b61, b70);
		features[c++] = computeIndexDiag7(b17, b26, b35, b44, b53, b62, b71);
		features[c++] = computeIndexDiag6(b27, b36, b45, b54, b63, b72);
		features[c++] = computeIndexDiag5(b37, b46, b55, b64, b73);
		features[c++] = computeIndexDiag4(b47, b56, b65, b74);

		features[c++] = computeIndexDiag4(b04, b15, b26, b37);
		features[c++] = computeIndexDiag5(b03, b14, b25, b36, b47);
		features[c++] = computeIndexDiag6(b02, b13, b24, b35, b46, b57);
		features[c++] = computeIndexDiag7(b01, b12, b23, b34, b45, b56, b67);
		features[c++] = computeIndexDiag8(b00, b11, b22, b33, b44, b55, b66, b77);
		features[c++] = computeIndexDiag7(b10, b21, b32, b43, b54, b65, b76);
		features[c++] = computeIndexDiag6(b20, b31, b42, b53, b64, b75);
		features[c++] = computeIndexDiag5(b30, b41, b52, b63, b74);
		features[c++] = computeIndexDiag4(b40, b51, b62, b73);

		features[c++] = computeIndexEdge2X(b00, b01, b02, b03, b04, b05, b06, b07, b11, b16);
		features[c++] = computeIndexEdge2X(b00, b10, b20, b30, b40, b50, b60, b70, b11, b61);
		features[c++] = computeIndexEdge2X(b70, b71, b72, b73, b74, b75, b76, b77, b61, b66);
		features[c++] = computeIndexEdge2X(b07, b17, b27, b37, b47, b57, b67, b77, b16, b66);

		var e:Int = b.numEmptySquares();
		var stage:Int = 9 - Std.int(e / 6);

		if (stage < 3) { // stage 0, 1, 2
			features[c++] = computeIndexCorner25(b11, b12, b13, b14, b15, b21, b22, b23, b24, b25);
			features[c++] = computeIndexCorner25(b11, b21, b31, b41, b51, b12, b22, b32, b42, b52);
			features[c++] = computeIndexCorner25(b16, b15, b14, b13, b12, b26, b25, b24, b23, b22);
			features[c++] = computeIndexCorner25(b61, b51, b41, b31, b21, b62, b52, b42, b32, b22);
			features[c++] = computeIndexCorner25(b61, b62, b63, b64, b65, b51, b52, b53, b54, b55);
			features[c++] = computeIndexCorner25(b16, b26, b36, b46, b56, b15, b25, b35, b45, b55);
			features[c++] = computeIndexCorner25(b66, b65, b64, b63, b62, b56, b55, b54, b53, b52);
			features[c++] = computeIndexCorner25(b66, b56, b46, b36, b26, b65, b55, b45, b35, b25);

			features[c++] = computeIndexCorner33(b11, b12, b13, b21, b22, b23, b31, b32, b33);
			features[c++] = computeIndexCorner33(b16, b15, b14, b26, b25, b24, b36, b35, b34);
			features[c++] = computeIndexCorner33(b61, b62, b63, b51, b52, b53, b41, b42, b43);
			features[c++] = computeIndexCorner33(b66, b65, b64, b56, b55, b54, b46, b45, b44);
		} else { // stage 3, 4, 5, 6, 7, 8, 9
			features[c++] = computeIndexCorner25(b00, b01, b02, b03, b04, b10, b11, b12, b13, b14);
			features[c++] = computeIndexCorner25(b00, b10, b20, b30, b40, b01, b11, b21, b31, b41);
			features[c++] = computeIndexCorner25(b07, b06, b05, b04, b03, b17, b16, b15, b14, b13);
			features[c++] = computeIndexCorner25(b70, b60, b50, b40, b30, b71, b61, b51, b41, b31);
			features[c++] = computeIndexCorner25(b07, b17, b27, b37, b47, b06, b16, b26, b36, b46);
			features[c++] = computeIndexCorner25(b70, b71, b72, b73, b74, b60, b61, b62, b63, b64);
			features[c++] = computeIndexCorner25(b77, b67, b57, b47, b37, b76, b66, b56, b46, b36);
			features[c++] = computeIndexCorner25(b77, b76, b75, b74, b73, b67, b66, b65, b64, b63);

			features[c++] = computeIndexCorner33(b00, b01, b02, b10, b11, b12, b20, b21, b22);
			features[c++] = computeIndexCorner33(b70, b71, b72, b60, b61, b62, b50, b51, b52);
			features[c++] = computeIndexCorner33(b07, b06, b05, b17, b16, b15, b27, b26, b25);
			features[c++] = computeIndexCorner33(b77, b76, b75, b67, b66, b65, b57, b56, b55);
		}

		// compute non-pattern features

		// compute mobility
		var blackMobilityCount:Int = Int64Util.countBits64(bm0, bm1);
		var whiteMobilityCount:Int = Int64Util.countBits64(wm0, wm1);
		features[c++] = blackMobilityCount - whiteMobilityCount;

		// compute parity data of each quadrant
		var isOddTotal:Int = 0;
		var numEvenHolesBlackCannotPutOn:Int = 0;
		var numEvenHolesWhiteCannotPutOn:Int = 0;
		var numOddHolesBlackCannotPutOn:Int = 0;
		var numOddHolesWhiteCannotPutOn:Int = 0;
		var numEmptyCellsInQuadrant:Int;
		var isOdd:Int;
		var validityMask:Int;
		var blackCannotPut:Int;
		var whiteCannotPut:Int;

		// first quadrant
		//    ........
		//    ........
		//    ........
		//    ........
		//    ....oooo
		//    ....oooo
		//    ....oooo
		//    ....oooo = 0x0f0f0f0f
		//
		// make this quadrand invalid if there any empty square in
		//    ........
		//    ........
		//    ........
		//    ...ooooo = 0x0000001f
		//    ...ooooo
		//    ...oo...
		//    ...oo...
		//    ...oo... = 0x1f181818
		validityMask = 1 ^ Int64Util.oneIfNotZero32((e1 & 0x0000001f) | (e0 & 0x1f181818));
		validityMask &= Int64Util.oneIfNotZero32(e0 & 0x0f0f0f0f);
		numEmptyCellsInQuadrant = Int64Util.countBits32(e0 & 0x0f0f0f0f);
		isOdd = numEmptyCellsInQuadrant & 1;
		blackCannotPut = 1 ^ Int64Util.oneIfNotZero32(bm0 & 0x0f0f0f0f);
		whiteCannotPut = 1 ^ Int64Util.oneIfNotZero32(wm0 & 0x0f0f0f0f);
		isOddTotal ^= ~ -blackCannotPut & ~ -whiteCannotPut & numEmptyCellsInQuadrant & 1;
		numEvenHolesBlackCannotPutOn += validityMask & ~isOdd & blackCannotPut;
		numEvenHolesWhiteCannotPutOn += validityMask & ~isOdd & whiteCannotPut;
		numOddHolesBlackCannotPutOn += validityMask & isOdd & blackCannotPut;
		numOddHolesWhiteCannotPutOn += validityMask & isOdd & whiteCannotPut;

		// second quadrant
		//    ....oooo
		//    ....oooo
		//    ....oooo
		//    ....oooo = 0x0f0f0f0f
		//    ........
		//    ........
		//    ........
		//    ........
		//
		// make this quadrand invalid if there any empty square in
		//    ...oo...
		//    ...oo...
		//    ...oo...
		//    ...ooooo = 0x1818181f
		//    ...ooooo
		//    ........
		//    ........
		//    ........ = 0x1f000000
		validityMask = 1 ^ Int64Util.oneIfNotZero32((e1 & 0x1818181f) | (e0 & 0x1f000000));
		validityMask &= Int64Util.oneIfNotZero32(e1 & 0x0f0f0f0f);
		numEmptyCellsInQuadrant = Int64Util.countBits32(e1 & 0x0f0f0f0f);
		isOdd = numEmptyCellsInQuadrant & 1;
		blackCannotPut = 1 ^ Int64Util.oneIfNotZero32(bm1 & 0x0f0f0f0f);
		whiteCannotPut = 1 ^ Int64Util.oneIfNotZero32(wm1 & 0x0f0f0f0f);
		isOddTotal ^= ~ -blackCannotPut & ~ -whiteCannotPut & numEmptyCellsInQuadrant & 1;
		numEvenHolesBlackCannotPutOn += validityMask & ~isOdd & blackCannotPut;
		numEvenHolesWhiteCannotPutOn += validityMask & ~isOdd & whiteCannotPut;
		numOddHolesBlackCannotPutOn += validityMask & isOdd & blackCannotPut;
		numOddHolesWhiteCannotPutOn += validityMask & isOdd & whiteCannotPut;

		// third quadrant
		//    oooo....
		//    oooo....
		//    oooo....
		//    oooo.... = 0xf0f0f0f0
		//    ........
		//    ........
		//    ........
		//    ........
		//
		// make this quadrand invalid if there any empty square in
		//    ...oo...
		//    ...oo...
		//    ...oo...
		//    ooooo... = 0x181818f8
		//    ooooo...
		//    ........
		//    ........
		//    ........ = 0xf8000000
		validityMask = 1 ^ Int64Util.oneIfNotZero32((e1 & 0x181818f8) | (e0 & 0xf8000000));
		validityMask &= Int64Util.oneIfNotZero32(e1 & 0xf0f0f0f0);
		numEmptyCellsInQuadrant = Int64Util.countBits32(e1 & 0xf0f0f0f0);
		isOdd = numEmptyCellsInQuadrant & 1;
		blackCannotPut = 1 ^ Int64Util.oneIfNotZero32(bm1 & 0xf0f0f0f0);
		whiteCannotPut = 1 ^ Int64Util.oneIfNotZero32(wm1 & 0xf0f0f0f0);
		isOddTotal ^= ~ -blackCannotPut & ~ -whiteCannotPut & numEmptyCellsInQuadrant & 1;
		numEvenHolesBlackCannotPutOn += validityMask & ~isOdd & blackCannotPut;
		numEvenHolesWhiteCannotPutOn += validityMask & ~isOdd & whiteCannotPut;
		numOddHolesBlackCannotPutOn += validityMask & isOdd & blackCannotPut;
		numOddHolesWhiteCannotPutOn += validityMask & isOdd & whiteCannotPut;

		// fourth quadrant
		//    ........
		//    ........
		//    ........
		//    ........
		//    oooo....
		//    oooo....
		//    oooo....
		//    oooo.... = 0xf0f0f0f0
		//
		// make this quadrand invalid if there any empty square in
		//    ........
		//    ........
		//    ........
		//    ooooo... = 0x000000f8
		//    ooooo...
		//    ...oo...
		//    ...oo...
		//    ...oo... = 0xf8181818
		validityMask = 1 ^ Int64Util.oneIfNotZero32((e1 & 0x000000f8) | (e0 & 0xf8181818));
		validityMask &= Int64Util.oneIfNotZero32(e0 & 0xf0f0f0f0);
		numEmptyCellsInQuadrant = Int64Util.countBits32(e0 & 0xf0f0f0f0);
		isOdd = numEmptyCellsInQuadrant & 1;
		blackCannotPut = 1 ^ Int64Util.oneIfNotZero32(bm0 & 0xf0f0f0f0);
		whiteCannotPut = 1 ^ Int64Util.oneIfNotZero32(wm0 & 0xf0f0f0f0);
		isOddTotal ^= ~ -blackCannotPut & ~ -whiteCannotPut & numEmptyCellsInQuadrant & 1;
		numEvenHolesBlackCannotPutOn += validityMask & ~isOdd & blackCannotPut;
		numEvenHolesWhiteCannotPutOn += validityMask & ~isOdd & whiteCannotPut;
		numOddHolesBlackCannotPutOn += validityMask & isOdd & blackCannotPut;
		numOddHolesWhiteCannotPutOn += validityMask & isOdd & whiteCannotPut;

		features[c++] = (isOddTotal << 1) - 1; // (1, 0) -> (1, -1)
		features[c++] = numEvenHolesBlackCannotPutOn - numEvenHolesWhiteCannotPutOn;
		features[c++] = numOddHolesBlackCannotPutOn - numOddHolesWhiteCannotPutOn;

		var diskDiff:Int = b.numBlackWins();
		features[c++] = diskDiff;

		var cornerMask0:Int = (e0 & 0x00000001) << 9 | (e0 & 0x00000080) << 7;
		var cornerMask1:Int = (e1 & 0x80000000) >>> 9 | (e1 & 0x01000000) >>> 7;

		var xWithoutCornerDiff:Int = Int64Util.countBits64(b0 & cornerMask0, b1 & cornerMask1) - Int64Util.countBits64(w0 & cornerMask0, w1 & cornerMask1);
		var cornerDiff:Int = Int64Util.countBits64(b0 & 0x00000081, b1 & 0x81000000) - Int64Util.countBits64(w0 & 0x00000081, w1 & 0x81000000);

		features[c++] = xWithoutCornerDiff;
		features[c++] = cornerDiff;

		if (reversed) {
			b.reverseColors();
		}
	}
}
