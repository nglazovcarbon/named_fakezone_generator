# Unbound fakezone generator

Генератор зон для unbound для списка доменов, которые необходимо перекидывать на заглушку, настроенную по гайду https://github.com/carbonsoft/reductor_blockpages

Это, возможно временный и неидеальный, но несколько более быстрый способ решения проблемы с фильтрацией HTTPS-ресурсов, меняющих IP адреса, чем реализация прокси/плагина для прокси, позволяющего фильтровать большие объёмы трафика с подменой сертификата или обхода DNSSEC в модуле xt_dnsmatch.

  * [Установка](#Установка)
  * [Использование](#Использование)
  * [Автоматизация](#Автоматизация)
  * [Принцип действия](#Принцип-действия)
  * [Примечания](#Примечания)

## Окружение

Вся эта схема рассчитана на использование на уже имеющиемся и реально используемом абонентами/ревизором DNS-сервере провайдера. **Устанавливать DNS-сервер unbound на Carbon Reductor пока что не рекомендуется** (возможно будет доступно из коробки потом).

## Установка

В целом нам понадобятся:

- **git** чтобы склонировать этот репозиторий
- **m4** чтобы генерировать записи из шаблона
- сам **unbound**, предполагается, что он уже установлен

Если unbound не установлен, необходимо выполнить:

    yum -y install unbound
    unbound-control-setup
    service unbound restart

В случае CentOS 6 установка будет выглядеть следующим образом:

    yum -y install git m4
    git clone https://github.com/carbonsoft/named_fakezone_generator.git /opt/named_fakezone_generator/

## Использование

Запустите:

    /opt/named_fakezone_generator/unbound/generate_bind_configs.sh <путь до файла со списком доменов> <ip адрес заглушки>

## Автоматизация

### Генерация зон

Если всё устраивает - добавьте вызов в крон, например так:

    echo '*/20 * * * * root /opt/named_fakezone_generator/unbound/generate_bind_configs.sh /tmp/reductor.https.resolv 10.50.140.73' > /etc/cron.d/unbound_fakezone_generator

### Получение списка доменов

Не забудьте добавить запись, которая периодически забирает файл https.resolv с Carbon Reductor. Это можно сделать следующим образом:

Если SSH ключи отсутствуют, генерируем их:

    ssh-keygen

Затем добавляем их на Carbon Reductor:

    ssh-copy-id root@<ip адрес carbon reductor>

Проверяем что scp не запрашивает пароль и выкачивает файл:

    scp root@<ip адрес carbon reductor>:/usr/local/Reductor/lists/https.resolv /tmp/reductor.https.resolv

При сильном желании, если хочется держать и менять IP адрес заглушки в одном месте, можно забирать аналогично с Carbon Reductor файл /usr/local/Reductor/userinfo/config внутри обёртки в духе, которую вызывать по крону:

    #!/bin/bash

    scp root@<ip адрес carbon reductor>:/usr/local/Reductor/userinfo/config /tmp/reductor.config
    scp root@<ip адрес carbon reductor>:/usr/local/Reductor/lists/https.resolv /tmp/reductor.https.resolv
    source /tmp/reductor.config
    /opt/named_fakezone_generator/generate_bind_configs.sh /tmp/reductor.https.resolv "${filter['dns_ip']}"

## Принцип действия

### Генерация конфигов

Список блокируемых доменов

    /etc/unbound/local.d/reductor.conf

### Добавление новых доменов

- Пытаемся добавить разницу/удалить разблокированные домены с помощью diff_load.sh
    - Добавление и удаление производится через unbound-control local_zone/local_data
- Если не получилось - unbound-control reload
- Если не вышло и это - service unbound restart

## Примечания

Само собой не обязательно чтобы все команды запускались от имени root. Здесь это только для примера, если настроите (и убедитесь, что всё правильно работает) от ограниченных учёток - чудесно.
