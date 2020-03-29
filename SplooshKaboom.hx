@:using(SplooshKaboom.TileTools)
enum Tile
{
    NOTHING;
    BOAT(size:Int);
}

class TileTools
{
    static public function toString(t:SplooshKaboom.Tile)
    {
        return switch (t)
        {
            case NOTHING: ".";
            case BOAT(_): "x";
        }
    }
}

class SplooshKaboom
{
    static public var GRID_LENGTH:Int = 8;

    var grid:Array<Array<Tile>>;

    public function new()
    {
        grid = [];
        for (i in 0...GRID_LENGTH)
        {
            var line = [];
            for (j in 0...GRID_LENGTH)
            {
                line.push(NOTHING);
            }
            grid.push(line);
        }

        var boats = [2, 3, 4];
        for (b in boats)
        {
            while (!placeBoat(grid, b)) {}
        }
    }

    public function getTile(pos: {x:Int, y:Int})
    {
        return grid[pos.y][pos.x];
    }

    public function print()
    {
        return "\n"+grid.map((l) -> l.map((t) -> t.toString()).join(" ")).join("\n");
    }

    static function placeBoat(grid:Array<Array<Tile>>, size:Int)
    {
        var vertical = Std.random(2) == 0;
        var startPos = {x: Std.random(GRID_LENGTH), y: Std.random(GRID_LENGTH)};
        if (vertical && startPos.x + size >= grid.length - 1 || !vertical && startPos.y + size >= grid.length - 1)
        {
            return false;
        }

        for (i in 0...size)
        {
            if (!vertical && grid[startPos.x][startPos.y + i].match(BOAT(_)) || vertical && grid[startPos.x + i][startPos.y].match(BOAT(_)))
                return false;
        }

        for (i in 0...size)
        {
            if (!vertical)
                grid[startPos.x][startPos.y + i] = BOAT(size);
            else
                grid[startPos.x + i][startPos.y] = BOAT(size);
        }
        return true;
    }
}
