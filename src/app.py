import os
from molten import App, Route, ResponseRendererMiddleware
from molten.contrib.prometheus import expose_metrics, prometheus_middleware

DEPLOY_VERSION = os.getenv('DEPLOY_VERSION', 'unknown')


def healthy() -> str:
    return f"healthy"

def ready() -> str:
    return f"ready"

def hello(name: str) -> str:
    return f"Hi {name}! I hear you're {age} years old."


def index() -> str:
    return f"Suuup our color is {DEPLOY_VERSION}"

app = App(
    middleware=[
        prometheus_middleware,
        ResponseRendererMiddleware()
    ],
    routes=[Route("/", index),
            Route("/hello/{name}", hello),
            Route("/healthy", healthy),
            Route("/ready", ready),
            Route("/metrics", expose_metrics),]
)