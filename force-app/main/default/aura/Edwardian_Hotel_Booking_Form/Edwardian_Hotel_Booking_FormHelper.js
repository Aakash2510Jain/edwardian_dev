({
    convertMillisecondsToTimeString: function( component,milliseconds) {
        var hours = Math.floor(milliseconds / (1000 * 60 * 60));
        milliseconds %= (1000 * 60 * 60);
        var minutes = Math.floor(milliseconds / (1000 * 60));
        milliseconds %= (1000 * 60);
        var seconds = Math.floor(milliseconds / 1000);

        var timeString = this.padZero(hours) + ":" + this.padZero(minutes) + ":" + this.padZero(seconds);
        return timeString;
    },

    padZero: function(number) {
        return (number < 10 ? '0' : '') + number;
    },
    

})