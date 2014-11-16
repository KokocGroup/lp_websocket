#!/usr/bin/env python
#!-*- coding: utf-8 -*-

__author__ = 'gotlium'

from BaseHTTPServer import BaseHTTPRequestHandler
from BaseHTTPServer import HTTPServer
from cgi import FieldStorage


class PostHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        form = FieldStorage(
            fp=self.rfile,
            headers=self.headers,
            environ={
                'REQUEST_METHOD': 'POST',
                'CONTENT_TYPE': self.headers['Content-Type'],
            }
        )

        self.send_response(200)
        self.end_headers()
        self.wfile.write('Client: %s\n' % str(self.client_address))
        self.wfile.write('User-agent: %s\n' % str(self.headers['user-agent']))
        self.wfile.write('Path: %s\n' % self.path)
        self.wfile.write('Form data:\n')

        for field in form.keys():
            self.wfile.write('\t%s=%s\n' % (field, form[field].value))
            print('\t%s=%s' % (field, form[field].value.strip()))
        return


if __name__ == '__main__':
    print 'Starting server, use <Ctrl-C> to stop'

    server = HTTPServer(('127.0.0.1', 8080), PostHandler)
    server.serve_forever()
