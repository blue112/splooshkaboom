import haxe.Timer;
using Lambda;
using Std;

class AIParams
{
    public var spaceOut:Int;
    public var sameLineProb:Float;
    public var otherLineProb:Float;

    public function new(spaceOut:Int, sameLineProb: Float, otherLineProb:Float)
    {
        this.spaceOut = spaceOut;
        this.sameLineProb = sameLineProb;
        this.otherLineProb = otherLineProb;
    }

    public function toString()
    {
        return 'SO=$spaceOut - SL=${(sameLineProb * 100).int()}% - OL=${(sameLineProb * 100).int()}%';
    }
}

typedef Pos = {x:Int, y:Int};

class SploochAI
{
    static var NUM_BOARDS = 500;
    static var POPULATION = 1000;

    var board:SplooshKaboom;

    var curNumMoves:Int;
    var alreadyPlayed:Array<{x:Int, y:Int}>;
    var params:AIParams;

    function new(board:SplooshKaboom, params:AIParams)
    {
        this.params = params;
        this.board = board;
    }

    public function isAlreadyPlayed(pos:{x:Int, y:Int})
    {
        for (i in alreadyPlayed)
        {
            if (i.x == pos.x && i.y == pos.y)
                return true;
        }

        return false;
    }

    public function run()
    {
        alreadyPlayed = [];
        curNumMoves = 0;

        while (true)
        {
            var tileToPlay = tileSelector();
            alreadyPlayed.push(tileToPlay);

            curNumMoves++;

            if (board.getTile(tileToPlay).match(BOAT(_)))
                break;
        }

        return curNumMoves;
    }

    function isFarFromOtherMoves(move:Pos, dist:Int)
    {
        for (i in alreadyPlayed)
        {
            if (Math.abs(i.x - move.x) < dist && Math.abs(i.y - move.y) < dist)
                return false;
        }

        return true;
    }

    function tileSelector()
    {
        if (alreadyPlayed.length > 0 && Math.random() < params.sameLineProb)
        {
            // Play on same line that previous shot
            var prevShot = alreadyPlayed[Std.random(alreadyPlayed.length)];
            var add = Std.random(SplooshKaboom.GRID_LENGTH - 1) + 1;
            var availOnSameLine = [];
            for (i in 0...SplooshKaboom.GRID_LENGTH)
            {
                var pos = {x: 0, y: prevShot.y};
                if (!isAlreadyPlayed(pos))
                {
                    availOnSameLine.push(pos);
                }
            }

            if (availOnSameLine.length > 0)
                return availOnSameLine[Std.random(availOnSameLine.length)];
        }

        if (alreadyPlayed.length > 0 && Math.random() < params.otherLineProb)
        {
            // Play on same line that previous shot
            var prevShot = alreadyPlayed[Std.random(alreadyPlayed.length)];
            var add = Std.random(SplooshKaboom.GRID_LENGTH - 1) + 1;
            var availOnSameLine = [];
            for (i in 0...SplooshKaboom.GRID_LENGTH)
            {
                var pos = {x: 0, y: prevShot.y};
                if (!isAlreadyPlayed(pos))
                {
                    availOnSameLine.push(pos);
                }
            }

            if (availOnSameLine.length > 0)
                return availOnSameLine[Std.random(availOnSameLine.length)];
        }

        var availableMoves = [];
        for (x in 0...SplooshKaboom.GRID_LENGTH)
        {
            for (y in 0...SplooshKaboom.GRID_LENGTH)
            {
                if (isFarFromOtherMoves({x: x, y: y}, params.spaceOut))
                {
                    availableMoves.push({x: x, y: y});
                }
            }
        }

        if (availableMoves.length == 0)
        {
            if (params.spaceOut == 1)
            {
                trace('No available moves with $params :( ');
                trace(alreadyPlayed);
                js.Node.process.exit(1);
            }
            return {x: Std.random(SplooshKaboom.GRID_LENGTH), y: Std.random(SplooshKaboom.GRID_LENGTH)};
        }

        return availableMoves[Std.random(availableMoves.length)];
    }

    static public function main()
    {
        js.Lib.require('source-map-support').install();
        haxe.CallStack.wrapCallSite = js.Lib.require('source-map-support').wrapCallSite;

        var currentPop = [];
        for (i in 0...POPULATION)
        {
            currentPop.push(new AIParams(Std.random(3), Math.random(), Math.random()));
        }

        var results = [];
        var count = 0;

        var startTime = Timer.stamp();
        for (params in currentPop)
        {
            for (n in 0...NUM_BOARDS)
            {
                var board = new SplooshKaboom();
                var ai = new SploochAI(board, params);
                var numMoves = ai.run();
                results.push({n: numMoves, params: params});
            }

            count++;
            if (count % (POPULATION / 20) == 0)
            {
                trace('d=${((Timer.stamp() - startTime) * 1000).int()}ms');
                startTime = Timer.stamp();
                trace('Playing next params ($count / $POPULATION)...');
            }
        }

        var avgHash:Map<String, {num:Int, sum:Int}> = new Map();

        for (i in results)
        {
            if (!avgHash.exists(i.params.string()))
            {
                avgHash.set(i.params.string(), {num: 0, sum: 0});
            }

            var h = avgHash.get(i.params.string());
            h.sum += i.n;
            h.num++;
        }

        var scores:Array<{score:Float, params:String}> = [];
        for (k => v in avgHash)
        {
            scores.push({score: v.sum / v.num, params: k});
        }

        scores.sort((a, b) -> if (a.score < b.score) -1 else 1);
        trace("Generation 1 results...");
        trace(scores.slice(0, 30));
    }
}