package reversi.evaluation;
import haxe.ds.Vector;
import reversi.common.Turn;
import reversi.core.Board;

/**
 * ...
 * @author saharan
 */
class Evaluator {
	var weights:Vector<Vector<Float>>;
	var numPatterns:Int;
	var numFeatures:Int;

	public function new(numPatterns:Int) {
		this.numPatterns = numPatterns;
		numFeatures = numPatterns + Features.NUM_NON_PATTERN_FEATURES;
		weights = new Vector<Vector<Float>>(10);
		for (i in 0...10) {
			weights[i] = new Vector<Float>(numFeatures);
		}
	}

	public function load(stage:Int, copyFrom:Array<Float>):Void {
		for (i in 0...numFeatures) {
			weights[stage][i] = copyFrom[i];
			if (Math.isNaN(copyFrom[i] + 0.0)) {
				trace("weight of feature index " + i + " is NaN!");
				weights[stage][i] = 0;
			}
		}
	}

	public function evaluate(b:Board, turn:Int):Float {
		if (b.black[0] | b.black[1] == 0) {
			return turn == Turn.BLACK ? -64 : 64;
		}
		if (b.white[0] | b.white[1] == 0) {
			return turn == Turn.WHITE ? -64 : 64;
		}

		var e:Int = b.numEmptySquares();
		var stage:Int = 9 - Std.int(e / 6);
		Features.extract(b, turn);
		var features:Vector<Int> = Features.features;
		var score:Float = 0;
		for (i in 0...Features.NUM_PATTERN_FEATURES) {
			score += weights[stage][features[i]];
			if (features[i] > 0 && weights[stage][features[i]] == 0) { // not-appeared pattern
				//score -= 5;
			}
		}
		var idx:Int = numPatterns;
		for (i in Features.NUM_PATTERN_FEATURES...Features.NUM_TOTAL_FEATURES) {
			score += weights[stage][idx++] * features[i];
		}
		return score;
	}

