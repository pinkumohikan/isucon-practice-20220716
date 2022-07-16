.PHONY: *

gogo: stop-services build truncate-logs start-services bench

build:
	cd go && go build -o isucondition

stop-services:
	sudo systemctl stop nginx
	sudo systemctl stop isucondition.go
	sudo systemctl stop mysql

start-services:
	sudo systemctl start mysql
	sleep 5
	sudo systemctl start isucondition.go
	sudo systemctl start nginx

truncate-logs:
	sudo truncate --size 0 /var/log/nginx/access.log
	sudo truncate --size 0 /var/log/nginx/error.log
	sudo truncate --size 0 /var/log/mysql/mysql-slow.log

bench:
	cd .. && ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999

kataribe:
	cd ../ && sudo cat /var/log/nginx/access.log | ./kataribe