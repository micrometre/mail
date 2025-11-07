.PHONY: start stop restart update clean_purge

start:
	docker compose up -d

stop:
	docker compose down

restart:
	docker compose restart

update:
	docker compose down 
	docker compose pull
	docker compose up -d --build

clean_purge:
	docker compose down -v
	docker compose rm -f
	docker volume ls -q | xargs -r docker volume rm -f
	docker system prune -f --volumes