(function(w) {
    var oldST = w.setTimeout;
    var oldSI = w.setInterval;
    var oldCI = w.clearInterval;
    var timers = [];
    w.timers = timers;
    w.setTimeout = function(fn, delay) {
        var id = oldST(function() {
            fn && fn();
            removeTimer(id);
        }, delay);
        timers.push(id);
        return id;
    };
    w.setInterval = function(fn, delay) {
        var id = oldSI(fn, delay);
        timers.push(id);
        return id;
    };
    w.clearInterval = function(id) {
        oldCI(id);
        removeTimer(id);
    };
    w.clearTimeout = w.clearInterval;

    function removeTimer(id) {
        var index = timers.indexOf(id);
        if (index >= 0)
            timers.splice(index, 1);
    }
}(window));