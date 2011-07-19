Flofiler logs method invocation times to the Flash log using the `flash.sampler` package. It's not
much, but it's better than paying $600 dollars for Flash Builder.

Using
---------------
1. [Download the swf](https://github.com/downloads/threerings/flofiler/flofiler.swf)
2. Add the path to the downloaded swf to your trusted locations in Flash. This is in the Advanced
   tab of the Flash preferences.
3. Add the path to the downloaded swf to [mm.cfg](http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7fc9.html) as `PreloadSWF` eg `PreloadSWF=/Users/groves/dev/flofile/target/flofiler.swf`.
4. Hit F2 while in a swf to be profiled to start sampling.
5. Hit F2 again to dump the method invocation times.
