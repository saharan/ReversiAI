package reversi.common;
import haxe.ds.Vector;
import reversi.core.Board;

/**
 * ...
 */
class Turn {
	public static inline var BLACK:Int = 0;
	public static inline var WHITE:Int = 1;

	public static inline function nextTurn(currentTurn:Int, afterCurrentMove:Board):Int {
		var b:Board = afterCurrentMove;
		var opponentsMobility:Vector<Int>;
		if (currentTurn == BLACK) {
			b.computeWhiteMoility();
			opponentsMobility = b.whiteMobility;
		} else {
			b.computeBlackMoility();
			opponentsMobility = b.blackMobility;
		}
		if (opponentsMobility[0] | opponentsMobility[1] == 0) {
			// the opponent passes
			return currentTurn;
		}
		return currentTurn ^ 1;
	}
}
