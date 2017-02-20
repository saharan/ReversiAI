package reversi.evaluation;
import haxe.ds.Vector;

/**
 * ...
 */
class Teacher {
	public var features:Vector<Int>;
	public var score:Int;

	public function new(features:Vector<Int>, score:Int) {
		this.score = score;
		this.features = new Vector<Int>(Features.NUM_TOTAL_FEATURES);
		for (i in 0...Features.NUM_TOTAL_FEATURES) {
			this.features[i] = features[i];
		}
	}

}
