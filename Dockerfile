FROM python:3-alpine
EXPOSE 8000
WORKDIR /src
ADD ./src /src
RUN pip install -r requirements.txt
ENTRYPOINT ["gunicorn"]
CMD ["--log-level=debug", "--bind=0.0.0.0:8000", "app:app"]