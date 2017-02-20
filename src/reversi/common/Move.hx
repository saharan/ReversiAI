package reversi.common;

/**
 * ...
 */
class Move {
	public var turn:Int;
	public var xCoord:Int; // A-H
	public var yCoord:Int; // 1-8
	public var score:Float;

	public function new(turn:Int, xCoord:Int, yCoord:Int, score:Float) {
		this.turn = turn;
		this.xCoord = xCoord;
		this.yCoord = yCoord;
		this.score = score;
	}

}
