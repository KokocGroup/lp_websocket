#!/usr/bin/env python
# !-*- coding: utf-8 -*-

__author__ = 'gotlium'

import logging
import json
import re

import tornado.web
import tornado.ioloop
import tornado.websocket
from tornado.options import define, options, parse_command_line

from raven.contrib.tornado import AsyncSentryClient
from raven.contrib.tornado import SentryMixin

import tornadoredis


define("port", default=8888, help="run on the given port", type=int)
define("debug", default=False, help="run in debug mode")

logger = logging.getLogger('ws_notify')
handler = logging.FileHandler('/tmp/ws-notify.log')
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.DEBUG)

ALLOWED_FILTER = r'^[a-zA-Z.*0-9_]+$'
ALLOWED_PATH = r'^[a-zA-Z.0-9_]+$'
REPLACE_RULE = (
    ('.', '\.'),
    ('*', '([a-zA-Z0-9_]+)'),
    ('**', '([a-zA-Z0-9_.]+)'),
)

parse_command_line()
# SESSION_REDIS_HOST = 'sessions.mem.dlp3001.ru'
SESSION_REDIS_HOST = '10.50.51.83'
if options.debug is True:
    SESSION_REDIS_HOST = 'localhost'
SESSION_REDIS_PORT = 6379
SESSION_REDIS_PASS = None
SESSION_REDIS_DB = 4

# WS_REDIS_HOST = 'websocket.mem.dlp3001.ru'
WS_REDIS_HOST = '10.50.51.103'
if options.debug is True:
    WS_REDIS_HOST = 'localhost'
WS_REDIS_PORT = 6379
WS_REDIS_PASS = None
WS_REDIS_DB = 4

ws = tornadoredis.Client(
    host=WS_REDIS_HOST, port=WS_REDIS_PORT,
    password=WS_REDIS_PASS, selected_db=WS_REDIS_DB
)
ws.connect()

session = tornadoredis.Client(
    host=SESSION_REDIS_HOST, port=SESSION_REDIS_PORT,
    password=SESSION_REDIS_PASS, selected_db=SESSION_REDIS_DB
)
session.connect()


class IndexHandler(SentryMixin, tornado.web.RequestHandler):
    def get(self):
        self.render('templates/index.html')


class NotificationHandler(SentryMixin, tornado.web.RequestHandler):
    def get(self):
        session.set('12345', '1')
        self.render('templates/notification.html')


class AllNotificationHandler(SentryMixin, tornado.web.RequestHandler):
    def get(self):
        self.render('templates/all_notification.html')


class BroadcastHandler(SentryMixin, tornado.web.RequestHandler):
    def get(self):
        self.render('templates/broadcast.html')


class BroadcastMessageHandler(SentryMixin, tornado.web.RequestHandler):
    def post(self):
        message = self.get_argument('message')
        user_id = str(self.get_argument('user'))

        if user_id.isdigit():
            try:
                data = json.loads(message)
                if isinstance(data, dict) and data.get('path'):
                    if re.match(ALLOWED_PATH, data.get('path')):
                        ws.publish(user_id, message)
                        self.set_header('Content-Type', 'text/plain')
                        self.write('OK')
                        return
            except (ValueError, TypeError):
                pass
        self.write('ERROR')

    def check_origin(self, origin):
        return True


