FROM ubuntu:latest

COPY . /app/

RUN apt-get update
RUN apt-get install -y python3 python3-pip python3-venv

WORKDIR /app

# Создаём виртуальное окружение и устанавливаем зависимости туда
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt

CMD ["bash", "-c", "source venv/bin/activate && python -m uvicorn app:app --host 0.0.0.0 --port 8000"]