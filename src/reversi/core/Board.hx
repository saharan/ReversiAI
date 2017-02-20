package reversi.core;
import haxe.ds.Vector;
import reversi.common.Int64Util;
import reversi.common.Turn;

/**
 * Board
 */
class Board {
	public var black:Vector<Int>;
	public var white:Vector<Int>;
	public var blackMobility:Vector<Int>;
	public var whiteMobility:Vector<Int>;
	var stack:Vector<Int>;
	var tmp:Vector<Int>;
	var stackCount:Int;

	//   ABCDEFGH
	// 1 00000000 (32-25 bits of [1])
	// 2 00000000 (24-17 bits of [1])
	// 3 00000000 (16- 9 bits of [1])
	// 4 00000000 (8 - 1 bits of [1])
	// 5 00000000 (32-25 bits of [0])
	// 6 00000000 (24-17 bits of [0])
	// 7 00000000 (16- 9 bits of [0])
	// 8 00000000 (8 - 1 bits of [0])

	public function new() {
		black = new Vector<Int>(2);
		white = new Vector<Int>(2);
		blackMobility = new Vector<Int>(2);
		whiteMobility = new Vector<Int>(2);
		stackCount = 0;
		stack = new Vector<Int>(1024);
		tmp = new Vector<Int>(2);
	}

	public function init():Void {
		stackCount = 0;
		black[0] = 0x10000000;
		black[1] = 0x00000008;
		white[0] = 0x08000000;
		white[1] = 0x00000010;
		computeBlackMoility();
		computeWhiteMoility();
	}

	public function clear():Void {
		stackCount = 0;
		black[0] = 0;
		black[1] = 0;
		white[0] = 0;
		white[1] = 0;
		computeBlackMoility();
		computeWhiteMoility();
	}

	public inline function isBlack(x:Int, y:Int):Bool {
		return getBit(black, x, y) == 1;
	}

	public inline function isWhite(x:Int, y:Int):Bool {
		return getBit(white, x, y) == 1;
	}

	public inline function canPutBlack(x:Int, y:Int):Bool {
		return getBit(blackMobility, x, y) == 1;
	}

	public inline function canPutWhite(x:Int, y:Int):Bool {
		return getBit(whiteMobility, x, y) == 1;
	}

	public inline function putBlack(x:Int, y:Int):Void {
		push();
		var pos:Int = (y ^ 7) << 3 | (x ^ 7);
		computeFlip(black, white, pos, tmp);
		black[0] ^= tmp[0];
		black[1] ^= tmp[1];
		white[0] ^= tmp[0];
		white[1] ^= tmp[1];
		setBit(black, x, y);
	}

	public inline function putWhite(x:Int, y:Int):Void {
		push();
		var pos:Int = (y ^ 7) << 3 | (x ^ 7);
		computeFlip(white, black, pos, tmp);
		black[0] ^= tmp[0];
		black[1] ^= tmp[1];
		white[0] ^= tmp[0];
		white[1] ^= tmp[1];
		setBit(white, x, y);
	}

	public inline function setBlack(x:Int, y:Int):Void {
		setBit(black, x, y);
	}

	public inline function setWhite(x:Int, y:Int):Void {
		setBit(white, x, y);
	}

	public inline function removeBlack(x:Int, y:Int):Void {
		clearBit(black, x, y);
	}

	public inline function removeWhite(x:Int, y:Int):Void {
		clearBit(white, x, y);
	}

	@:extern
	public inline function reverseColors():Void {
		var tmp:Int;
		tmp = black[0];
		black[0] = white[0];
		white[0] = tmp;
		tmp = black[1];
		black[1] = white[1];
		white[1] = tmp;
		tmp = blackMobility[0];
		blackMobility[0] = whiteMobility[0];
		whiteMobility[0] = tmp;
		tmp = blackMobility[1];
		blackMobility[1] = whiteMobility[1];
		whiteMobility[1] = tmp;
	}

	@:extern
	public inline function computeBlackMoility():Void {
		computeMobility(black, white, blackMobility);
	}

