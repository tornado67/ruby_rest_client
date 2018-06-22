# ruby_rest_client
Ruby script for data gathering from some rest service and putting them to mysql

Из БД Zabbix'а скрипт получает самое раннее время пинга и самое позднее , читай начало и конец, после чего с REST-сервиса получает информаию об расписании объекта на которои находится компьютер. По определенным причина имеется два сервера Zabbix.


At first, script gets connectivity data from Zabbix database (means, when did agent.ping started and when did it gone) and then 

it gets time table information from some rest service for specified object, where agent is located.
