# Базовый образ с Python
FROM python:3.12-slim

# Чтобы Python не создавал .pyc и вывод шел сразу в консоль
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Рабочая директория внутри контейнера
WORKDIR /app

# Установим системные зависимости для psycopg2
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
 && rm -rf /var/lib/apt/lists/*

# Скопировать requirements и установить зависимости
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Скопировать весь проект внутрь контейнера
COPY . .

# Статические и медиа файлы можно потом настраивать отдельно
EXPOSE 8000

# Команда по умолчанию (разработка)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
