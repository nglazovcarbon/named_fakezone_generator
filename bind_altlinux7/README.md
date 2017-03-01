# Named fakezone generator

**Версия для систем с bash3.2 и bind, работающем в chroot (тестировалось на altlinux 7, принципиальных зависящих от дистрибутива моментов нет)**

Генератор зон для named/bind9 для списка доменов, которые необходимо перекидывать на заглушку, настроенную по гайду https://github.com/carbonsoft/reductor_blockpages

Это, возможно временный и неидеальный, но несколько более быстрый способ решения проблемы с фильтрацией HTTPS-ресурсов, меняющих IP адреса, чем реализация прокси/плагина для прокси, позволяющего фильтровать большие объёмы трафика с подменой сертификата или обхода DNSSEC в модуле xt_dnsmatch.

  * [Установка](#Установка)
  * [Обновление](#Обновление)
  * [Использование](#Использование)
  * [Автоматизация](#Автоматизация)
  * [Принцип действия](#Принцип-действия)
  * [Примечания](#Примечания)

## Окружение

Вся эта схема рассчитана на использование на уже имеющиемся и реально используемом абонентами/ревизором DNS-сервере провайдера. **Устанавливать DNS-сервер bind/named на Carbon Reductor пока что не рекомендуется** (возможно будет доступно из коробки потом).

## Установка

В целом нам понадобятся:

- **git** чтобы склонировать этот репозиторий
- **m4** чтобы генерировать записи из шаблона
- сам **bind9/named**, предполагается, что он уже установлен

В случае CentOS 6 установка будет выглядеть следующим образом:

    yum -y install git m4
    git clone https://github.com/carbonsoft/named_fakezone_generator.git /opt/named_fakezone_generator/

Допишите в конец файла /etc/named.conf:

    include "/etc/named.reductor.zones";

## Обновление

``` bash
cd /opt/named_fakezone_generator/
git status
git add -p
git commit -m "Changes made by provider"
git pull origin master
./main.sh
```

## Использование

Запустите:

    ./generate_bind_configs.sh <путь до файла со списком доменов> <ip адрес заглушки>

## Настройка

```
cp etc/sysconfig/named_fakezone_generator /etc/sysconfig/named_fakezone_generator
vim /etc/sysconfig/named_fakezone_generator
```

Внутри поменяйте IP адрес редуктора, чтобы по SCP забирать с него список доменов для блокировки.

Если bind работает без chroot - удалите записи ZONES_CONF и ZONES, если с chroot - оставьте.
```
REDUCTOR_IP=10.0.0.1

# only if you work in chroot
ZONES_CONF=/var/lib/bind/etc/named/reductor_zones.conf
ZONES=/var/lib/bind/etc/named.reductor.zones

# even if you work in chroot
ZONES_CONF_PATH=/etc/named/reductor_zones.conf
```

## Автоматизация

### Генерация зон

```
cp main.sh_example main.sh
```

Если всё устраивает - добавьте вызов в крон, например так:

```
echo '*/20 * * * * root /opt/named_fakezone_generator/bind_altlinux7/main.sh' > /etc/cron.d/named_fakezone_generator
```

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

Генерирует следующие файлы:

Список блокируемых зон

```
/etc/named.reductor.zones
```

Файл с описанием зоны (общий для всех)

```
/etc/named/reductor_zones.conf
```

Больше подробностей можно узнать непосредственно посмотрев файлы ```generate_bind_configs.sh``` и ```reductor_named_domain.tmplt```.

## Примечания

Само собой не обязательно чтобы все команды запускались от имени root. Здесь это только для примера, если настроите (и убедитесь, что всё правильно работает) от ограниченных учёток - чудесно.
