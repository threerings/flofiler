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
import flash.ui.Keyboard;

public class Flofiler extends Sprite
{
    public function Flofiler ()
    {
        addEventListener("allComplete", onAllComplete);
    }

    protected function onAllComplete (e :Event) :void
    {
        removeEventListener("allComplete", onAllComplete);
        const loader :LoaderInfo = LoaderInfo(e.target);
        loader.content.stage.addEventListener(KeyboardEvent.KEY_DOWN,
            function (e :KeyboardEvent) :void {
                if (e.keyCode != Keyboard.F2) { return; }
                toggleSampling();
            });
    }

    protected function toggleSampling () :void
    {
        if (!_sampling) {
            startSampling();
        } else {
            checkSamples();
            clearSamples();
            stopSampling();
        }
        _sampling = !_sampling;
    }

    public static function checkSamples (..._) :void
    {
        const rootFrame :Frame = new Frame("root");
        for each (var s :Sample in getSamples()) {
            var pos :Frame = rootFrame;
            if (s == null || s.stack == null || isNaN(s.time)) { continue; }
            var rev :Array = s.stack.concat().reverse();
            for each (var frame :StackFrame in rev) {
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