	public function evaluateAndTrace(b:Board, turn:Int):Float {
		var e:Int = b.numEmptySquares();
		var stage:Int = 9 - Std.int(e / 6);
		if (stage < 0) stage = 0;
		Features.extract(b, turn);
		var features:Vector<Int> = Features.features;
		var score:Float = 0;
		var patterns = [ // see Features.extract
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"oooooooo\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"oooooooo\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"oooooooo\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"oooooooo\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"oooooooo\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"oooooooo\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"......o.\n" +
			"......o.\n" +
			"......o.\n" +
			"......o.\n" +
			"......o.\n" +
			"......o.\n" +
			"......o.\n" +
			"......o.",
			".....o..\n" +
			".....o..\n" +
			".....o..\n" +
			".....o..\n" +
			".....o..\n" +
			".....o..\n" +
			".....o..\n" +
			".....o..",
			"....o...\n" +
			"....o...\n" +
			"....o...\n" +
			"....o...\n" +
			"....o...\n" +
			"....o...\n" +
			"....o...\n" +
			"....o...",
			"...o....\n" +
			"...o....\n" +
			"...o....\n" +
			"...o....\n" +
			"...o....\n" +
			"...o....\n" +
			"...o....\n" +
			"...o....",
			"..o.....\n" +
			"..o.....\n" +
			"..o.....\n" +
			"..o.....\n" +
			"..o.....\n" +
			"..o.....\n" +
			"..o.....\n" +
			"..o.....",
			".o......\n" +
			".o......\n" +
			".o......\n" +
			".o......\n" +
			".o......\n" +
			".o......\n" +
			".o......\n" +
			".o......",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			".......o\n" +
			"......o.\n" +
			".....o..\n" +
			"....o...",
			"........\n" +
			"........\n" +
			"........\n" +
			".......o\n" +
			"......o.\n" +
			".....o..\n" +
			"....o...\n" +
			"...o....",
			"........\n" +
			"........\n" +
			".......o\n" +
			"......o.\n" +
			".....o..\n" +
			"....o...\n" +
			"...o....\n" +
			"..o.....",
			"........\n" +
			".......o\n" +
			"......o.\n" +
			".....o..\n" +
			"....o...\n" +
			"...o....\n" +
			"..o.....\n" +
			".o......",
			".......o\n" +
			"......o.\n" +
			".....o..\n" +
			"....o...\n" +
			"...o....\n" +
			"..o.....\n" +
			".o......\n" +
			"o.......",
			"......o.\n" +
			".....o..\n" +
			"....o...\n" +
			"...o....\n" +
			"..o.....\n" +
			".o......\n" +
			"o.......\n" +
			"........",
			".....o..\n" +
			"....o...\n" +
			"...o....\n" +
			"..o.....\n" +
			".o......\n" +
			"o.......\n" +
			"........\n" +
			"........",
			"....o...\n" +
			"...o....\n" +
			"..o.....\n" +
			".o......\n" +
			"o.......\n" +
			"........\n" +
			"........\n" +
			"........",
			"...o....\n" +
			"..o.....\n" +
			".o......\n" +
			"o.......\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"o.......\n" +
			".o......\n" +
			"..o.....\n" +
			"...o....",
			"........\n" +
			"........\n" +
			"........\n" +
			"o.......\n" +
			".o......\n" +
			"..o.....\n" +
			"...o....\n" +
			"....o...",
			"........\n" +
			"........\n" +
			"o.......\n" +
			".o......\n" +
			"..o.....\n" +
			"...o....\n" +
			"....o...\n" +
			".....o..",
			"........\n" +
			"o.......\n" +
			".o......\n" +
			"..o.....\n" +
			"...o....\n" +
			"....o...\n" +
			".....o..\n" +
			"......o.",
			"o.......\n" +
			".o......\n" +
			"..o.....\n" +
			"...o....\n" +
			"....o...\n" +
			".....o..\n" +
			"......o.\n" +
			".......o",
			".o......\n" +
			"..o.....\n" +
			"...o....\n" +
			"....o...\n" +
			".....o..\n" +
			"......o.\n" +
			".......o\n" +
			"........",
			"..o.....\n" +
			"...o....\n" +
			"....o...\n" +
			".....o..\n" +
			"......o.\n" +
			".......o\n" +
			"........\n" +
			"........",
			"...o....\n" +
			"....o...\n" +
			".....o..\n" +
			"......o.\n" +
			".......o\n" +
			"........\n" +
			"........\n" +
			"........",
			"....o...\n" +
			".....o..\n" +
			"......o.\n" +
			".......o\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			".o....o.\n" +
			"oooooooo",
			".......o\n" +
			"......oo\n" +
			".......o\n" +
			".......o\n" +
			".......o\n" +
			".......o\n" +
			"......oo\n" +
			".......o",
			"oooooooo\n" +
			".o....o.\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"o.......\n" +
			"oo......\n" +
			"o.......\n" +
			"o.......\n" +
			"o.......\n" +
			"o.......\n" +
			"oo......\n" +
			"o.......",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"...ooooo\n" +
			"...ooooo",
			"........\n" +
			"........\n" +
			"........\n" +
			"......oo\n" +
			"......oo\n" +
			"......oo\n" +
			"......oo\n" +
			"......oo",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"ooooo...\n" +
			"ooooo...",
			"......oo\n" +
			"......oo\n" +
			"......oo\n" +
			"......oo\n" +
			"......oo\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"oo......\n" +
			"oo......\n" +
			"oo......\n" +
			"oo......\n" +
			"oo......",
			"...ooooo\n" +
			"...ooooo\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"oo......\n" +
			"oo......\n" +
			"oo......\n" +
			"oo......\n" +
			"oo......\n" +
			"........\n" +
			"........\n" +
			"........",
			"ooooo...\n" +
			"ooooo...\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			".....ooo\n" +
			".....ooo\n" +
			".....ooo",
			".....ooo\n" +
			".....ooo\n" +
			".....ooo\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"ooo.....\n" +
			"ooo.....\n" +
			"ooo.....",
			"ooo.....\n" +
			"ooo.....\n" +
			"ooo.....\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........\n" +
			"........",
		];
		trace("evaluation: ");
		trace('stage(0-9): $stage');
		for (i in 0...Features.NUM_PATTERN_FEATURES) {
			var index:Int = features[i];
			trace('----------------\npattern:\n${patterns[i]}\nindex = $index, weight = ${weights[stage][index]}');
			score += weights[stage][index];
			if (index > 0 && weights[stage][index] == 0) {
				trace("oh: " + index);
			}
		}
		var idx:Int = numPatterns;
		for (i in Features.NUM_PATTERN_FEATURES...Features.NUM_TOTAL_FEATURES) {
			score += weights[stage][idx++] * features[i];
		}
		trace('score = $score');
		trace('turn = ${turn == Turn.BLACK ? "Black" : "White"}');
		return score;
	}

}
