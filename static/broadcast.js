$(document).ready(function () {
    var server_url = window.location.origin + "/broadcast/msg/";
    var status = $('#status');

    var notify = function (msg) {
        status.text(msg);

        setTimeout(function () {
            status.text('');
        }, 2000);

    };

    var fail = function () {
        notify('ERROR');
    };

    var success = function (data) {
        notify(data);
    };

    var send = function () {
        $.post(server_url, {
            message: $('#message').val(),
            user: $('#user').val()
        }).success(success).fail(fail);
    };

    $('#send').click(send);
});
