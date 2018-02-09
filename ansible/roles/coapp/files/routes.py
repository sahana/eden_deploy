#!/usr/bin/python
default_application = 'eden_deployment'
default_controller = 'setup'
default_function = 'index'
routes_onerror = [
        ('eden_deployment/400', '!'),
        ('eden_deployment/401', '!'),
        ('eden_deployment/*', '/eden_deployment/errors/index'),
        ('*/*', '/eden_deployment/errors/index'),
    ]