	@:extern
	public inline function computeWhiteMoility():Void {
		computeMobility(white, black, whiteMobility);
	}

	@:extern
	public inline function move(turn:Int, pos:Int, p0:Int, p1:Int):Void {
		push();
		switch (turn) {
		case Turn.BLACK:
			computeFlip(black, white, pos, tmp);
			black[0] |= p0;
			black[1] |= p1;
		case Turn.WHITE:
			computeFlip(white, black, pos, tmp);
			white[0] |= p0;
			white[1] |= p1;
		}
		white[0] ^= tmp[0];
		white[1] ^= tmp[1];
		black[0] ^= tmp[0];
		black[1] ^= tmp[1];
	}

	@:extern
	public inline function undo():Void {
		pop();
	}

	@:extern
	public inline function redo():Void {
		stackCount += 4;
		black[0] = stack[stackCount];
		black[1] = stack[stackCount + 1];
		white[0] = stack[stackCount + 2];
		white[1] = stack[stackCount + 3];
	}

	@:extern
	public inline function push():Void {
		stack[stackCount] = black[0];
		stack[stackCount + 1] = black[1];
		stack[stackCount + 2] = white[0];
		stack[stackCount + 3] = white[1];
		stackCount += 4;
	}

	@:extern
	inline function pop():Void {
		stackCount -= 4;
		black[0] = stack[stackCount];
		black[1] = stack[stackCount + 1];
		white[0] = stack[stackCount + 2];
		white[1] = stack[stackCount + 3];
	}

	//@:extern
	public inline function numEmptySquares():Int {
		var n0:Int = ~(black[0] | white[0]);
		var n1:Int = ~(black[1] | white[1]);
		return Int64Util.countBits64(n0, n1);
	}

	//@:extern
	public inline function numBlackWins():Int {
		var numB:Int = Int64Util.countBits64(black[0], black[1]);
		var numW:Int = Int64Util.countBits64(white[0], white[1]);
		return numB - numW;
	}

	public inline function numBlacks():Int {
		return Int64Util.countBits64(black[0], black[1]);
	}

	public inline function numWhites():Int {
		return Int64Util.countBits64(white[0], white[1]);
	}

	/*
	@:extern
	public inline function getHorizontalBlack(n:Int):Int {
		return getHorizontal(black, n);
	}

	@:extern
	public inline function getHorizontalWhite(n:Int):Int {
		return getHorizontal(white, n);
	}

	@:extern
	public inline function getVerticalBlack(n:Int):Int {
		return getVertical(black, n);
	}

	@:extern
	public inline function getVerticalWhite(n:Int):Int {
		return getVertical(white, n);
	}

	@:extern
	public inline function getDiagonalRT2LBBlack(n:Int):Int {
		return getDiagonalRT2LB(black, n);
	}

	@:extern
	public inline function getDiagonalRT2LBWhite(n:Int):Int {
		return getDiagonalRT2LB(white, n);
	}

	@:extern
	public inline function getDiagonalLT2RBBlack(n:Int):Int {
		return getDiagonalLT2RB(black, n);
	}

	@:extern
	public inline function getDiagonalLT2RBWhite(n:Int):Int {
		return getDiagonalLT2RB(white, n);
	}
	*/

	/**
	 * returns [00000000 00000000 00000000 abcdefgh]
	 *
	 * 00000000
	 * 00000000
	 * 00000000
	 * abcdefgh - n'th
	 * 00000000
	 * 00000000
	 * 00000000
	 * 00000000 - 0'th
	 */
	//@:extern
	//inline function getHorizontal(black:Vector<Int>, n:Int):Int {
		//var r0:Int;
		//var r1:Int;
		//var b0:Int = black[0];
		//var b1:Int = black[1];
		//Int64Util.slr64(r0, r1, b0, b1, n << 3);
		//return r0 & 0xff;
	//}

