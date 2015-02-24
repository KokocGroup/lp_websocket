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

.. code-block:: json

    Полностью идентична входящей.


Доступные страницы для разработчиков
------------------------------------
/ - Главная

/notification/ - Страница получения уведомлений

/broadcast/ - Отправка сообщений

/broadcast/msg/ - Страница отправки уведомлений методом POST

/ws/ - Вебсокет

/events/ - Страница просмотра всех оповещений

/ws/events/ - Вебсокет для всех оповещений