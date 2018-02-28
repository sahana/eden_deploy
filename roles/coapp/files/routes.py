#!/usr/bin/python
default_application = 'eden_setup'
default_controller = 'setup'
default_function = 'index'
routes_onerror = [
        ('eden_setup/400', '!'),
        ('eden_setup/401', '!'),
        ('eden_setup/*', '/eden_setup/errors/index'),
        ('*/*', '/eden_setup/errors/index'),
    ]