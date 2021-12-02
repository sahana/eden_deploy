#!/usr/bin/python
default_application = '{{ appname }}'
default_controller = 'default'
default_function = 'index'
routes_onerror = [
        ('{{ appname }}/400', '!'),
        ('{{ appname }}/401', '!'),
        ('{{ appname }}/405', '!'),
        ('{{ appname }}/409', '!'),
        ('{{ appname }}/509', '!'),
        ('{{ appname }}/*', '/{{ appname }}/errors/index'),
        ('*/*', '/{{ appname }}/errors/index'),
    ]