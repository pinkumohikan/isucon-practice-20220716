.PHONY: *

gogo: stop-services build truncate-logs start-services bench

build:
	cd go && go build -o isucondition

stop-services:
	sudo systemctl stop nginx
	sudo systemctl stop varnish
	sudo systemctl stop isucondition.go
	ssh isucon111q-03 "sudo systemctl stop isucondition.go"
	ssh isucon111q-02 "sudo systemctl stop mysql"

start-services:
	ssh isucon111q-02 "sudo systemctl start mysql"
	sleep 5
	sudo systemctl start isucondition.go
	scp ./go/isucondition isucon111q-03:/home/isucon/webapp/go/isucondition
	ssh isucon111q-03 "sudo systemctl start isucondition.go"
	sudo systemctl start varnish
	sudo systemctl start nginx

truncate-logs:
	sudo truncate --size 0 /var/log/nginx/access.log
	sudo truncate --size 0 /var/log/nginx/error.log
	ssh isucon111q-02 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"

bench:
	cd ../bench && ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999

kataribe:
	sudo cat /var/log/nginx/access.log | ./kataribe -conf kataribe.toml | grep --after-context 20 "Top 20 Sort By Total"

save-log: TS=$(shell date "+%Y%m%d_%H%M%S")
save-log: 
	mkdir /home/isucon/logs/$(TS)
	sudo  cp -p /var/log/nginx/access.log  /home/isucon/logs/$(TS)/access.log
	ssh isucon111q-02  "sudo cp -p /var/log/mysql/mysql-slow.log  /home/isucon/mysql-slow.log && sudo chmod 777 /home/isucon/mysql-slow.log"
	scp -C isucon111q-02:/home/isucon/mysql-slow.log  /home/isucon/logs/$(TS)/mysql-slow.log
	sudo chmod -R 777 /home/isucon/logs/*
sync-log:
	scp -C kataribe.toml isucon-tool:~/
	rsync -av -e ssh /home/isucon/logs isucon-tool:/home/ubuntu  
analysis-log:
	ssh isucon-tool "sh push_github.sh"
gogo-log: save-log sync-log analysis-log
