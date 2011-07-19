package com.threerings.flofiler {

public class Frame
{
    public var ownMicros :Number = 0, cumulativeMicros :Number = 0;
    public var name :String;
    public var children :Array = [];//<Frame>

    public function Frame (name :String)
    {
        this.name = name;
    }

    public function dump (prefix :String="") :void
    {
        trace(prefix + name + " " + (ownMicros/1000000000) + " " + (cumulativeMicros/1000000000));
        prefix += "  ";
        children.sortOn("cumulativeMicros", Array.NUMERIC | Array.DESCENDING);
        for each (var child :Frame in children) {
            child.dump(prefix);
        }

    }
}
}
