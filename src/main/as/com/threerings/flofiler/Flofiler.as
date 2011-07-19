package com.threerings.flofiler {

import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.sampler.Sample;
import flash.sampler.StackFrame;
import flash.sampler.clearSamples;
import flash.sampler.getSamples;
import flash.sampler.startSampling;
import flash.sampler.stopSampling;
import flash.sampler.getSampleCount;
import flash.ui.Keyboard;

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
    }

    protected function toggleSampling () :void
    {
        if (!_sampling) {
            startSampling();
            trace("Flofiler sampling");
        } else {
            dumpSamples();
            stopSampling();// stop also clears out the samples
            trace("Flofiler idle");
        }
        _sampling = !_sampling;
    }

    protected static function dumpSamples () :void
    {
        const rootFrame :Frame = new Frame("root");
        for each (var s :Sample in getSamples()) {
            if (s== null || s.stack == null) { continue; }// memory samples have no stack
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
        rootFrame.dump();
    }

    protected var _sampling :Boolean;
}
}
