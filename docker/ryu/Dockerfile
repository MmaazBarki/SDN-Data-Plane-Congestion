# docker/ryu/Dockerfile
FROM python:3.7-slim

ENV PYTHONUNBUFFERED=1
# pin Ryu and exact runtime dependencies compatible with Python 3.7
RUN pip install --no-cache-dir \
    "ryu==4.34" \
    "eventlet==0.25.1" \
    "dnspython==1.16.0" \
    "setuptools==25.4.0"

WORKDIR /app
COPY ryu_app.py /app/ryu_app.py

EXPOSE 6633 6653 8080
CMD ["ryu-manager", "--default-log-level", "20", "ryu.app.ofctl_rest", "/app/ryu_app.py"]