	/**
	 * returns [00000000 00000000 00000000 abcdefgh]
	 *
	 * 0h000000
	 * 0g000000
	 * 0f000000
	 * 0e000000
	 * 0d000000
	 * 0c000000
	 * 0b000000
	 * 0a000000
	 *  |     |
	 *  n'th  0'th
	 */
	//@:extern
	//inline function getVertical(black:Vector<Int>, n:Int):Int {
		//var r0:Int;
		//var r1:Int;
		//var b0:Int = black[0];
		//var b1:Int = black[1];
		//Int64Util.slr64(r0, r1, b0, b1, n);
		//r0 &= 0x01010101;
		//r1 &= 0x01010101;
		//r0 *= 0x08040201;
		//r1 *= 0x08040201;
		//return r0 >>> 20 & 0xf0 | r1 >>> 24;
	//}

	/**
	 * returns [00000000 00000000 00000000 abcdefgh]
	 *
	 * 00c00000 - 0'th
	 * 0b000000
	 * a0000000
	 * 0000000h - n'th
	 * 000000g0
	 * 00000f00
	 * 0000e000
	 * 000d0000
	 */
	//@:extern
	//inline function getDiagonalRT2LB(black:Vector<Int>, n:Int):Int {
		//var r0:Int;
		//var r1:Int;
		//var s0:Int;
		//var s1:Int;
		//var b0:Int = black[0];
		//var b1:Int = black[1];
		//Int64Util.sll64(r0, r1, b0, b1, n << 3);
		//Int64Util.slr64(s0, s1, b0, b1, 64 - (n << 3));
		//var k:Int = -((n | -n) >>> 31);
		//r0 |= s0 & k;
		//r1 |= s1 & k;
		//r0 &= 0x10204080;
		//r1 &= 0x01020408;
		//r0 *= 0x01010101;
		//r1 *= 0x01010101;
		//return r0 >>> 24 | (r1 >>> 24 & 0x0f);
	//}

	/**
	 * returns [00000000 00000000 00000000 abcdefgh]
	 *
	 * 00c00000
	 * 000d0000
	 * 0000e000
	 * 00000f00
	 * 000000g0
	 * 0000000h - n'th
	 * a0000000
	 * 0b000000 - 0'th
	 */
	//@:extern
	//inline function getDiagonalLT2RB(black:Vector<Int>, n:Int):Int {
		//var r0:Int;
		//var r1:Int;
		//var s0:Int;
		//var s1:Int;
		//var b0:Int = black[0];
		//var b1:Int = black[1];
		//Int64Util.slr64(r0, r1, b0, b1, n << 3);
		//Int64Util.sll64(s0, s1, b0, b1, 64 - (n << 3));
		//var k:Int = -((n | -n) >>> 31);
		//r0 |= s0 & k;
		//r1 |= s1 & k;
		//r0 &= 0x08040201;
		//r1 &= 0x80402010;
		//r0 *= 0x01010101;
		//r1 *= 0x01010101;
		//return r0 >>> 24 | (r1 >>> 24 & 0xf0);
	//}

