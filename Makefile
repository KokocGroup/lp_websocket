ARGS=$(filter-out $@,$(MAKECMDGOALS))
BRANCH=`git rev-parse --abbrev-ref HEAD`
ENV=`basename "$PWD"`

.PHONY: run
# target: run - Run Django development server
run: kill_server
	@python -m tornado.autoreload ws-notify.py --logging=debug

.PHONY: help
# target: sync - sync with remote server
sync:
	@rsync -auv ../ws-notify/ root@5.9.106.21:/srv/projects/notify.lpgenerator.ru/www/

.PHONY: vagrant-up
# target: vagrant-up - Start Vagrant
vagrant-up:
	@vagrant status|grep running >&/dev/null && exit 1 || true
	@VBoxManage hostonlyif remove vboxnet1 >& /dev/null || true
	@uname -s|grep Darwin >&/dev/null && (vagrant plugin list|grep parallels >&/dev/null || vagrant plugin install vagrant-parallels)
	@vagrant status|grep suspended >&/dev/null && vagrant resume || (uname -s|grep Darwin >&/dev/null && vagrant up --provider=parallels || vagrant up)

.PHONY: vagrant-down
# target: vagrant-down - Stop Vagrant
vagrant-down:
	@vagrant status|grep running >&/dev/null || exit 1
	@vagrant suspend || vagrant halt

.PHONY: vagrant-destroy
# target: vagrant-destroy - Destroy Vagrant Files
vagrant-destroy:
	@vagrant destroy -f

.PHONY: vagrant-browser
# target: vagrant-browser - Open all what you need for development
vagrant-browser:
	@open http://vagrant.lpgenerator.ru/ || xdg-open http://vagrant.lpgenerator.ru/
	@open http://vagrant.lpgenerator.ru:1080/ || xdg-open http://vagrant.lpgenerator.ru:1080/
	@open http://vagrant.lpgenerator.ru:5555/ || xdg-open http://vagrant.lpgenerator.ru:5555/
	@open http://vagrant.lpgenerator.ru:9999/ || xdg-open http://vagrant.lpgenerator.ru:9999/

.PHONY: pull
# target: pull - Git pull origin CURRENT-BRANCH
pull: clean
	@git pull origin `git rev-parse --abbrev-ref HEAD`
	@git log --name-only -1|grep migrations >& /dev/null && ./manage.py migrate --noinput || true
	@test -f touch.reload && touch touch.reload || true

.PHONY: push
# target: push - Git push origin CURRENT-BRANCH
push: clean
	@git status --porcelain|grep -v '??' && (echo '\033[0;32mCommit message:\033[0m' && MSG=`rlwrap -o -S "> " cat` && git commit -am "$$MSG") || true
	@git push origin $(BRANCH) || (git pull origin $(BRANCH) && git push origin $(BRANCH))

.PHONY: reset
# target: reset - Reset branch for two commits
reset: clean
	@git rev-parse --abbrev-ref HEAD|grep master >& /dev/null && false || true
	@git reset --soft `git log --pretty=format:"%H" master.. | tail -1`
	@git status --porcelain|grep -v '??' && (echo '\033[0;32mCommit message:\033[0m' && MSG=`rlwrap -o -S "> " cat` && git commit -am "$$MSG") || true
	@git push origin `git rev-parse --abbrev-ref HEAD` -f

.PHONY: pull-from-reset
# target: pull-from-reset - Reset branch and pool after reset
pull-from-reset: clean
	@git rev-parse --abbrev-ref HEAD|grep master >& /dev/null && false || true
	@git stash
	@git reset --hard `git log --pretty=format:"%H" master.. | tail -1`
	@git pull origin `git rev-parse --abbrev-ref HEAD` -f
	@test -f touch.reload && touch touch.reload || true

.PHONY: help
# target: help - Display callable targets
help:
	@egrep "^# target:" [Mm]akefile | sed -e 's/^# target: //g'

kill_server:
	@ps aux|grep [w]s-notify.py|awk '{print $2}'|xargs kill -9 >& /dev/null; true

%:
	@:

