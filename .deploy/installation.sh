#!/bin/bash

add-apt-repository -y ppa:chris-lea/redis-server
add-apt-repository -y ppa:nginx/stable
add-apt-repository -y ppa:pypy/ppa

apt-get update && apt-get upgrade -y

apt-get install -y \
    nginx-full git-core ngrep screen bash-completion htop gcc logtop \
    python-virtualenv ipython python-dev pypy supervisor redis-server \
    golang golang-go golang-go.tools gccgo-go mercurial

cat >> ~/.bashrc << END
export GOROOT=/usr/lib/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
END
source ~/.bashrc
pkill -9 lpg-events; rm -rf /usr/bin/lpg-events; make install

# For Ubuntu 12.04
if [ -f /etc/bash_completion.d/git-prompt ]; then ln -sf /etc/bash_completion.d/git-prompt /etc/bash_completion.d/git; fi
if [ -d /usr/include/freetype2 ]; then ln -sf /usr/include/freetype2 /usr/include/freetype; fi

mkdir -p /srv/projects/notify.lpgenerator.ru
cd /srv/projects/notify.lpgenerator.ru
git clone --depth 1 git@github.com:LPgenerator/lpg-notify-ws.git www
cp ./www/.deploy/.screenrc ~/.screenrc
cp ./www/.deploy/.bashrc.sh ~/.bashrc
. ~/.bashrc
cd /srv/projects/notify.lpgenerator.ru
virtualenv -p /usr/bin/pypy venv
cd www
mkdir logs

chown -R www-data:www-data /srv/

. ../venv/bin/activate
pip install -r requirements.txt

cp .deploy/nginx/notify.lpgenerator.ru.conf /etc/nginx/sites-available/
cp .deploy/nginx/nginx.conf /etc/nginx/
cp .deploy/supervisor/notify.lpgenerator.ru.conf /etc/supervisor/conf.d/
cp .deploy/sys/sysctl.conf /etc/sysctl.conf
cp .deploy/sys/limits.conf /etc/security/limits.conf
sysctl -p

ln -sf /etc/nginx/sites-available/notify.lpgenerator.ru.conf /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
ln -sf /bin/bash /bin/sh

touch /usr/bin/lpgpy && chmod +x /usr/bin/lpgpy && cat > /usr/bin/lpgpy << END
#!/bin/bash

PROJECT_PATH="/srv/projects/notify.lpgenerator.ru"
PYTHON="\$PROJECT_PATH/venv/bin/python"

exec -a lpgpy sudo -u www-data -H \$PYTHON -OO "\$@"
END

update-rc.d redis-server defaults
update-rc.d supervisor defaults
update-rc.d nginx defaults

## SSH KEYS
# Angel
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVJLz3V1+r6J/83+el8hwYSDQ7u/Xj6MYMje3yS/7JxjpRP3X6Kt7/uLcc+L0+CMlM0KRkN5q5SPD5yG5OgNTKmF3zkcDaoCn33WS6LQr2wVQfUfvyrkmr5/4PaQJhujp6B/j2uwuMYjYtldhFlBxTNS/pxtH5wBfBR18otNnQtPrF6nJeWYG2cT5b9ngjHRC1Bp9SWvR0h7bee1BcZZW0UYAgbPXiKVBJeVW1Qi0WCN+D1twV4hFvh0YmpiZ3nDycSNJcM1JoAx6liuybzbFluVFQ3cs/RLkwXHLUz+g8dwx6Uxicvh7u6kb2ylnAzhYqHAwcmadH2EnDnev7oH5H denis.kabalkin@gmail.com' >> /root/.ssh/authorized_keys
# GoTLiuM
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHwBd/evcG5cCzaSju1exC77Fo8txHGqtDHYAf8o5VjcIdSZK30CSrRosiDvpXSsLee18A+UY4yPxERgBqDLQbG50rD2Ddl46/MXJMnwgBuGkOqEuAUoQTS5sIJNaFTZ1urrIqsDb9YNT6/LyX7QegCmuKf4QLp9/RaPCQg+emNjrdiP5uTAhI+AbzLoKiTxwBnYjB2rnlcOMucwFusBvjo0D1NnZwv/0p69J4AcbdgunTOgK7Gsim/GBbln0rvSMR0ZGMSj14hpLqBuH3zlS4fiToxY+dMSbJEz0AkingNTMmT6KMBe6tpPWuRBgdVdI7W3ELoc3M2RgrXCgmpNI9 gotlium@MacBook-Pro-Ruslan.local" >> /root/.ssh/authorized_keys

/etc/init.d/nginx restart
/etc/init.d/supervisor stop; /etc/init.d/supervisor start
/etc/init.d/redis-server restart
supervisorctl status
