$(document).ready(function () {
    var server_url = (window.location.protocol == 'https:' ? "wss://" : "ws://") + window.location.host + "/ws/events/";
    var ws = null;
    var message_div = $('#message');


    var open = function () {
        ws = new WebSocket(server_url);
        ws.onerror = on_error;
        ws.onmessage = on_message;
    };

    var on_error = function (event) {
        console.log(event);
    };

    var on_message = function (event) {
        var data = event.data;
        message_div.append(data);
        message_div.append('<hr>');
    };

    open();
});
