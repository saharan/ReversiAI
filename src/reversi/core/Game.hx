package reversi.core;
import reversi.common.Turn;
import reversi.evaluation.Learning;
import reversi.evaluation.Features;
import reversi.evaluation.Teacher;

/**
 * game data
 */
class Game {
	var b:Board;
	var nextTurns:Array<Int>;
	var putCount:Int;
	var score:Int;

	public function new() {
		b = new Board();
		putCount = 0;
		score = 0;
		nextTurns = [];
	}

	public static function parseKifu(kifu:String, onSucceeded:Void -> Void, putBlack:Int -> Int -> Void, putWhite:Int -> Int -> Void):Int {
		var b:Board = new Board();
		b.init();
		kifu = kifu.toUpperCase();
		var A:Int = "A".charCodeAt(0);
		var ONE:Int = "1".charCodeAt(0);
		var len:Int = kifu.length;
		if (len % 2 != 0) throw "invalid kifu";
		len >>= 1;
		var turn:Int = Turn.BLACK;
		var putData:Array<Int> = [];
		for (i in 0...len) {
			var x:Int = StringTools.fastCodeAt(kifu, i << 1) - A;
			var y:Int = StringTools.fastCodeAt(kifu, i << 1 | 1) - ONE;
			if (x < 0 || x > 7 || y < 0 || y > 7) throw "invalid kifu";
			if (turn == Turn.BLACK) {
				b.computeBlackMoility();
				if (b.blackMobility[0] | b.blackMobility[1] == 0) {
					turn ^= 1;
					b.computeWhiteMoility();
				}
			} else {
				b.computeWhiteMoility();
				if (b.whiteMobility[0] | b.whiteMobility[1] == 0) {
					turn ^= 1;
					b.computeBlackMoility();
				}
			}
			if (turn == Turn.BLACK) {
				if (!b.canPutBlack(x, y)) {
					throw 'black cannot put at ($x, $y)';
				}
				b.putBlack(x, y);
				putData.push(y << 3 | x | turn << 7);
			} else {
				if (!b.canPutWhite(x, y)) {
					throw 'white cannot put at ($x, $y)';
				}
				b.putWhite(x, y);
				putData.push(y << 3 | x | turn << 7);
			}
			turn ^= 1;
		}
		b.computeBlackMoility();
		b.computeWhiteMoility();
		onSucceeded();
		for (p in putData) {
			if (p >> 7 & 1 == Turn.BLACK) {
				putBlack(p & 7, p >> 3 & 7);
			} else {
				putWhite(p & 7, p >> 3 & 7);
			}
		}
		return b.numBlackWins();
	}

	public function loadKifu(kifu:String):Void {
		putCount = 0;
		b.init();
		kifu = kifu.toUpperCase();
		var A:Int = "A".charCodeAt(0);
		var ONE:Int = "1".charCodeAt(0);
		var len:Int = kifu.length;
		if (len % 2 != 0) throw "!?";
		len >>= 1;
		var turn:Int = Turn.BLACK;
		nextTurns = [];
		for (i in 0...len) {
			var x:Int = StringTools.fastCodeAt(kifu, i << 1) - A;
			var y:Int = StringTools.fastCodeAt(kifu, i << 1 | 1) - ONE;
			if (turn == Turn.BLACK) {
				b.computeBlackMoility();
				if (b.blackMobility[0] | b.blackMobility[1] == 0) {
					turn ^= 1;
					b.computeWhiteMoility();
				}
			} else {
				b.computeWhiteMoility();
				if (b.whiteMobility[0] | b.whiteMobility[1] == 0) {
					turn ^= 1;
					b.computeBlackMoility();
				}
			}
			nextTurns.push(turn);
			if (turn == Turn.BLACK) {
				if (!b.canPutBlack(x, y)) {
					throw 'black cannot put at ($x, $y)';
				}
				b.putBlack(x, y);
			} else {
				if (!b.canPutWhite(x, y)) {
					throw 'white cannot put at ($x, $y)';
				}
				b.putWhite(x, y);
			}
			putCount++;
			turn ^= 1;
		}
		nextTurns.push(Turn.BLACK);

		b.computeBlackMoility();
		b.computeWhiteMoility();
		//if (b.blackMobility[0] | b.blackMobility[1] | b.whiteMobility[0] | b.whiteMobility[1] != 0) {
			//throw "game did not end";
		//}
		score = b.numBlackWins();
	}

	public function addTeachers(learning:Learning, from:Int, to:Int):Void {
		if (to > putCount) to = putCount;

		from = putCount - from;
		to = putCount - to;

		var numUndo:Int = 0;

		while (to > 0) {
			b.undo();
			to--;
			from--;
			numUndo++;
		}
		while (from >= 0) {
//b.print();
			var turn:Int = nextTurns[putCount - numUndo];
			Features.extract(b, turn);
			var teacher:Teacher = new Teacher(Features.features, turn == Turn.BLACK ? score : -score);
			learning.addTeacher(teacher);
			b.undo();
			from--;
			numUndo++;
		}
		while (numUndo > 0) {
			b.redo();
			numUndo--;
		}
	}

}