class WSHandler(SentryMixin, tornado.websocket.WebSocketHandler):
    def __init__(self, *args, **kwargs):
        self.client = None
        self.is_authorized = True
        self.subscribe_id = None
        self.subscribe_filters = ['notify\.(.*?)']
        self.subscribe_filters_str = ''
        self.allowed_methods = [
            'authorize', 'subscribe', 'unsubscribe', 'subscriptions']

        super(WSHandler, self).__init__(*args, **kwargs)

    @staticmethod
    def _replace_rule(rule):
        for args in REPLACE_RULE:
            rule = rule.replace(*args)
        return rule

    def _compile_rules(self):
        combined = '|'.join(self.subscribe_filters)
        self.subscribe_filters_str = '^(%s)$' % combined

    def _check_auth(self):
        if not self.is_authorized:
            self.close(403, 'Not authorized!')

    @tornado.gen.engine
    def _password_is_valid(self, sid, callback=None):
        # todo: check user_id on unserialized session
        res = yield tornado.gen.Task(session.get, sid)
        callback(res)

    @tornado.web.asynchronous
    @tornado.gen.engine
    def authorize(self, data):
        if data.get('login') and data.get('password'):
            self.subscribe_id = data.get('login')
            if str(self.subscribe_id).isdigit():
                password_is_valid = yield tornado.gen.Task(
                    self._password_is_valid, data.get('password'))
                if password_is_valid is not None:
                    self.is_authorized = True
                    self.listen()
                    return

        logger.error('Authorization error')
        self.close()

    def subscribe(self, data):
        for rule in data.get('data', []):
            if rule and re.match(ALLOWED_FILTER, rule):
                rule = self._replace_rule(rule)
                if rule and rule not in self.subscribe_filters:
                    self.subscribe_filters.append(rule)
        self._compile_rules()

    def unsubscribe(self, filters):
        for rule in filters.get('data', []) or []:
            if rule and re.match(ALLOWED_FILTER, rule):
                rule = self._replace_rule(rule)
                if rule and rule in self.subscribe_filters:
                    self.subscribe_filters.remove(rule)
        self._compile_rules()

    def subscriptions(self, _):
        self.write_message(self.subscribe_filters_str)

    @tornado.gen.engine
    def listen(self):
        self.client = tornadoredis.Client(
            host=WS_REDIS_HOST, port=WS_REDIS_PORT,
            password=WS_REDIS_PASS, selected_db=WS_REDIS_DB
        )
        self.client.connect()
        self._compile_rules()
        yield tornado.gen.Task(self.client.subscribe, str(self.subscribe_id))
        self.client.listen(self.backend_message)

    def dispatch_backend_message(self, json_msg):
        try:
            data = json.loads(json_msg)
            path = data.get('path')
            if self.subscribe_filters_str:
                if re.match(self.subscribe_filters_str, path):
                    self.write_message(json_msg)
        except Exception, e:
            logger.exception(e)

    def backend_message(self, message):
        if message.kind == 'message':
            self.dispatch_backend_message(message.body)
        if message.kind == 'disconnect':
            self.close()

    def on_message(self, message):
        try:
            message = json.loads(message)
            action = message.get('action')
            if action and action in self.allowed_methods:
                if action != 'authorize':
                    self._check_auth()
                getattr(self, action)(message)
        except ValueError:
            self.close()

    def on_close(self, message=None):
        if self.client and self.client.subscribed:
            self.client.unsubscribe(str(self.subscribe_id))
        if self.client:
            self.client.disconnect()

    def check_origin(self, origin):
        return True


class WSAllHandler(SentryMixin, tornado.websocket.WebSocketHandler):
    def __init__(self, *args, **kwargs):
        self.client = None
        super(WSAllHandler, self).__init__(*args, **kwargs)
        self.listen()

    @tornado.gen.engine
    def listen(self):
        self.client = tornadoredis.Client(
            host=WS_REDIS_HOST, port=WS_REDIS_PORT,
            password=WS_REDIS_PASS, selected_db=WS_REDIS_DB
        )
        self.client.connect()
        yield tornado.gen.Task(self.client.psubscribe, '*')
        self.client.listen(self.backend_message)

    def backend_message(self, message):
        if message.kind == 'pmessage' and '"path"' in message.body:
            self.write_message(message.body)

    def on_close(self, message=None):
        if self.client and self.client.subscribed:
            self.client.punsubscribe('*')
        if self.client:
            self.client.disconnect()

    def check_origin(self, origin):
        return True


class Application(tornado.web.Application):
    def __init__(self):
        self.sentry_client = AsyncSentryClient(
            'http://7276697d95364bc891f8dbe202be7fa2:'
            'c31687ea6d9b4575ba974c202a9755bd@sentry.lpgenerator.ru/9'
        )
        handlers = (
            (r'/', IndexHandler),
            (r'/notification/', NotificationHandler),
            (r'/broadcast/', BroadcastHandler),
            (r'/broadcast/msg/', BroadcastMessageHandler),
            (r'/ws/', WSHandler),
            (
                r'/static/(.*)', tornado.web.StaticFileHandler,
                {'path': 'static/'}
            ),
        )
        if options.debug is True:
            handlers += (
                (r'/events/', AllNotificationHandler),
                (r'/ws/events/', WSAllHandler),
            )
        tornado.web.Application.__init__(self, handlers)


if __name__ == '__main__':
    application = Application()
    application.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()
