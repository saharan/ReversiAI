package reversi.evaluation;
import haxe.ds.Vector;

/**
 * ...
 */
class Learning {
	public var weights(default, null):Vector<Float>;
	var dWeights:Vector<Float>;
	var numWeights:Int;

	public var counts(default, null):Vector<Int>;
	var numAppearedFeatures:Int;

	var diffScalings:Vector<Float>;
	var numPatterns:Int;

	var teachers:Vector<Teacher>;
	var numTeachers:Int;

	var fixIndex:Array<Int>;
	var fixValue:Array<Float>;

	/**
	 * the factor of L2 regularization
	 */
	var lambda:Float;

	public function new(numPatterns:Int, fixIndex:Array<Int>, fixValue:Array<Float>, lambda:Float) {
		this.numPatterns = numPatterns;
		this.fixIndex = fixIndex.copy();
		this.fixValue = fixValue.copy();
		this.lambda = lambda;

		this.fixIndex.push(0); // the score of "null pattern" should be 0.0
		this.fixValue.push(0);

		numWeights = numPatterns + Features.NUM_NON_PATTERN_FEATURES;
		weights = new Vector<Float>(numWeights);
		diffScalings = new Vector<Float>(numWeights);
		dWeights = new Vector<Float>(numWeights);
		counts = new Vector<Int>(numWeights);

		teachers = new Vector<Teacher>(6 * 550000 + 1000);
		numTeachers = 0;
	}

	public function addTeacher(teacher:Teacher):Void {
		teachers[numTeachers++] = teacher;
	}

	public function learn(maxIterations:Int):Void {
		for (i in 0...numWeights) {
			weights[i] = 0;
			dWeights[i] = 0;
			diffScalings[i] = 0;
			counts[i] = 0;
		}

		for (i in 0...numTeachers) {
			var t:Teacher = teachers[i];
			var features:Vector<Int> = t.features;
			for (j in 0...Features.NUM_PATTERN_FEATURES) {
				counts[features[j]]++;
			}
			var idx:Int = numPatterns;
			for (j in Features.NUM_PATTERN_FEATURES...Features.NUM_TOTAL_FEATURES) {
				counts[idx++]++;
			}
		}
		numAppearedFeatures = 0;

		for (i in 0...numWeights) {
			if (counts[i] != 0) {
				numAppearedFeatures++;
			}
		}

		var maxScaling:Float = 1 / 100; // 1 / (0.1 * numAppearedFeatures);
		for (i in 0...numWeights) {
			var scaling:Float = 0;
			if (counts[i] != 0) {
				scaling = 1 / counts[i];
				if (scaling > maxScaling) scaling = maxScaling;
			}
			diffScalings[i] = scaling;
		}

		for (i in 0...fixIndex.length) {
			diffScalings[fixIndex[i]] = 0;
			weights[fixIndex[i]] = fixValue[i];
		}

		trace('$numAppearedFeatures out of $numWeights (${numAppearedFeatures / numWeights * 100}%) features appeared in the teacher data');

		var end:Bool = false;
		var count:Int = 0;
		var delta:Float = 6;
		var prevError:Float = 1.0 / 0.0;

		var overShootCount:Int = 0;

		while (!end) {
			var error:Float = 0;

			// compute grad f
			for (i in 0...numTeachers) {
				var t:Teacher = teachers[i];
				var features:Vector<Int> = t.features;
				var r:Float = t.score - evaluate(features);
				var rDelta:Float = r * delta;
				error += r * r;
				for (j in 0...Features.NUM_PATTERN_FEATURES) {
					var index:Int = features[j];
					dWeights[index] += r * diffScalings[index];
				}
				var idx:Int = numPatterns;
				for (j in Features.NUM_PATTERN_FEATURES...Features.NUM_TOTAL_FEATURES) {
					dWeights[idx] += r * diffScalings[idx] * features[j];
					idx++;
				}
			}

			// L2 Regularization
			for (i in 0...numWeights) {
				if (diffScalings[i] > 0) {
					dWeights[i] -= lambda * weights[i];
				}
			}

			var length:Float = 0;
			for (i in 0...numWeights) {
				length += dWeights[i] * dWeights[i];
			}
			length = 1 / Math.sqrt(length);

			for (i in 0...numWeights) {
				weights[i] += dWeights[i] * length * delta;
				dWeights[i] = 0;
			}

			if (error > prevError) {
				delta /= 1.01;
				overShootCount++;
				if (overShootCount == 3) {
					delta *= 0.75;
					overShootCount = 0;
				}
			} else {
				delta *= 1.001;
			}

			prevError = error;

			count++;
			if (count > maxIterations || delta < 0.01) end = true;
			if ((count - 1) % 5 == 0) {
				trace('MSE=${error / numTeachers}, delta=$delta, ${(count - 1) / maxIterations * 100}%');
			}
		}
		trace('finished.');
	}

	@:extern
	inline function evaluate(features:Vector<Int>):Float {
		var score:Float = 0;
		for (i in 0...Features.NUM_PATTERN_FEATURES) {
			score += weights[features[i]];
		}
		var idx:Int = numPatterns;
		for (i in Features.NUM_PATTERN_FEATURES...Features.NUM_TOTAL_FEATURES) {
			score += weights[idx++] * features[i];
		}
		return score;
	}

}
