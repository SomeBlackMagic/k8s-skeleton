Kubernetes skeleton.
====================
Базовый конфиг для создания кластера основан на kubespray

# Зависимости
* docker
* make

# Подготовка к использованию
* Скопируйте себе содержимое репозитория.
* Отредактируйте список нод в файле kubespray_config/inventory.ini
* Отредактируйте поле cluster_name в файле kubespray_config/group_vars/k8s_cluster/k8d-dns.yml указав свой технический домен
* Отредактируйте .env а именно MASTER_NODE_*

Список всех доступных команд можно получить выполнив ```make help```.


Команды делятся на 2 категории, работа с kubespray и доустановка софта из helm и yaml манифестов.
При первом запуске и создание кластреа выполняем:
* Билдим докер образ с kubespray ```make docker_build ```
* Запускаем установку нового кластера ```make kubespray_create```

Установка и обновление могут продлиться довольно долго.
Если кластер успешно установлен - то по итогу в PLAY RECAP в таблице с нодами не будет ни одной ошибки ``` failed=0 ```

Далее устанавливаем хелм и bash completion для kubectl на мастер ноду для дальнейшей установки софта
```
make pkg_install
```
## Базовые компоненты
Устанавливаем базовые компоненты такие как priority class и metrics server(тот что соберет базовые метрики для автоскейлинга) а так-же базовые сетевые политики
````
make base_config_apply
````
В конце выполнения можно видеть список сертификатов которые нужно принять для корректной работы metrics server. Это можно сделать командой ``` kubectl certificate approve csr-h24sp ```


## Устанавливаем сетевой драйвер cilium.
```
make cilium-install
```
При первой установке мы можем видеть ошибку
```
Error: execution error at (cilium/templates/validate.yaml:21:9): Service Monitor requires monitoring.coreos.com/v1 CRDs. Please refer to https://github.com/prometheus-operator/prometheus-operator/blob/master/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
```
Это потому-что у нас не установлен мониторинг.
Идем в configs/cilium/cilium.yaml, находим serviceMonitor(3 штуки) и выключаем его на время первой установки.
Далее повторно запускаем установку.
После успешной установки проверяем чтоб у всех нод был статус Ready

# Longhorn
Устанавливаем менеджер волюмов в кластер: ``` make longhorn_install```, предварительно закомментировав чарт мониторинг в Makefile.
После установки так-же нужно будет принять сертификаты которые в статусе Pending

## rancher monitoring
Для того чтоб ранчер корректно отображал метрики в веб интерфейсе нужно деплоить именно ранчеровский мониторинг.
```
make rancher_monitoring_install
```
После этого действия можно включить все места где мы не деплоили сервис аккаунты(cilium, longhorn) и передеплоить эти чарты теми-же командами

## Alert mapper
Утилита для перенаправления алерт ивентов из alert-manager в alerta(external self-hosted)
```
make alertMapper_install
```
После чего нужно добавить через ранчер таргет из алертменеджера в алерт маппер
Monitoring -> Routes and Receivers
Добавляем новый Receiver типа webhook c линкой ``` http://alert-mapper-app:3000/input/alert-manager/webhook ``` без авторизации