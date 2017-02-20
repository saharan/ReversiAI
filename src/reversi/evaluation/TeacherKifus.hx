package reversi.evaluation;
import haxe.ds.Vector;
import reversi.core.Game;

/**
 * ...
 */
class TeacherKifus {
	static var games:Vector<Game>;
	static var numGames:Int;

	public static function loadGames(kifus:Array<String>, max:Int):Void {
		if (max > 500000) throw "too many games";
		games = new Vector<Game>(500000);
		var i:Int = 0;
		for (kifu in kifus) {
			if (i == max) break;
			var g:Game = new Game();
			try {
				g.loadKifu(kifu);
			} catch (e:Any) {
				trace("invalid kifu: " + kifu);
			}
			if (i % 1000 == 0) {
				trace("created game: i=" + i);
			}
			games[i++] = g;
		}
		numGames = i;
		trace('created $numGames games');
	}

	public static function createTeachers(learning:Learning, from:Int, to:Int):Void {
		for (i in 0...numGames) {
			games[i].addTeachers(learning, from, to);
			if (i % 1000 == 0) {
				trace("added teacher data: i=" + i);
			}
		}
	}

	public static function createGamesAndTeachers(learning:Learning, kifus:Array<String>, max:Int, from:Int, to:Int):Void {
		var g:Game = new Game();
		var i:Int = 0;
		for (kifu in kifus) {
			if (i == max) break;
			try {
				g.loadKifu(kifu);
			} catch (e:Any) {
				trace("invalid kifu: " + kifu);
			}
			g.addTeachers(learning, from, to);
			if (i % 1000 == 0) {
				trace("created teacher data: i=" + i);
			}
			i++;
		}
	}

}