	@:extern
	inline function computeMobility(black:Vector<Int>, white:Vector<Int>, mobility:Vector<Int>):Void {
		var p0:Int;
		var p1:Int;
		var t0:Int;
		var t1:Int;

		var b0:Int = black[0];
		var b1:Int = black[1];
		var w0:Int = white[0];
		var w1:Int = white[1];

		// empty squares
		var e0:Int = ~(b0 | w0);
		var e1:Int = ~(b1 | w1);

		// mobilities
		var m0:Int = 0;
		var m1:Int = 0;

		// overflow
		var f:Int;

		// mask by 01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		p0 = 0x7e7e7e7e & w0;
		p1 = 0x7e7e7e7e & w1;

		// -- left --

		// potentially flippable disks
		t0 = p0 & b0 << 1;
		t0 |= p0 & t0 << 1;
		t0 |= p0 & t0 << 1;
		t0 |= p0 & t0 << 1;
		t0 |= p0 & t0 << 1;
		t0 |= p0 & t0 << 1;
		t1 = p1 & b1 << 1;
		t1 |= p1 & t1 << 1;
		t1 |= p1 & t1 << 1;
		t1 |= p1 & t1 << 1;
		t1 |= p1 & t1 << 1;
		t1 |= p1 & t1 << 1;
		// disks can only be put on empty squares
		m0 |= t0 << 1 & e0;
		m1 |= t1 << 1 & e1;

		// -- right --

		// potentially flippable disks
		t0 = p0 & b0 >>> 1;
		t0 |= p0 & t0 >>> 1;
		t0 |= p0 & t0 >>> 1;
		t0 |= p0 & t0 >>> 1;
		t0 |= p0 & t0 >>> 1;
		t0 |= p0 & t0 >>> 1;
		t1 = p1 & b1 >>> 1;
		t1 |= p1 & t1 >>> 1;
		t1 |= p1 & t1 >>> 1;
		t1 |= p1 & t1 >>> 1;
		t1 |= p1 & t1 >>> 1;
		t1 |= p1 & t1 >>> 1;
		// disks can only be put on empty squares
		m0 |= t0 >>> 1 & e0;
		m1 |= t1 >>> 1 & e1;

		// mask by 00000000
		//         11111111
		//         11111111
		//         11111111
		//         11111111
		//         11111111
		//         11111111
		//         00000000
		p0 = 0xffffff00 & w0;
		p1 = 0x00ffffff & w1;

		// -- top --

		// potentially flippable disks
		t0 = p0 & b0 << 8;
		t0 |= p0 & t0 << 8;
		t0 |= p0 & t0 << 8;
		f = t0 >>> 24; // overflow from 0 to 1
		t1 = p1 & (b1 << 8 | b0 >>> 24 | f);
		t1 |= p1 & (t1 << 8 | f);
		t1 |= p1 & (t1 << 8 | f);
		// disks can only be put on empty squares
		m0 |= t0 << 8 & e0;
		m1 |= (t1 << 8 | f) & e1;

		// -- bottom --

		// potentially flippable disks
		t1 = p1 & b1 >>> 8;
		t1 |= p1 & t1 >>> 8;
		t1 |= p1 & t1 >>> 8;
		f = t1 << 24; // overflow from 1 to 0
		t0 = p0 & (b0 >>> 8 | b1 << 24 | f);
		t0 |= p0 & (t0 >>> 8 | f);
		t0 |= p0 & (t0 >>> 8 | f);
		// disks can only be put on empty squares
		m0 |= (t0 >>> 8 | f) & e0;
		m1 |= t1 >>> 8 & e1;

		// mask by 00000000
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         01111110
		//         00000000
		p0 = 0x7e7e7e00 & w0;
		p1 = 0x007e7e7e & w1;

		// -- left top --

		// potentially flippable disks
		t0 = p0 & b0 << 9;
		t0 |= p0 & t0 << 9;
		t0 |= p0 & t0 << 9;
		f = t0 >>> 23; // overflow from 0 to 1
		t1 = p1 & (b1 << 9 | b0 >>> 23 | f);
		t1 |= p1 & (t1 << 9 | f);
		t1 |= p1 & (t1 << 9 | f);
		// disks can only be put on empty squares
		m0 |= t0 << 9 & e0;
		m1 |= (t1 << 9 | f) & e1;

		// -- right top --

		// potentially flippable disks
		t0 = p0 & b0 << 7;
		t0 |= p0 & t0 << 7;
		t0 |= p0 & t0 << 7;
		f = t0 >>> 25; // overflow from 0 to 1
		t1 = p1 & (b1 << 7 | b0 >>> 25 | f);
		t1 |= p1 & (t1 << 7 | f);
		t1 |= p1 & (t1 << 7 | f);
		// disks can only be put on empty squares
		m0 |= t0 << 7 & e0;
		m1 |= (t1 << 7 | f) & e1;

		// -- left bottom --

		// potentially flippable disks
		t1 = p1 & b1 >>> 7;
		t1 |= p1 & t1 >>> 7;
		t1 |= p1 & t1 >>> 7;
		f = t1 << 25; // overflow from 1 to 0
		t0 = p0 & (b0 >>> 7 | b1 << 25 | f);
		t0 |= p0 & (t0 >>> 7 | f);
		t0 |= p0 & (t0 >>> 7 | f);
		// disks can only be put on empty squares
		m0 |= (t0 >>> 7 | f) & e0;
		m1 |= t1 >>> 7 & e1;

		// -- right bottom --

		// potentially flippable disks
		t1 = p1 & b1 >>> 9;
		t1 |= p1 & t1 >>> 9;
		t1 |= p1 & t1 >>> 9;
		f = t1 << 23; // overflow from 1 to 0
		t0 = p0 & (b0 >>> 9 | b1 << 23 | f);
		t0 |= p0 & (t0 >>> 9 | f);
		t0 |= p0 & (t0 >>> 9 | f);
		// disks can only be put on empty squares
		m0 |= (t0 >>> 9 | f) & e0;
		m1 |= t1 >>> 9 & e1;

		mobility[0] = m0;
		mobility[1] = m1;
	}

