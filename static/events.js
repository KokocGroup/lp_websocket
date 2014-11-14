$(document).ready(function () {
    var server_url = "ws://" + window.location.host + "/ws/events/";
    var ws = null;
    var message_div = $('#message');


    var open = function () {
        ws = new WebSocket(server_url);
        ws.onclose = on_close;
        ws.onerror = on_error;
        ws.onmessage = on_message;
    };

    var on_close = function () {
        ws = null;

        setTimeout(function () {
            open();
        }, 2000);
    };

    var on_error = function (event) {
        console.log(event);
        on_close();
    };

    var on_message = function (event) {
        var data = event.data;
        message_div.append(data);
        message_div.append('<hr>');
    };

    open();
});
