Events server
-------------
Входящая структура евентов:

.. code-block:: json

    {
        "url": "http://Plugin.Url",
        "message": "String escaped JSON struct",
        "api_key": "Plugin ApiKey"
    }

Исходящая структура евентов (http POST):

.. code-block:: html

    apiKey = string api key
    event = JSON Message


WebSocket server
----------------
Входящая структура уведомлений:

.. code-block:: json

    {
        "path": "some path",
        ... any keys & data ...
    }

*все что угодно, но главное необходим ключ path в JSON документе.*

Исходящая структура уведомлений:

    Полностью идентична входящей.