	//@:extern
	inline function computeFlip(black:Vector<Int>, white:Vector<Int>, pos:Int, flip:Vector<Int>):Void {
		// outflank
		var o0:Int;
		var o1:Int;

		// mask
		var m0:Int;
		var m1:Int;

		// tmp
		var t:Int;

		var b0:Int = black[0];
		var b1:Int = black[1];
		var w0:Int = white[0];
		var w1:Int = white[1];

		// masked
		var wm0:Int = w0 & 0x7e7e7e7e;
		var wm1:Int = w1 & 0x7e7e7e7e;

		// flip
		var f0:Int = 0;
		var f1:Int = 0;

		// -- left --

		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 11111110
		Int64Util.sll32(m0, m1, 0x000000fe, pos);
		o0 = wm0 | ~m0;
		o1 = wm1 | ~m1;
		Int64Util.inc(o0, o1);
		o0 &= m0 & b0;
		o1 &= m1 & b1;
		// t = 0000...0 (o = 0)
		// t = 1111...1 (o != 0)
		t = o0 | o1;
		t = -((t | -t) >>> 31);
		Int64Util.dec(o0, o1);
		o0 &= t;
		o1 &= t;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- top --

		// 00000001
		// 00000001
		// 00000001
		// 00000001
		// 00000001
		// 00000001
		// 00000001
		// 00000000
		Int64Util.sll64(m0, m1, 0x01010100, 0x01010101, pos);
		o0 = w0 | ~m0; // need not mask only in top or bottom direction
		o1 = w1 | ~m1;
		Int64Util.inc(o0, o1);
		o0 &= m0 & b0;
		o1 &= m1 & b1;
		// t = 0000...0 (o = 0)
		// t = 1111...1 (o != 0)
		t = o0 | o1;
		t = -((t | -t) >>> 31);
		Int64Util.dec(o0, o1);
		o0 &= t;
		o1 &= t;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- left top --

		// 10000000
		// 01000000
		// 00100000
		// 00010000
		// 00001000
		// 00000100
		// 00000010
		// 00000000
		Int64Util.sll64(m0, m1, 0x08040200, 0x80402010, pos);
		o0 = wm0 | ~m0;
		o1 = wm1 | ~m1;
		Int64Util.inc(o0, o1);
		o0 &= m0 & b0;
		o1 &= m1 & b1;
		// t = 0000...0 (o = 0)
		// t = 1111...1 (o != 0)
		t = o0 | o1;
		t = -((t | -t) >>> 31);
		Int64Util.dec(o0, o1);
		o0 &= t;
		o1 &= t;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- right top --

		// 00000000
		// 00000010
		// 00000100
		// 00001000
		// 00010000
		// 00100000
		// 01000000
		// 10000000
		Int64Util.sll64(m0, m1, 0x10204080, 0x00020408, pos);
		o0 = wm0 | ~m0;
		o1 = wm1 | ~m1;
		Int64Util.inc(o0, o1);
		o0 &= m0 & b0;
		o1 &= m1 & b1;
		// t = 0000...0 (o = 0)
		// t = 1111...1 (o != 0)
		t = o0 | o1;
		t = -((t | -t) >>> 31);
		Int64Util.dec(o0, o1);
		o0 &= t;
		o1 &= t;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- right --

		// 01111111
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		// 00000000
		Int64Util.slr64(m0, m1, 0, 0x7f000000, 63 - pos);
		o0 = ~wm0 & m0;
		o1 = ~wm1 & m1;
		Int64Util.highestOneBit(o0, o1, o0, o1);
		o0 &= b0;
		o1 &= b1;
		Int64Util.neg(o0, o1);
		// << 1
		o1 = o1 << 1 | o0 >>> 31;
		o0 <<= 1;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- bottom --

		// 00000000
		// 10000000
		// 10000000
		// 10000000
		// 10000000
		// 10000000
		// 10000000
		// 10000000
		Int64Util.slr64(m0, m1, 0x80808080, 0x00808080, 63 - pos);
		o0 = ~w0 & m0; // need not mask only in top or bottom direction
		o1 = ~w1 & m1;
		Int64Util.highestOneBit(o0, o1, o0, o1);
		o0 &= b0;
		o1 &= b1;
		Int64Util.neg(o0, o1);
		// << 1
		o1 = o1 << 1 | o0 >>> 31;
		o0 <<= 1;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- right bottom --

		// 00000000
		// 01000000
		// 00100000
		// 00010000
		// 00001000
		// 00000100
		// 00000010
		// 00000001
		Int64Util.slr64(m0, m1, 0x08040201, 0x00402010, 63 - pos);
		o0 = ~wm0 & m0;
		o1 = ~wm1 & m1;
		Int64Util.highestOneBit(o0, o1, o0, o1);
		o0 &= b0;
		o1 &= b1;
		Int64Util.neg(o0, o1);
		// << 1
		o1 = o1 << 1 | o0 >>> 31;
		o0 <<= 1;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		// -- left bottom --

		// 00000001
		// 00000010
		// 00000100
		// 00001000
		// 00010000
		// 00100000
		// 01000000
		// 00000000
		Int64Util.slr64(m0, m1, 0x10204000, 0x01020408, 63 - pos);
		o0 = ~wm0 & m0;
		o1 = ~wm1 & m1;
		Int64Util.highestOneBit(o0, o1, o0, o1);
		o0 &= b0;
		o1 &= b1;
		Int64Util.neg(o0, o1);
		// << 1
		o1 = o1 << 1 | o0 >>> 31;
		o0 <<= 1;
		f0 |= o0 & m0;
		f1 |= o1 & m1;

		flip[0] = f0;
		flip[1] = f1;
	}

