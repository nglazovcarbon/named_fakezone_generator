# Unbound fakezone generator
Генератор зон для unbound для списка доменов, которые необходимо перекидывать на заглушку, настроенную по гайду [https://github.com/carbonsoft/reductor_blockpages](https://github.com/carbonsoft/reductor_blockpages)

Это, возможно временный и неидеальный, но несколько более быстрый способ решения проблемы с фильтрацией HTTPS-ресурсов, меняющих IP адреса, чем реализация прокси/плагина для прокси, позволяющего фильтровать большие объёмы трафика с подменой сертификата или обхода DNSSEC в модуле xt_dnsmatch.
- [Установка](#Установка)
- [Использование](#Использование)
- [Автоматизация](#Автоматизация)
- [Принцип действия](#Принцип-действия)
- [Примечания](#Примечания)

## Окружение
Вся эта схема рассчитана на использование на уже имеющиемся и реально используемом абонентами/ревизором DNS-сервере провайдера. **Устанавливать DNS-сервер unbound на Carbon Reductor пока что не рекомендуется** (возможно будет доступно из коробки потом).

## Установка

Если unbound не установлен, необходимо выполнить:

```
yum -y install unbound
mkdir /var/run/unbound
unbound-control-setup
service unbound restart
```

В случае CentOS 6 установка будет выглядеть следующим образом:

```
yum -y install git
git clone https://github.com/carbonsoft/named_fakezone_generator.git /opt/named_fakezone_generator/
cp /opt/named_fakezone_generator/unbound/main.sh.example /opt/named_fakezone_generator/unbound/main.sh
```

## Использование

Укажите в /opt/named_fakezone_generator/unbound/main.sh IP адрес Carbon Reductor.

### Получение списка доменов

Если SSH ключи отсутствуют, генерируем их:

```
ssh-keygen
```

Затем добавляем их на Carbon Reductor:

```
ssh-copy-id root@<ip адрес carbon reductor>
```

Проверяем что scp не запрашивает пароль и выкачивает файл:

```
/opt/named_fakezone_generator/unbound/main.sh
```

Добавляем вызов в Cron.

```
echo '*/20 * * * * root /opt/named_fakezone_generator/unbound/main.sh' > /etc/cron.d/unbound_fakezone_generator
```


## Принцип действия

- Выкачиваем новый список доменов, которые нужно блокировать
- Пытаемся добавить разницу/удалить разблокированные домены с помощью diff_load.sh
    - Разница автоматически вычисляется из скачанного файла и используемого в текущий момент /etc/unbound/local.d/reductor.conf
    - Добавление и удаление производится через unbound-control local_zone/local_data/local_zone_remove
- Если не получилось (нажали ctrl+c или что-то ещё произошло) - вызывается unbound-control reload
- Если не вышло и это (например сервер был выключен) - service unbound restart

## Примечания
Само собой не обязательно чтобы все команды запускались от имени root. Здесь это только для примера, если настроите (и убедитесь, что всё правильно работает) от ограниченных учёток - чудесно.
