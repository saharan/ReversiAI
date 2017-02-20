package reversi.core;
import reversi.common.Int64Util;
import reversi.common.Turn;
import reversi.evaluation.Evaluator;
import reversi.search.MidGame;

/**
 * ...
 */
class RandomGame {
	public function new() {
	}

	/**
	 * returns a kifu of the game.
	 */
	public function runGame(numRandMoves:Int, etor:Evaluator):String {
		var b:Board = new Board();
		b.init();
		var turn:Int = Turn.BLACK;
		var kifu:String = "";
		var count:Int = 0;
		var lookahead:Int = 5;
		while (true) {
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
			if (m0 | m1 == 0) break; // the game is over
			var bestScore:Float = -1.0 / 0.0;
			var bestPos:Int = -1;
			var bestP0:Int = -1;
			var bestP1:Int = -1;
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
				var score:Float;
				if (count < numRandMoves) {
					score = Math.random();
				} else {
					score = MidGame.evaluateCurrent(etor, b, nextTurn, lookahead - 1, 14);
				}
				if (turn != nextTurn) {
					score = -score;
				}
				b.undo();
				if (score > bestScore) {
					bestScore = score;
					bestPos = pos;
					bestP0 = p0;
					bestP1 = p1;
				}
			} while (m0 | m1 != 0);
			kifu += "ABCDEFGH".charAt(~bestPos & 7) + "12345678".charAt(~bestPos >>> 3 & 7);
			if (count == numRandMoves - 1) kifu += " ";
			b.move(turn, bestPos, bestP0, bestP1);
			turn = Turn.nextTurn(turn, b);
			count++;
		}
		return kifu;
	}

}