	public function print():Void {
		var str:String = "";
		str += "  ABCDEFGH\n";
		for (i in 0...8) {
			str += (i + 1) + " ";
			for (j in 0...8) {
				switch ([isBlack(j, i), isWhite(j, i)]) {
				case [false, false]:
					str += ".";
				case [true, false]:
					str += "B";
				case [false, true]:
					str += "W";
				case [true, true]:
					str += "?";
				}
			}
			str += "\n";
		}
		str += 'black[0] = ${black[0]}\n';
		str += 'black[1] = ${black[1]}\n';
		str += 'white[0] = ${white[0]}\n';
		str += 'white[1] = ${white[1]}\n';
		trace(str);
	}

	public function validate():Void {
		if (black[0] & white[0] | (black[1] & white[1]) != 0) {
			throw "invalid board";
		}
	}

	@:extern
	inline function getBit(board:Vector<Int>, x:Int, y:Int):Int {
		x ^= 7;
		y ^= 7;
		return (board[y >> 2] >>> (x | (y & 3) << 3)) & 1;
	}

	@:extern
	inline function setBit(board:Vector<Int>, x:Int, y:Int):Void {
		x ^= 7;
		y ^= 7;
		board[y >> 2] |= 1 << (x | (y & 3) << 3);
	}

	@:extern
	inline function clearBit(board:Vector<Int>, x:Int, y:Int):Void {
		x ^= 7;
		y ^= 7;
		board[y >> 2] &= ~(1 << (x | (y & 3) << 3));
	}

}
