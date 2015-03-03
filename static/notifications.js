$(document).ready(function () {
    var server_url = (window.location.protocol == 'https:' ? "wss://" : "ws://") + window.location.host + "/ws/";
    var ws = null;
    var status = $('#status');
    var user_id = $('#user_id');
    var message_div = $('#message');
    var connect_button = $('#connect');
    var disconnect_button = $('#disconnect');


    var open = function () {
        if (ws == null) {
            connect_button.hide();

            ws = new WebSocket(server_url);
            ws.onopen = on_open;
            ws.onclose = on_close;
            ws.onerror = on_error;
            ws.onmessage = on_message;

            status.text('OPENING ...');
            user_id.attr('disabled', 'disabled');
        }
    };

    var close = function () {
        if (ws != null) {
            status.text('CLOSING ...');
            ws.close();
        }
    };

    var send_message = function (msg) {
        ws.send(JSON.stringify(msg));
    };

    var on_open = function () {
        status.text('CONNECTED');
        disconnect_button.show();

        setTimeout(function () {
            status.text('');
        }, 2000);

        send_message({action: "authorize", login: user_id.val(), password: 12345});
        send_message({action: "subscribe", data: ['hello.*', 'pkg.test.*']});
    };

    var on_close = function () {
        status.text('CLOSED ...');
        user_id.removeAttr('disabled');
        connect_button.show();
        disconnect_button.hide();
        ws = null;

        setTimeout(function () {
            status.text('');
            message_div.html('');
        }, 2000);
    };

    var on_error = function (event) {
        alert(event.data);
        on_close();
    };

    var on_message = function (event) {
        var data = event.data;
        message_div.append(data);
        message_div.append('<hr>');
    };


    connect_button.click(open);

    disconnect_button.hide();
    disconnect_button.click(close);
});
