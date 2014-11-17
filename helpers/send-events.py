# -*- encoding: utf-8 -*-

__author__ = 'gotlium'

from redis import Redis
from json import dumps


DATA_STRUCT = {
    "url": "http://127.0.0.1:8080/",
    "message": "Hello, World!",
    "api_key": "AFAAFASDVZXV"
}
QUEUE_RANGE = 100000
QUEUE_NAME = "events"


def send_events():
    data = dumps(DATA_STRUCT)
    redis = Redis()

    for i in range(QUEUE_RANGE):
        redis.rpush(QUEUE_NAME, data)


if __name__ == '__main__':
    send_events()
