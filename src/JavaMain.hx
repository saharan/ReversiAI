package;
import haxe.ds.Vector;
import reversi.core.Game;
import reversi.core.RandomGame;
import reversi.evaluation.Evaluator;
import reversi.evaluation.Learning;
import reversi.evaluation.Features;
import reversi.evaluation.TeacherKifus;
import sys.io.File;

/**
 * ...
 */
class JavaMain {
	public function new() {
		Features.computeIndices();

		//createRandomGameKifus();
		computeEvaluationFactors();
	}

	function createRandomGameKifus():Void {
		var etor:Evaluator = new Evaluator(Features.numPatterns);
		for (i in 0...10) {
			var weights:Array<Float> = File.getContent('./eval_$i.txt').split("\n").map(function (s) {
				return Std.parseFloat(s.split(":")[1]);
			});
			etor.load(i, weights);
		}
		trace("input num of random moves from 0 to 60:");
		var rand = Std.parseInt(Sys.stdin().readLine());
		if (rand < 0 || rand > 60) {
			trace("invalid number.");
			return;
		}
		for (j in 0...100000) {
			var g:RandomGame = new RandomGame();
			var kifu:String = g.runGame(rand, etor);
			File.append("randkifu" + rand + ".txt").writeString(kifu + "\n");
			trace("generated: " + j);
		}
	}

	function computeEvaluationFactors():Void {
		Features.computeIndices();

		trace("input stage(s) from 0 to 9 (ex. \"0,1,2,3,4\"):");
		var stages:Array<Int> = ~/ /g.replace(Sys.stdin().readLine(), "").split(",").map(function(s) {
			return Std.parseInt(s);
		});
		trace("stages: " + stages);
		for (s in stages) {
			computeStage(s);
		}
	}

	function computeStage(stage:Int):Void {
		var fname:String = "";
		switch (stage) {
		case 0: // max: 6
			fname += "kifus10.txt";
		case 1, 2, 3: // max: 18
			fname += "kifus20.txt";
		case 4, 5: // max: 30
			fname += "kifus30.txt";
		case 6, 7, 8, 9: // max: 60
			fname += "kifus40.txt";
		}
		var rfname:String = "";
		switch (stage) {
		case 3: // max: 12
			rfname += "randkifu18.txt";
		case 4: // max: 18
			rfname += "randkifu24.txt";
		case 5: // max: 24
			rfname += "randkifu30.txt";
		case 6: // max: 30
			rfname += "randkifu36.txt";
		case 7, 8, 9:
			rfname += "randkifu42.txt";
		}
		var fixIndex:Array<Int>;
		var fixValue:Array<Float>;
		var lambda:Float;
		switch (stage) {
		case 0:
			fixIndex = [113540, 113544];
			fixValue = [0, -8];
			lambda = 0.3;
		case 1:
			fixIndex = [113540, 113544];
			fixValue = [0, -6];
			lambda = 0.25;
		case 2:
			fixIndex = [113540, 113544];
			fixValue = [0, -5];
			lambda = 0.2;
		case 3:
			fixIndex = [113540, 113544];
			fixValue = [0, -4];
			lambda = 0.15;
		case 4:
			fixIndex = [113540, 113544];
			fixValue = [0, -3];
			lambda = 0.1;
		case 5:
			fixIndex = [113540, 113544];
			fixValue = [0, -1.5];
			lambda = 0.05;
		case 6:
			fixIndex = [113544];
			fixValue = [-0.7];
			lambda = 0.02;
		case 7:
			fixIndex = [];
			fixValue = [];
			lambda = 0.01;
		case 8:
			fixIndex = [];
			fixValue = [];
			lambda = 0.005;
		case 9:
			fixIndex = [];
			fixValue = [];
			lambda = 0.001;
		case _:
			fixIndex = [];
			fixValue = [];
			lambda = 0;
		}
		trace("start learning stage " + stage + " using 100,000 books.txt and 400,000 " + fname + (rfname != "" ? " and 10,000 " + rfname : ""));
		var l:Learning = new Learning(Features.numPatterns, fixIndex, fixValue, lambda);
		var from:Int = stage * 6 + 1;
		var to:Int = (stage + 1) * 6;
		if (rfname != "") {
			var rkifus:Array<String> = File.getContent("./" + rfname).split("\n");
			TeacherKifus.createGamesAndTeachers(l, rkifus, 10000, from, to);
		}
		var kifus:Array<String> = File.getContent("./" + fname).split("\n");
		TeacherKifus.createGamesAndTeachers(l, kifus, 400000, from, to);
		// used LOGISTELLO books from http://www.soongsky.com/en/download/
		var books:Array<String> = File.getContent("./books.txt").split("\n");
		TeacherKifus.createGamesAndTeachers(l, books, 100000, from, to);
		l.learn(600);
		trace("saving...");
		save('./eval_$stage.txt', l.weights, l.counts);
		trace("learning finished");
	}

	function save(path:String, weights:Vector<Float>, counts:Vector<Int>):Void {
		var n:Int = weights.length;
		var s = "";
		var ss = [];
		for (i in 0...n) {
			ss.push(counts[i] + ":" + weights[i]);
		}
		File.saveContent(path, ss.join("\n"));
	}

	static function main():Void {
		new JavaMain();
	}
}
