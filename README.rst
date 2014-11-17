Евент сервер
------------
Входящая структура евентов:
{
    "url": "http://127.0.0.1:8080/",
    "message": "String escaped JSON struct",
    "api_key": "Remote User ApiKey for security"
}

Исходящая структура евентов (http POST):
    apiKey = string api key
    event = JSON Message


Socket сервер
-------------
Входящая структура уведомлений:
{
    "path": "some path",
    ... any keys & data ...
}

*все что угодно, но главное необходим ключ path в JSON документе.*
