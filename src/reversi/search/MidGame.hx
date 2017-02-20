package reversi.search;
import haxe.ds.Vector;
import reversi.common.Int64Util;
import reversi.common.Move;
import reversi.common.Turn;
import reversi.core.Board;
import reversi.evaluation.Evaluator;

/**
 * ...
 */
class MidGame {
	static var transpositionTable:TranspositionTable = new TranspositionTable();
	static var etor:Evaluator;
	static var count:Int;

	static inline var INF:Float = 1e200;

	// for move-ordering
	static var posList:Vector<Int> = new Vector<Int>(64 * 60);
	static var posValueList:Vector<Int> = new Vector<Int>(64 * 60);
	static var posStackCount:Int;

	//static var prevScore:Vector<Float>;

	public static inline var LOOKAHEAD_MAX_DEPTH:Int = 60;

	public static function evaluateMoves(etor:Evaluator, b:Board, turn:Int, lookahead:Int, lookaheadExact:Int):Array<Move> {
		var m0:Int;
		var m1:Int;
		if (turn == Turn.BLACK) {
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
		} else {
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
		}
		if (m0 | m1 == 0) return [];
		var moves:Array<Move> = [];
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
			var nextTurn:Int = Turn.nextTurn(turn, b);
			var score:Float = evaluateCurrent(etor, b, nextTurn, lookahead - 1, lookaheadExact - 1);
			if (turn != nextTurn) {
				score = -score;
			}
			moves.push(new Move(turn, ~pos & 7, ~pos >>> 3 & 7, score));
			b.undo();
		} while (m0 | m1 != 0);
		return moves;
	}

	public static function evaluateCurrent(etor:Evaluator, b:Board, turn:Int, lookahead:Int, lookaheadExact:Int):Float {
		MidGame.etor = etor;
		var height:Int = b.numEmptySquares();
		var score:Float;
		count = 0;
		posStackCount = 0;
		if (height <= lookaheadExact) {
			lookahead = LOOKAHEAD_MAX_DEPTH;
			score = solveNegaScoutWithTable(b, turn, -INF, INF, height, lookahead, 0, false);
		} else if (lookahead >= 5) {
			score = solveNegaMax(b, turn, -INF, INF, height, lookahead - 4, false);
			score = solveMTDf(b, turn, height, lookahead, score);
		} else {
			score = solveNegaMax(b, turn, -INF, INF, height, lookahead, false);
		}
		//trace('score = $score, count = $count, map used = ${transpositionTable.count()} out of ${TranspositionTable.NUM}');
		return score;
	}

	static function solveMTDf(b:Board, turn:Int, height:Int, lookahead:Int, f:Float):Float {
		var lower:Float = -1.0 / 0.0;
		var upper:Float = 1.0 / 0.0;
		var bound:Float = f;
		var score:Float = 0;
		while (lower < upper) {
			score = solveNegaMaxMoveOrderingTable(b, turn, bound - 1, bound, height, lookahead, false);
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

	static function solveNegaScoutWithTable(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, lookahead:Int, depth:Int, passedLast:Bool):Float {
		if (lookahead == LOOKAHEAD_MAX_DEPTH - 1) lookahead = LOOKAHEAD_MAX_DEPTH;
		if (height < 6) return solveNegaMax(b, turn, alpha, beta, height, lookahead, passedLast);

		count++;

		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var turnAndLookahead:Int = turn == Turn.BLACK ? lookahead + 1 : -(lookahead + 1);
		var index:Int = TranspositionTable.index(b0, b1, w0, w1, turnAndLookahead);

		var value:Vector<Float> = transpositionTable.get(index, b0, b1, w0, w1, turnAndLookahead);
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

		var bestScore:Float = -1.0 / 0.0;

		if (lookahead == 0) { // leaf node
			bestScore = etor.evaluate(b, turn);
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, bestScore, bestScore); // set exact score
			return bestScore;
		}

		var posFrom:Int = posStackCount;
		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				bestScore = evaluate(b) * sign;
				transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, bestScore, bestScore); // set exact score
				return bestScore;
			} else {
				bestScore = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -alpha, height, lookahead, depth, true);
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
				// fast-first search
				// counting the opponents' mobility
				if (turn == Turn.BLACK) {
					b.computeWhiteMoility();
					posValueList[posStackCount] = -Int64Util.countBits64(b.whiteMobility[0], b.whiteMobility[1]);
				} else {
					b.computeBlackMoility();
					posValueList[posStackCount] = -Int64Util.countBits64(b.blackMobility[0], b.blackMobility[1]);
				}
				b.undo();
				posList[posStackCount++] = pos;
			} while (m0 | m1 != 0);

			// insertion sort (descending)
			for (i in posFrom + 1...posStackCount) {
				var val:Int = posValueList[i];
				var pos:Int = posList[i];
				var j:Int = i;
				while (j > posFrom && posValueList[j - 1] < val) {
					posValueList[j] = posValueList[j - 1];
					posList[j] = posList[j - 1];
					j--;
				}
				posValueList[j] = val;
				posList[j] = pos;
			}

			do { // first search
				// compute position data
				var pos:Int = posList[posFrom];
				var p0:Int;
				var p1:Int;
				Int64Util.sll32(p0, p1, 1, pos);

				b.move(turn, pos, p0, p1);
				bestScore = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -alpha, height - 1, lookahead - 1, depth + 1, false);
				b.undo();

				if (bestScore >= beta) { // fail-high
					break;
				}

				for (i in posFrom + 1...posStackCount) {
					// compute position data
					pos = posList[i];
					Int64Util.sll32(p0, p1, 1, pos);

					var upper:Float = bestScore > alpha ? bestScore : alpha;

					b.move(turn, pos, p0, p1);
					// null window search
					var score:Float = -solveNegaScoutWithTable(b, turn ^ 1, -(upper + 1), -upper, height - 1, lookahead - 1, depth + 1, false);
					if (score > upper && score < beta) {
						// re-search
						score = -solveNegaScoutWithTable(b, turn ^ 1, -beta, -upper, height - 1, lookahead - 1, depth + 1, false);
					}
					b.undo();


					if (score > bestScore) {
						bestScore = score;
						if (bestScore >= beta) { // fail-high
							break;
						}
					}
				}
			} while (false);
		}

		posStackCount = posFrom; // pop

		if (bestScore <= alpha) { // fail-low
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, lower, bestScore);
		} else if (bestScore >= beta) { // fail-high
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, bestScore, upper);
		} else { // exact alpha-beta
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, bestScore, bestScore);
		}
		return bestScore;
	}

	static function solveNegaMax(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, lookahead:Int, passedLast:Bool):Float {
		if (height == 1) return solveNegaMaxLastMove(b, turn, passedLast);
		if (lookahead == LOOKAHEAD_MAX_DEPTH - 1) lookahead = LOOKAHEAD_MAX_DEPTH;

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
		if (lookahead == 0) { // leaf node
			return etor.evaluate(b, turn);
		}

		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				return evaluate(b) * sign;
			} else {
				return -solveNegaMax(b, turn ^ 1, -beta, -alpha, height, lookahead, true);
			}
		}
		var first:Bool = true;
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
			var newScore:Float = -solveNegaMax(b, turn ^ 1, -beta, -alpha, height - 1, lookahead - 1, false);
			b.undo();
			if (first) {
				first = false;
				if (newScore >= beta) return newScore;
				alpha = newScore;
			} else if (newScore > alpha) {
				if (newScore >= beta) return newScore;
				alpha = newScore;
			}
		} while (m0 | m1 != 0);
		return alpha;
	}

	static function solveNegaMaxLastMove(b:Board, turn:Int, passedLast:Bool):Float {
		count++;
		var m0:Int = 0;
		var m1:Int = 0;
		if (turn == Turn.BLACK) {
			b.computeBlackMoility();
			m0 = b.blackMobility[0];
			m1 = b.blackMobility[1];
			if (m0 | m1 == 0) { // pass
				if (passedLast) { // leaf node
					return evaluate(b);
				} else {
					return -solveNegaMaxLastMove(b, Turn.WHITE, true);
				}
			}
			var t0:Int = m0;
			var t1:Int = m1;
			Int64Util.dec(t0, t1);
			var pos:Int = Int64Util.countBits64(t0, t1);
			b.move(turn, pos, m0, m1);
			var score:Float = evaluate(b);
			b.undo();
			return score;
		} else {
			b.computeWhiteMoility();
			m0 = b.whiteMobility[0];
			m1 = b.whiteMobility[1];
			if (m0 | m1 == 0) { // pass
				if (passedLast) { // leaf node
					return -evaluate(b);
				} else {
					return -solveNegaMaxLastMove(b, Turn.BLACK, true);
				}
			}
			var t0:Int = m0;
			var t1:Int = m1;
			Int64Util.dec(t0, t1);
			var pos:Int = Int64Util.countBits64(t0, t1);
			b.move(turn, pos, m0, m1);
			var score:Float = -evaluate(b);
			b.undo();
			return score;
		}
	}

	static function solveNegaMaxMoveOrdering(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, lookahead:Int, passedLast:Bool):Float {
		if (lookahead == LOOKAHEAD_MAX_DEPTH - 1) lookahead = LOOKAHEAD_MAX_DEPTH;
		if (height < 6) return solveNegaMax(b, turn, alpha, beta, height, lookahead, passedLast);

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
		if (lookahead == 0) {
			return etor.evaluate(b, turn);
		}

		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				return evaluate(b) * sign;
			} else {
				return -solveNegaMaxMoveOrdering(b, turn ^ 1, -beta, -alpha, height, lookahead, true);
			}
		}

		var posFrom:Int = posStackCount;
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

			var posIndex:Int = posStackCount;
			posList[posIndex] = pos;

			// count the opponents' mobility
			b.move(turn, pos, p0, p1);
			if (turn == Turn.BLACK) {
				b.computeWhiteMoility();
				posValueList[posIndex] = Int64Util.countBits64(b.whiteMobility[0], b.whiteMobility[1]);
			} else {
				b.computeBlackMoility();
				posValueList[posIndex] = Int64Util.countBits64(b.blackMobility[0], b.blackMobility[1]);
			}

			b.undo();
			posStackCount++;
		} while (m0 | m1 != 0);

		// insertion sort
		for (i in posFrom + 1...posStackCount) {
			var val:Int = posValueList[i];
			var pos:Int = posList[i];
			var j:Int = i;
			while (j > posFrom && posValueList[j - 1] > val) {
				posValueList[j] = posValueList[j - 1];
				posList[j] = posList[j - 1];
				j--;
			}
			posValueList[j] = val;
			posList[j] = pos;
		}

		for (i in posFrom...posStackCount) {
			var pos:Int = posList[i];
			var p0:Int; // position
			var p1:Int;
			Int64Util.sll32(p0, p1, 1, posList[i]);
			b.move(turn, pos, p0, p1);
			var newScore:Float = -solveNegaMaxMoveOrdering(b, turn ^ 1, -beta, -alpha, height - 1, lookahead - 1, false);
			b.undo();
			if (newScore > alpha) {
				if (newScore >= beta) {
					// pop the stack
					posStackCount = posFrom;
					return newScore;
				}
				alpha = newScore;
			}
		}
		// pop the stack
		posStackCount = posFrom;
		return alpha;
	}

	static function solveNegaMaxMoveOrderingTable(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, lookahead:Int, passedLast:Bool):Float {
		if (lookahead == LOOKAHEAD_MAX_DEPTH - 1) lookahead = LOOKAHEAD_MAX_DEPTH;
		if (height < 6) return solveNegaMax(b, turn, alpha, beta, height, lookahead, passedLast);

		count++;

		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var turnAndLookahead:Int = turn == Turn.BLACK ? lookahead + 1 : -(lookahead + 1);
		var index:Int = TranspositionTable.index(b0, b1, w0, w1, turnAndLookahead);

		var value:Vector<Float> = transpositionTable.get(index, b0, b1, w0, w1, turnAndLookahead);
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

		if (lookahead == 0) { // leaf node
			score = etor.evaluate(b, turn);
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score); // set exact score
			return score;
		}

		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				score = evaluate(b) * sign;
				transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score); // set exact score
				return score;
			} else {
				// cut if:
				//      score <=  alpha ||  score >= beta
				// <=> -score <= -beta || -score >= alpha
				score = -solveNegaMaxMoveOrderingTable(b, turn ^ 1, -beta, -alpha, height, lookahead, true);
			}
		} else {
			var posFrom:Int = posStackCount;
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

				var posIndex:Int = posStackCount;
				posList[posIndex] = pos;

				// count the opponents' mobility
				b.move(turn, pos, p0, p1);
				if (turn == Turn.BLACK) {
					b.computeWhiteMoility();
					posValueList[posIndex] = Int64Util.countBits64(b.whiteMobility[0], b.whiteMobility[1]);
				} else {
					b.computeBlackMoility();
					posValueList[posIndex] = Int64Util.countBits64(b.blackMobility[0], b.blackMobility[1]);
				}

				b.undo();
				posStackCount++;
			} while (m0 | m1 != 0);

			// insertion sort
			for (i in posFrom + 1...posStackCount) {
				var val:Int = posValueList[i];
				var pos:Int = posList[i];
				var j:Int = i;
				while (j > posFrom && posValueList[j - 1] > val) {
					posValueList[j] = posValueList[j - 1];
					posList[j] = posList[j - 1];
					j--;
				}
				posValueList[j] = val;
				posList[j] = pos;
			}

			for (i in posFrom...posStackCount) {
				var pos:Int = posList[i];
				var p0:Int; // position
				var p1:Int;
				Int64Util.sll32(p0, p1, 1, posList[i]);
				b.move(turn, pos, p0, p1);

				// * in order to update the max score, the opponent's score must be lower than `-max(score, alpha)`
				// * this branch will be cut if the opponent's score is not greater than `-beta`
				// so the opponent's score must be in range of open interval (`-beta`, `-max(score, alpha)`)
				var newAlpha:Float = -beta;
				var newBeta:Float = -(score > alpha ? score : alpha);
				var newScore:Float = -solveNegaMaxMoveOrderingTable(b, turn ^ 1, newAlpha, newBeta, height - 1, lookahead - 1, false);

				b.undo();
				if (newScore > score) {
					score = newScore;
					if (score >= beta) { // fail-high
						break;
					}
				}
			}
			// pop the stack
			posStackCount = posFrom;
		}

		if (score <= alpha) { // fail-low
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, lower, score);
		} else if (score >= beta) { // fail-high
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, upper);
		} else { // exact alpha-beta
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score);
		}
		return score;
	}

	static function solveNegaMaxWithTable(b:Board, turn:Int, alpha:Float, beta:Float, height:Int, lookahead:Int, passedLast:Bool):Float {
		if (lookahead == LOOKAHEAD_MAX_DEPTH - 1) lookahead = LOOKAHEAD_MAX_DEPTH;
		if (height < 6 || lookahead < 3) return solveNegaMax(b, turn, alpha, beta, height, lookahead, passedLast);

		count++;

		var b0:Int = b.black[0];
		var b1:Int = b.black[1];
		var w0:Int = b.white[0];
		var w1:Int = b.white[1];
		var turnAndLookahead:Int = turn == Turn.BLACK ? lookahead + 1 : -(lookahead + 1);
		var index:Int = TranspositionTable.index(b0, b1, w0, w1, turnAndLookahead);

		var value:Vector<Float> = transpositionTable.get(index, b0, b1, w0, w1, turnAndLookahead);
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

		if (lookahead == 0) { // leaf node
			score = etor.evaluate(b, turn);
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score); // set exact score
			return score;
		}

		if (m0 | m1 == 0) { // pass
			if (passedLast) { // leaf node
				score = evaluate(b) * sign;
				transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score); // set exact score
				return score;
			} else {
				// cut if:
				//      score <=  alpha ||  score >= beta
				// <=> -score <= -beta || -score >= alpha
				score = -solveNegaMaxWithTable(b, turn ^ 1, -beta, -alpha, height, lookahead, true);
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

				// * in order to update the max score, the opponent's score must be lower than `-max(score, alpha)`
				// * this branch will be cut if the opponent's score is not greater than `-beta`
				// so the opponent's score must be in range of open interval (`-beta`, `-max(score, alpha)`)
				var newAlpha:Float = -beta;
				var newBeta:Float = -(score > alpha ? score : alpha);
				var newScore:Float = -solveNegaMaxWithTable(b, turn ^ 1, newAlpha, newBeta, height - 1, lookahead - 1, false);

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
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, lower, score);
		} else if (score >= beta) { // fail-high
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, upper);
		} else { // exact alpha-beta
			transpositionTable.set(index, b0, b1, w0, w1, turnAndLookahead, score, score);
		}
		return score;
	}

	@:extern
	static inline function evaluate(b:Board):Float {
		if (b.black[0] | b.black[1] == 0) return -64;
		if (b.white[0] | b.white[1] == 0) return 64;
		return b.numBlackWins();
	}
}
