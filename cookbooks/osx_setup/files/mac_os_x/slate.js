// Configure Slate, a window manager for OS X.

slate.config("defaultToCurrentScreen", true);

mods = ":cmd;alt";

// Push Bindings
_.each({X: ["left", "right"], Y: ["up", "down"]}, function(dirs, dim) {
    _.each(dirs, function(dir) {
        slate.bind(dir + mods, slate.operation("push", {
            direction: dir,
            style: "bar-resize:screenSize" + dim + "/2"
        }));
    });
});

// Throw Bindings
_.each(_.range(3), function(i) {
    slate.bind((i + 1).toString() + mods, slate.operation("throw", {
        screen: i.toString(),
        width: "screenSizeX",
        height: "screenSizeY"
    }));
});
