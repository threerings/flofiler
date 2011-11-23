package com.threerings.flofiler {

import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.net.LocalConnection;
import flash.sampler.DeleteObjectSample;
import flash.sampler.NewObjectSample;
import flash.sampler.Sample;
import flash.sampler.StackFrame;
import flash.sampler.getSamples;
import flash.sampler.pauseSampling;
import flash.sampler.clearSamples;
import flash.sampler.startSampling;
import flash.sampler.stopSampling;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.ui.Keyboard;

import flash.system.System;

public class Flofiler extends Sprite
{
    public function Flofiler ()
    {
        trace("Flofiler created");
        // "allComplete" is called whenever a swf is loaded, so we can use it to get the real stage
        // http://jpauclair.net/2010/02/17/one-swf-to-rule-them-all-the-almighty-preloadswf/
        addEventListener("allComplete", onAllComplete);
    }

    protected function onAllComplete (e :Event) :void
    {
        removeEventListener("allComplete", onAllComplete);
        // Extract the real stage and listen for keyboard events on it. The PreloadSwf stage is
        // garbage collected when the real stage is loaded. Accessing it from here crashes the flash
        // plugin.
        const loader :LoaderInfo = LoaderInfo(e.target);
        loader.content.stage.addEventListener(KeyboardEvent.KEY_DOWN,
            function (e :KeyboardEvent) :void {
                if (e.keyCode != Keyboard.F2) { return; }
                toggleSampling();
            });
        trace("Flofiler listening");
        var dumper :Timer = new Timer(50);

        var adding :Boolean;
        dumper.addEventListener(TimerEvent.TIMER, function (..._) :void {
            if (!_root || adding) return;
            adding = true;

            pauseSampling();
            addSamples(_root, _allocs);
            if (_sampling) {
                startSampling();
            } else {
                _root.dump();
                dumpAllocs();
                _root = null;
                _allocs = null;
            }
            adding = false;
        });

        // starts the timer ticking
        dumper.start();
    }

    protected function dumpAllocs () :void
    {
        trace("Allocations...");
        trace("Class : allocatedCount : remainingCount : remainingSize");
        var summary :Dictionary = new Dictionary();
        for each (var data :Array in _allocs) {
            var sumArr :Array = summary[data[0]];
            if (sumArr != null) {
                sumArr[0]++;
                if (!data[2]) {
                    sumArr[1]++;
                    sumArr[2] += data[1];
                }
            } else {
                summary[data[0]] = [1, data[2] ? 0 : 1, data[2] ? 0 : data[1]];
            }
        }

        var entries :Array = [];
        for (var key :Object in summary) {
            entries.push(new MemoryEntry(key, summary[key][0], summary[key][1], summary[key][2]));
        }

        entries.sortOn("size", Array.DESCENDING | Array.NUMERIC);

        for each (var entry :MemoryEntry in entries) {
            trace(entry.toString());
        }
    }

    protected function toggleSampling () :void
    {
        if (!_sampling) {
            _root = new Frame("root");
            _allocs = new Dictionary();
            startSampling();
            trace("Flofiler sampling");
        } else {
            function forceGC():void {
                // Magical hack to force GC to occur IMMEDIATELY.
                // Evidently, System.gc() waits for the next frame.
                try {
                    new LocalConnection().connect("bdebdd96-7bf8-407b-bec9-8336b2b0c329");
                    new LocalConnection().connect("bdebdd96-7bf8-407b-bec9-8336b2b0c329");
                }
                catch (error:Error) {
                }
            };

            forceGC();
        }
        _sampling = !_sampling;
    }

    protected static function addSamples (rootFrame :Frame, allocs :Dictionary) :void
    {
        for each (var s :Sample in getSamples()) {
            var id :int;
            if (s is NewObjectSample) {
                id = NewObjectSample(s).id;
                allocs[id] = [NewObjectSample(s).type, NewObjectSample(s)["size"], false];
            } else if (s is DeleteObjectSample) {
                id = DeleteObjectSample(s).id;
                if (allocs[id] != null) {
                    allocs[id][2] = true;
                }
            }
            
            if (s == null || s.stack == null) {
                continue;
            }

            var pos :Frame = rootFrame;
            for (var idx :int = s.stack.length; idx >= 0; idx--) {
                var frame :StackFrame = s.stack[idx] as StackFrame;
                if (frame == null) { continue; }
                var found :Frame = null;
                for each (var child :Frame in pos.children) {
                    if (child.name == frame.name) {
                        found = child;
                        break;
                    }
                }
                if (found == null) {
                    found = new Frame(frame.name);
                    pos.children.push(found);
                }
                pos = found;
                pos.cumulativeMicros += s.time;
            }
            pos.ownMicros += s.time;
        }
        clearSamples();
    }

    protected var _root :Frame;
    protected var _allocs :Dictionary;
    protected var _sampling :Boolean;
}
}

class MemoryEntry
{
    public var type :Object;
    public var items :int;
    public var undeleted :int;
    public var size :int;

    public function MemoryEntry (type :Object, items :int, undeleted :int, size :int)
    {
        this.type = type;
        this.items = items;
        this.undeleted = undeleted;
        this.size = size;
    }

    public function toString () :String
    {
        return type + " : " + items + " : " + undeleted + " : " + size;
    }
}