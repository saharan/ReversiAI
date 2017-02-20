package reversi.search;
import haxe.ds.Vector;
import reversi.common.Int64Util;
import reversi.common.Turn;
import reversi.core.Board;

/**
 * ...
 */
class EndGameSolver {
	static var transpositionTable:TranspositionTable = new TranspositionTable();
	static var count:Int;
	static var prevScore:Float = 0;

	public static function solve(b:Board, turn:Int):Float {
		//trace("begin endgame solve");
		count = 0;
		transpositionTable.clear();
		var height:Int = b.numEmptySquares();
		var score:Float;
		//score = solveNegaMaxWithTable(b, turn, -1.0 / 0.0, 1.0 / 0.0, height, false);
		score = solveNegaScoutWithTable(b, turn, -1.0 / 0.0, 1.0 / 0.0, height, false);
		//score = solveMTDf(b, turn, height, prevScore);
		prevScore = score;
		//trace('score = $score, count = $count, map used = ${transpositionTable.count()} out of ${TranspositionTable.NUM}');
		return score;
	}

	static function solveMTDf(b:Board, turn:Int, height:Int, f:Float):Float {
		var lower:Float = -1.0 / 0.0;
		var upper:Float = 1.0 / 0.0;
		var bound:Float = f;
		var score:Float = 0;
		while (lower < upper) {
			score = solveNegaMaxWithTable(b, turn, bound - 1, bound, height, false);
			if (score < bound) {
				upper = score;
			} else {
				lower = score;
			}
			if (lower == score) {
				bound = score + 1;
			} else {
				bound = score;
			}
		}
		return score;
	}

	static function solveNegaScoutWithTable(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		if (height < 6) return solveNegaMax(b, turn, alpha, beta, height, passedLast);
//trace('negamax with table searching... turn = $turn, height = $height, ($alpha, $beta)');
//b.print();

		count++;

		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var index:Int = TranspositionTable.index(b0, b1, w0, w1, turn);

		var value:Vector<Float> = transpositionTable.get(index, b0, b1, w0, w1, turn);
		var lower:Float = -1.0 / 0.0;
		var upper:Float = 1.0 / 0.0;
		if (value != null) {
			lower = value[0];
			upper = value[1];
			if (upper <= alpha) return upper; // fail-low
			if (lower >= beta) return lower; // fail-high
			if (lower == upper) return lower; // exact value
			// shrink window
			if (alpha < lower) alpha = lower;
			if (beta > upper) beta = upper;
		}

		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;

		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}

		var score:Float = -1.0 / 0.0;

		if (m0 | m1 == 0) { // pass
//trace('pass!');
			if (passedLast) { // leaf node
				score = evaluate(b) * sign;
//trace('leaf node. turn = $turn, score = $score');
				transpositionTable.set(index, b0, b1, w0, w1, turn, score, score); // set exact score
				return score;
			} else {
				score = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
//trace("mobility:");
//Int64Util.trace64(m0, m1);
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);
				var a:Float = score > alpha ? score : alpha;
				var newScore:Float;
				if (a == -1.0 / 0.0) {
					newScore = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -a, height - 1, false);
				} else {
					// null window search
					newScore = -solveNegaScoutWithTable(b, turn ^ 1, -(a + 1), -a, height - 1, false);
					if (newScore > a && newScore < beta) {
						// re-search
						newScore = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -a, height - 1, false);
					}
				}

				b.undo();

				if (newScore > score) {
					score = newScore;
					if (score >= beta) { // fail-high
						break;
					}
				}
			} while (m0 | m1 != 0);
		}

		if (score <= alpha) { // fail-low
			transpositionTable.set(index, b0, b1, w0, w1, turn, lower, score);
		} else if (score >= beta) { // fail-high
			transpositionTable.set(index, b0, b1, w0, w1, turn, score, upper);
		} else { // exact alpha-beta
			transpositionTable.set(index, b0, b1, w0, w1, turn, score, score);
		}
