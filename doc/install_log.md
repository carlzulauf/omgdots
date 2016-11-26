# Installation Log

Notes on steps taken while trying to create a server env for omgdots.

## Host Environment

Using personal server with VM running Ubuntu Server 16.04.

VM provided by Oracle VirtualBox. Host is running 14.04. Everything seems to work well with synergy, which is a little surprising. Installation took a while but was pretty easy and uneventful. Really wish it required less attention.

Chose "standard system utilities" and "OpenSSH server" on "Software selection" screen during install. Yes, grub on MBR.

VM has 512MB of RAM and 16GB storage.

## Server environment

Copied `.ssh/authorized_keys` from personal server to `carl`.

`carl` is admin user.

Create `deploy` user:

    $ sudo adduser deploy

Used a really long random password. Won't really be used.

Install some stuff as `carl`:

    $ sudo apt install ruby pry build-essential redis-server git tmux libreadline6-dev libssl-doc libssl1.0.0 libtinfo-dev nginx libffi-dev libgdbm-dev libncurses5-dev libreadline-dev libssl-dev libyaml-dev zlib1g-dev

Somehow `git` and `tmux` were already installed. The latter is very surprising.

Grant access to `deploy` user

    $ sudo mkdir /home/deploy/.ssh
    $ sudo cp /home/carl/.ssh/authorized_keys /home/deploy/.ssh
    $ sudo chown -R deploy:deploy /home/deploy/.ssh

From the `carl` account install **ruby-install** from instructions here: https://github.com/postmodern/ruby-install#install

From `deploy` account use ruby-install to install a user ruby.

    $ ruby-install --no-install-deps ruby 2.3.3

Install chruby through `carl` account from instructions: https://github.com/postmodern/chruby#install

Also run setup.sh to install chruby into `/etc/profile.d/`

    $ sudo ./scripts/setup.sh

Add default ruby and rails env to `~/.bashrc`. Also maybe change force color option while there.

    chruby ruby-2.3.3
    export RAILS_ENV=staging

Create deploy directory (as `carl`)

    sudo mkdir -p /var/www/omgdots
    sudo chown deploy:deploy /var/www/omgdots

Setup capistrano. Create `.env` with `SECRET_KEY_BASE` and place in `/var/www/omgdots/shared/.env`.

Install bundler gem manually on deploy user's chruby.

    $ chruby ruby-2.3.3
    $ gem install bundler

Install nginx config (`doc/nginx.conf`) to `/etc/nginx/sites-available/omgdots`. Copy certs to `/var/www/omgdots/certs` and ensure name matches nginx conf.

    $ cd /etc/nginx/sites-enabled
    $ sudo ln -s /etc/nginx/sites-available/omgdots omgdots
    $ sudo service nginx restart

Copy `doc/puma.service` to `/etc/systemd/system` and install service.

    $ sudo systemctl enable puma.service
    $ sudo systemctl start puma.service

Give `deploy` the ability to restart puma.

    $ sudo visudo
    # add the following line
    deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart puma.service

Deploy app. Run capistrano from dev environment.

    $ cap staging deploy

## Production Host Environment

DigitalOcean 512MB droplet.

IP: 104.236.122.39

## Production Server Environment

Or, really, the differences from staging

`root` is admin user

Install letsencrypt to get ssl certs

    $ apt install letsencrypt

Stop nginx

    $ systemctl stop nginx

Start certbot server to validate domain and get certs

    $ letsencrypt certonly --standalone -d omgdots.win

Validate that renewal works

    $ letsencrypt renew --dry-run --agree-tos

Add twice daily renewal to crontab. Actually renews less frequently. Expires after 90 days.

    # m h  dom mon dow   command
    51 5,17 * * *  /usr/bin/letsencrypt renew
