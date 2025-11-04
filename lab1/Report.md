# Лабораторная работа №1
## Тема: Первоначальная настройка и конфигурирование веб-сервера Nginx

### Цель
Освоить базовые принципы DevOps на практике, изучив и применив ключевые механизмы конфигурации веб-сервера Nginx для развертывания безопасного и функционального веб-хостинга, соответствующего производственным требованиям.

### Задачи
- ```Nginx``` должен работать по https c сертификатом
- Настроить принудительное перенаправление HTTP-запросов (порт 80) на HTTPS (порт 443) для обеспечения безопасного соединения.
- Использовать ```alias``` для создания псевдонимов путей к файлам или каталогам на сервере.
- Настроить виртуальные хосты для обслуживания нескольких доменных имен на одном сервере.


## Ход работы
К сожаления я не devops инженер, поэтому nginx у меня не установлен, а значит есть с чего начать. Для этого переходим на [официальную документацию nginx](https://nginx.org/) и там находим [инструкцию по установке](https://nginx.org/ru/linux_packages.html#Ubuntu) для нашей OС.  
**P.S.** Cпасибо хорошим разработчикам, что ведут качественную документацию.  
### Шаг 1. Установка nginx
Выполняем все по документации для Ubuntu:
```bash
  sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring
  
  curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
  http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
      | sudo tee /etc/apt/sources.list.d/nginx.list
  
  echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
      | sudo tee /etc/apt/preferences.d/99nginx
  
  sudo apt update
  sudo apt install nginx
```
Проверяем версию nginx, которая установилась:
```bash
  nginx -version
  nginx version: nginx/1.28.0
```
Все работает, можно выполнять лабораторную.
### Шаг 2. Настройка сертификатов для работы nginx по https
Так как я мало что знаю о сертификатах, пришлось использовать лучший помощник google. Нашел отличный сайт Let's Encrypt и у них уже была [инструкция по самоподписанным сертификатам](https://letsencrypt.org/ru/docs/certificates-for-localhost/#создание-и-поверка-собственных-сертификатов).
Прочитав её я немного разобрался в этом, но оставалось понять, что вообще значит команда, представленная в статье:
```bash
  openssl req -x509 -out localhost.crt -keyout localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=localhost' -extensions EXT -config <( \
     printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```
Значение параметров:  
```-x509``` - указание на создание самоподписанного сертификата  
```-out localhost.crt``` - имя выходного файла для сертификата  
```-keyout localhost.key``` - имя выходного файла для приватного ключа  
```-newkey rsa:2048``` - создание ключа с длиной 2048 бит  
```-nodes``` - сохранение ключа в незашифрованном виде, чтобы не вводить пароль(для удобства)  
```-sha256``` - указание на использование алгоритма шифрования SHA-256  
```-subj '/CN=localhost'``` - Задает Subject (субъект) сертификата  
```-extensions EXT``` - указание на использование раздела с именем ```EXT``` из конфигурационного файла для применения расширений к сертификату  
```-config <( ... )``` - создание временного файла для передачи его как конфига  

Посмотрев на эти параметры я подумал, что мне придётся создавать два ключа на каждый сервер отдельно. Это мне показалось странным, ведь легче создать общий сертификат.  
Я пошел искать какую-то информации об этом и нашел раздел [настройка HTTPS-серверов](https://nginx.org/ru/docs/http/configuring_https_servers.html#certificate_with_several_names) в документации nginx.  
Так я познакомился с CN и SAN, а также понял для чего тут нужен временный файл, в котором указывается формат SAN ```subjectAltName=```.
Создаём сертификат:
```bash
  openssl req -x509 -out localhost.crt -keyout localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=localhost' -extensions EXT -config <( \
     printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost,DNS:127.0.0.1,DNS:app1.local,DNS:app2.local,IP:127.0.0.1\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```

Добавляем сертификат в конфигурацию nginx:
```nginx
  http {
    ...
    ssl_certificate /home/dinis/projects/study/Clouds/lab1/ssl/localhost.crt;
    ssl_certificate_key /home/dinis/projects/study/Clouds/lab1/ssl/localhost.key;
  }
```

### Шаг 3. Настройка принудительного перенаправления на HTTPS запросы
Добавим в nginx.conf следующий код для реализации переадресации
```nginx
  http {
    ...
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }
  }
```

### Шаг 4. Настройка виртуальных хостов
Я посмотрел несколько гайдов для начинающих, и везде было предложено просто сделать в файле nginx.conf несколько блоков ```server { }```, но мне не понравился этот подход. А вдруг у меня будет 20 серверов, тогда конфигурация получится огромной и менее читаемой. Для реализации более удобной архитектуры конфигурации nginx я нашел подход через использование директории ```conf.d``` для дополнительных конфигов.  

Создаём два файла в директории conf.d:  
- app1.conf  
- app2.conf
  
Добавляем в ```/etc/hosts``` 127.0.0.1 app1.local app2.local
Создаём файлы app1.html и app2.html
Настраиваем файлы app1.conf и app2.conf:
- app1.conf
  ```nginx
    server {
      listen 443 ssl;
      listen [::]:443 ssl;
      server_name app1.local;

      location / {
        root /home/dinis/projects/study/Clouds/lab1/apps/;
        index app1.html;
      }
    }
  ```
- app2.conf
  ```nginx
    server {
      listen 443 ssl;
      listen [::]:443 ssl;
      server_name app2.local;

      location / {
        root /home/dinis/projects/study/Clouds/lab1/apps/;
        index app1.html;
      }
    }
  ```
На этом этапе я решил проверить работу nginx и он запустился. Тут я подумал, что вроде все должно работать и решил проверить в браузере, что будет выдано при переходе на app1.local, но он просто не видит сайт. Ну да, кто мог подумать что wsl на котором запущен nginx и windows на котором запущен бразузер это разные вещи и друг с другом они не обмениваются. Тогда я решил, что просто проверю работоспособность через терминал linux.   
Хорошо, проверил тогда через терминал:  
```bash
  curl -I http://app1.local
```
**Response:**  
```http
HTTP/1.1 403 Forbidden  
Server: nginx/1.28.0  
Date: Tue, 04 Nov 2025 18:26:09 GMT  
Content-Type: text/html  
Content-Length: 153  
Connection: keep-alive  
```
Да, я получил код ошибка 403. Оказалось, что файлы сайтов находились в моей личной директории, к которой у nginx не было доступа и пришлось изменять права доступа. 

Проверяем еще раз 

 app1
  
**Request:**
```bash
curl -I http://app1.local
```
**Response:**
```bash
HTTP/1.1 301 Moved Permanently
Server: nginx/1.28.0
Date: Tue, 04 Nov 2025 19:00:53 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://app1.local/
```

  app2
   
**Request:**
```bash
curl -I http://app2.local
```
**Response:**
```bash
HTTP/1.1 301 Moved Permanently
Server: nginx/1.28.0
Date: Tue, 04 Nov 2025 19:06:20 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://app2.local/
```

Отлично, редирект на https работает для обоих серверов.  

Проверим, разные ли вообще странички выдает nginx при запросах на разные сервера:  

 app1
  
**Request:**
```bash
curl -k https://app1.local
```
**Response:**
```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Приложение 1 - Главная</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f8ff;
        }
        .header {
            background: #4CAF50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 10px;
        }
        .content {
            background: white;
            padding: 20px;
            margin-top: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Добро пожаловать в Приложение 1!</h1>
        <p>Ваш надежный партнер в мире технологий</p>
    </div>

    <div class="content">
        <h2>О нашем приложении</h2>
        <p>Это первое приложение работает на безопасном HTTPS соединении через Nginx.</p>

        <h3>Наши преимущества:</h3>
        <ul>
            <li>Высокая производительность</li>
            <li>Безопасное соединение</li>
            <li>Круглосуточная поддержка</li>
        </ul>

        <div style="background: #e7f3ff; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <strong>Техническая информация:</strong>
            <br>Сервер: Nginx
            <br>Протокол: HTTPS
            <br>Домен: app1.local
        </div>
    </div>

    <footer style="text-align: center; margin-top: 30px; color: #666;">
        <p>© 2024 Приложение 1. Все права защищены.</p>
    </footer>
</body>
</html>
```

  app2
   
**Request:**
```bash
curl -k https://app2.local
```
**Response:**
```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Приложение 2 - Порталы</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #fff0f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            text-align: center;
            border-radius: 15px;
        }
        .content {
            background: white;
            padding: 25px;
            margin-top: 20px;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .feature {
            background: #f8f9fa;
            padding: 15px;
            margin: 10px 0;
            border-left: 4px solid #667eea;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌈 Приложение 2 - Порталы</h1>
        <p>Откройте новые горизонты возможностей</p>
    </div>

    <div class="content">
        <h2>Добро пожаловать в будущее!</h2>
        <p>Второе приложение демонстрирует работу виртуальных хостов в Nginx.</p>

        <h3>Наши возможности:</h3>
        <div class="feature">
            <strong>Многопользовательский режим</strong>
            <p>Работайте вместе с коллегами в реальном времени</p>
        </div>

        <div class="feature">
            <strong>Расширенная аналитика</strong>
            <p>Получайте детальные отчеты о вашей деятельности</p>
        </div>

        <div class="feature">
            <strong>Интеграции</strong>
            <p>Подключайте любимые сервисы и инструменты</p>
        </div>

        <div style="background: #e6f7ff; padding: 20px; border-radius: 10px; margin-top: 25px; text-align: center;">
            <h3>🔒 Безопасное соединение</h3>
            <p>Этот сайт защищен SSL сертификатом</p>
            <p><strong>Домен:</strong> app2.local</p>
            <p><strong>Статус:</strong> ✅ Защищено</p>
        </div>
    </div>

    <footer style="text-align: center; margin-top: 30px; color: #777; padding: 20px;">
        <p>Приложение 2 | Innovate. Create. Elevate.</p>
        <p style="font-size: 0.9em;">Виртуальный хост Nginx демонстрация</p>
    </footer>
</body>
</html>
```
Все отлично, разные сервера выдают разные html странички.  

Проверим работает ли сертификат:
**Request:**
```bash
 curl -kv https://app1.local 2>&1 | grep -E "(SSL certificate|subject:|issuer:|expire date:|HTTP/|Server:)"
```
**Response:**
```bash
*  subject: CN=localhost
*  expire date: Dec  4 16:45:19 2025 GMT
*  issuer: CN=localhost
*  SSL certificate verify result: self-signed certificate (18), continuing anyway.
* using HTTP/1.x
> GET / HTTP/1.1
< HTTP/1.1 200 OK
< Server: nginx/1.28.0
```

Сертификат тоже работает, только присутствует предупреждение о том, что он самоподписанный.

### Шаг 4. Настройка alias
Добавляем следующий код в app1.conf:

```nginx
  ...
  location /something/ {
        alias /home/dinis/projects/study/Clouds/lab1/incomprehensibleHTML/;
  }
  ...
```
Проверяем работоспособность:
**Request:**
```bash
  curl -k https://app1.local/something/
```
**Response:**
```html
  <!DOCTYPE html>
<html>
<head>
    <title>Тайная страница!</title>
    <style>
        body {
            font-family: Comic Sans MS;
            background: #ffe6f2;
            text-align: center;
            padding: 50px;
        }
        .secret {
            background: yellow;
            padding: 20px;
            border: 3px dashed red;
            margin: 20px;
            transform: rotate(-2deg);
        }
    </style>
</head>
<body>
    <div class="secret">
        <h1>🎉 Поздравляю! 🎉</h1>
        <h2>Вы нашли секретную страницу!</h2>
        <p>Здесь хранятся самые важные данные:</p>
        <p><strong>Ответ на главный вопрос:</strong> что-то</p>
        <p><strong>Секрет успеха:</strong> Больше кофе ☕</p>
        <p><strong>Мудрость дня:</strong> Если работает - не трогай!</p>
    </div>

    <p>🔐 Этот файл спрятан за alias'ом /something/</p>
    <p>👻 Призраки сервера одобряют!</p>
</body>
</html>
```
**P.S.** Все html файлы сгенерированы AI, я к ним причастия не имею!! :no_good:

## Вывод:
## Вывод

В процессе выполнения лабораторной работы я получил ценный практический опыт работы с веб-сервером Nginx и познакомился с ключевыми аспектами его конфигурации.

### Что нового я освоил:

- **Установка Nginx** - научился устанавливать веб-сервер из официальных репозиториев, что гарантирует стабильность и безопасность работы
- **SSL-сертификаты** - познакомился с механизмом создания самоподписанных сертификатов, разобрался в структуре CN (Common Name) и SAN (Subject Alternative Name)
- **Безопасность** - освоил настройку принудительного редиректа с HTTP на HTTPS, что является стандартом для современных веб-приложений
- **Виртуальные хосты** - научился организовывать обслуживание нескольких доменов на одном сервере через отдельные конфигурационные файлы
- **Alias директивы** - понял практическое применение `alias` для гибкого управления путями к ресурсам

### Технические инсайты:

- Осознал преимущества модульной структуры конфигурации через директорию `conf.d` для лучшей организации и масштабируемости
- На практике убедился в важности правильной настройки прав доступа к файлам для работы веб-сервера
- Понял разницу между работой в локальном окружении и продакшн-среде, особенно в контексте резолвинга доменных имен

Полученные навыки позволяют уверенно настраивать базовую инфраструктуру веб-сервера, что является фундаментальным умением в DevOps-практике. Работа дала понимание того, как организовано обслуживание веб-приложений в реальных проектах.
