import os
from jinja2 import Template
from molten import App, Route, ResponseRendererMiddleware, HTTP_500, HTTP_200, Response
from molten.contrib.templates import Templates, TemplatesComponent
from molten.contrib.prometheus import expose_metrics, prometheus_middleware

DEPLOY_VERSION = os.getenv('DEPLOY_VERSION', 'unknown')
ENVIRONMENT_NAME = os.getenv('ENVIRONMENT_NAME', 'Unknown')

hello_template = Template('Hello {{ name }}!')

index_template = Template('<html><style>body{background-color:{{ DEPLOY_VERSION }}}</style><body>DEPLOY_VERSION: {{ DEPLOY_VERSION }}!<br>In Environment: {{ ENVIRONMENT_NAME }}</body></html>')


def healthy() -> str:
    return f"healthy"

def unhealthy() -> str:
    return Response(HTTP_500, content=hello_template.render(name=name), headers={
    "content-type": "text/html",
    })

def ready() -> str:
    return f"ready"


def hello(templates: Templates, name: str) -> str:
    return Response(HTTP_200, content=hello_template.render(name=name), headers={
    "content-type": "text/html",
    })


def index(templates: Templates) -> str:
    return templates.render('index.html', DEPLOY_VERSION=DEPLOY_VERSION,
                                          ENVIRONMENT_NAME=ENVIRONMENT_NAME)


app = App(
    components=[TemplatesComponent('templates')],
    middleware=[
        prometheus_middleware,
        ResponseRendererMiddleware()
    ],
    routes=[Route("/", index),
            Route("/hello/{name}", hello),
            Route("/healthy", healthy),
            Route("/ready", ready),
            Route("/metrics", expose_metrics),
            Route("/unhealthy", unhealthy),]
)