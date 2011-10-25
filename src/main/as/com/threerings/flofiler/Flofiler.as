package com.threerings.flofiler {

import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.sampler.Sample;
import flash.sampler.StackFrame;
import flash.sampler.getSamples;
import flash.sampler.pauseSampling;
import flash.sampler.clearSamples;
import flash.sampler.startSampling;
import flash.sampler.stopSampling;
import flash.utils.Timer;
import flash.events.TimerEvent;
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
        var dumper :Timer = new Timer(50);

        var adding :Boolean;
        dumper.addEventListener(TimerEvent.TIMER, function (..._) :void {
            if (!_root || adding) return;
            adding = true;
            pauseSampling();
            addSamples(_root);
            if (_sampling) {
                startSampling();
            } else {
                _root.dump();
                _root = null;
            }
            adding = false;
        });

        // starts the timer ticking
        dumper.start();
    }

    protected function toggleSampling () :void
    {
        if (!_sampling) {
            _root = new Frame("root");
            startSampling();
            trace("Flofiler sampling");
        }
        _sampling = !_sampling;
    }

    protected static function addSamples (rootFrame :Frame) :void
    {
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
        clearSamples();
    }

    protected var _root :Frame;
    protected var _sampling :Boolean;
}
}
