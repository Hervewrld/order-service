FROM python:3.12-slim

WORKDIR /app

COPY src/worker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/worker/worker.py .

EXPOSE 9100

CMD ["python", "worker.py"]
