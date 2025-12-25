# Лабораторная работа 1. Знакомство с IaaS, PaaS, SaaS сервисами в облаке на примере Amazon Web Services (AWS). Создание сервисной модели.

### Вариант 10
### Выполнил: Янченко Денис


## Описание работы

### Цель работы:
Знакомство с облачными сервисами. Понимание уровней абстракции над инфраструктурой в облаке. Формирование понимания типов потребления сервисов в сервисной-модели. 

### Дано:
- Слепок данных биллинга от провайдера после небольшой обработки в виде SQL-параметров. Символ % в начале/конце означает, что перед/после него может стоять любой набор символов.
- Образец итогового соответствия, что желательно получить в конце. В этом же документе  


### Необходимо:
- Импортировать файл .csv в Excel или любую другую программу работы с таблицами. Для Excel делается на вкладке Данные – Из текстового / csv файла – выбрать файл, разделитель – точка с запятой.
- Распределить потребление сервисов по иерархии, чтобы можно было провести анализ от большего к меньшему (напр. От всех вычислительных ресурсов Compute дойти до конкретного типа использования - Выделенной стойка в датацентре Dedicated host usage).
- Сохранить файл и залить в соответствующую папку на Google Drive.

### Алгоритм работы:
Сопоставить входящие данные от провайдера с его же документацией. Написать в соответствие колонкам справа значения 5 колонок слева, которые бы однозначно классифицировали тип сервиса. Для столбцов IT Tower и Service Family значения можно выбрать из образца.


### Ход работы

Изначально была получена следующая таблица:
<img width="665" height="622" alt="image" src="https://github.com/user-attachments/assets/25082b98-e78d-4d92-b246-2b4f634cddc3" />  
Заходим на [сайт с официальной документацией AWS](https://docs.aws.amazon.com/) и проходим по каждому `Product code` из таблицы, заполняя данные первых 5 столбцов. Для столбцов 1 и 2 используем значения их примера.    


В результате получается следующая таблица:  
<img width="1600" height="765" alt="image" src="https://github.com/user-attachments/assets/96c8c9bd-4a45-45ae-9609-a4bc04e869e5" />  


## Описание облачных сервисов AWS из таблицы

### Amazon S3 - IaaS
Amazon Simple Storage Service (Amazon S3) is storage for the internet. You can use Amazon S3 to store and retrieve any amount of data at any time, from anywhere on the web.

### Amazon QLDB
На данный момент документации по этому сервису недоступна на официальном сайте. Предположительно сервис больше не функционирует.  

### Amazon Redshift - PaaS
Amazon Redshift is a fast, fully managed, petabyte-scale data warehouse service that makes it simple and cost-effective to efficiently analyze all your data using your existing business intelligence tools. It is optimized for datasets ranging from a few hundred gigabytes to a petabyte or more.

### Amazon VPC - IaaS
Amazon Virtual Private Cloud (Amazon VPC) enables you to provision a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you've defined.

### Amazon SES - PaaS
Amazon Simple Email Service (Amazon SES) is a reliable, scalable, and cost-effective email service. Digital marketers and application developers can use Amazon SES to send marketing, notification, and transactional emails.

### Amazon SNS - PaaS
Amazon Simple Notification Service (Amazon SNS) is a web service that enables applications, end-users, and devices to instantly send and receive notifications from the cloud.

## Вывод
В ходе выполнения лабораторной работы были проанализированы и описаны 5 сервисов Amazon, а также получены данные о подтипах этих сервисов и других характеристиках.