//trace('max score is $score');
		return score;
	}

	static function solveNegaMaxWithTable(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		if (height < 5) return solveNegaMax(b, turn, alpha, beta, height, passedLast);
//trace('negamax with table searching... turn = $turn, height = $height, ($alpha, $beta)');
//b.print();

		count++;

		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var index:Int = TranspositionTable.index(b0, b1, w0, w1, turn);

		var value:Vector<Float> = transpositionTable.get(index, b0, b1, w0, w1, turn);
		var lower:Float = -1.0 / 0.0;
		var upper:Float = 1.0 / 0.0;
		if (value != null) {
			lower = value[0];
			upper = value[1];
			if (upper <= alpha) return upper; // fail-low
			if (lower >= beta) return lower; // fail-high
			if (lower == upper) return lower; // exact value
			// shrink window
			if (alpha < lower) alpha = lower;
			if (beta > upper) beta = upper;
		}

		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;

		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}

		var score:Float = -1.0 / 0.0;

		if (m0 | m1 == 0) { // pass
//trace('pass!');
			if (passedLast) { // leaf node
				score = evaluate(b) * sign;
//trace('leaf node. turn = $turn, score = $score');
				transpositionTable.set(index, b0, b1, w0, w1, turn, score, score); // set exact score
				return score;
			} else {
				// cut if:
				//      score <=  alpha ||  score >= beta
				// <=> -score <= -beta || -score >= alpha
				score = -solveNegaMaxWithTable(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
	//trace("mobility:");
	//Int64Util.trace64(m0, m1);
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);

				// * in order to update the max score, the opponent's score must be lower than `-max(score, alpha)`
				// * this branch will be cut if the opponent's score is not greater than `-beta`
				// so the opponent's score must be in range of open interval (`-beta`, `-max(score, alpha)`)
				var newAlpha:Float = -beta;
				var newBeta:Float = -(score > alpha ? score : alpha);
				var newScore:Float = -solveNegaMaxWithTable(b, turn ^ 1, newAlpha, newBeta, height - 1, false);

				b.undo();
				if (newScore > score) {
					score = newScore;
					if (score >= beta) { // fail-high
//trace('fail-high');
						break;
					}
				}
			} while (m0 | m1 != 0);
		}

		if (score <= alpha) { // fail-low
			transpositionTable.set(index, b0, b1, w0, w1, turn, lower, score);
		} else if (score >= beta) { // fail-high
			transpositionTable.set(index, b0, b1, w0, w1, turn, score, upper);
		} else { // exact alpha-beta
			transpositionTable.set(index, b0, b1, w0, w1, turn, score, score);
		}

//trace('max score is $score');
		return score;
	}

	static function solveNegaMax(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		if (height <= 3) return solveNegaMax2(b, turn, alpha, beta, height, passedLast);

		count++;
		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;
		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				return evaluate(b) * sign;
			} else {
				return -solveNegaMax(b, turn ^ 1, -beta, -alpha, height, true);
			}
		}
		do {
			var p0:Int; // position
			var p1:Int;
			Int64Util.lowestOneBit(p0, p1, m0, m1);
			m0 ^= p0; // pop the bit
			m1 ^= p1;
			var t0:Int = p0;
			var t1:Int = p1;
			Int64Util.dec(t0, t1);
			var pos:Int = Int64Util.countBits64(t0, t1);
			b.move(turn, pos, p0, p1);
			var newScore:Float = -solveNegaMax(b, turn ^ 1, -beta, -alpha, height - 1, false);
			b.undo();
			if (newScore > alpha) {
				if (newScore >= beta) return newScore;
				alpha = newScore;
			}
		} while (m0 | m1 != 0);
		return alpha;
	}

	// ------------- for inline expansion

	static function solveNegaMax2(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		count++;
		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;
		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				alpha = evaluate(b) * sign;
			} else {
				alpha = -solveNegaMax3(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);
				var newScore:Float = -solveNegaMax3(b, turn ^ 1, -beta, -alpha, height - 1, false);
				b.undo();
				if (newScore > alpha) {
					alpha = newScore;
					if (newScore >= beta) break; // fail-high
				}
			} while (m0 | m1 != 0);
		}
		return alpha;
	}

	@:extern
	static inline function solveNegaMax3(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		count++;
		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;
		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				alpha = evaluate(b) * sign;
			} else {
				alpha = -solveNegaMax4(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);
				var newScore:Float = -solveNegaMax4(b, turn ^ 1, -beta, -alpha, height - 1, false);
				b.undo();
				if (newScore > alpha) {
					alpha = newScore;
					if (newScore >= beta) break; // fail-high
				}
			} while (m0 | m1 != 0);
		}
		return alpha;
	}

	@:extern
	static inline function solveNegaMax4(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		count++;
		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;
		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				alpha = evaluate(b) * sign;
			} else {
				alpha = -solveNegaMax5(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);
				var newScore:Float = -solveNegaMax5(b, turn ^ 1, -beta, -alpha, height - 1, false);
				b.undo();
				if (newScore > alpha) {
					alpha = newScore;
					if (newScore >= beta) break; // fail-high
				}
			} while (m0 | m1 != 0);
		}
		return alpha;
	}

	static function solveNegaMax5(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, passedLast:Bool):Float {
		count++;
		var m0:Int = 0; // mobility
		var m1:Int = 0;
		var sign:Int = 0;
		switch (turn) {
		case Turn.BLACK:
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			sign = 1;
		case Turn.WHITE:
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			sign = -1;
		}
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				alpha = evaluate(b) * sign;
			} else {
				alpha = -solveNegaMax5(b, turn ^ 1, -beta, -alpha, height, true);
			}
		} else {
			do {
				var p0:Int; // position
				var p1:Int;
				Int64Util.lowestOneBit(p0, p1, m0, m1);
				m0 ^= p0; // pop the bit
				m1 ^= p1;
				var t0:Int = p0;
				var t1:Int = p1;
				Int64Util.dec(t0, t1);
				var pos:Int = Int64Util.countBits64(t0, t1);
				b.move(turn, pos, p0, p1);
				var newScore:Float = -solveNegaMax5(b, turn ^ 1, -beta, -alpha, height - 1, false);
				b.undo();
				if (newScore > alpha) {
					alpha = newScore;
					if (newScore >= beta) break; // fail-high
				}
			} while (m0 | m1 != 0);
		}
		return alpha;
	}

	@:extern
	static inline function evaluate(b:Board):Float {
		return b.numBlackWins();
	}
}
