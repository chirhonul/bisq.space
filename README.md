# bisq.space

This repo holds tools and information about the bisq.space service.

The `bisq.space` service runs a [rocket.chat](https://rocket.chat) instance.

# features

See [rocket.chat](https://rocket.chat) documentation for general info about the
system.

The bisq.space instance is also configured with the following features enabled:

- 2fa support: using Google Authenticator or a similar app, a second factor can be required,
  so that username + password + 2fa token is needed to sign in
- end-to-end encryption enabled: users receive a code when first signing in, that along with username and password can be used
  to create encrypted chats where even the server operator can't see the data: https://rocket.chat/docs/user-guides/end-to-end-encryption/

# operational

## installation

The following outlines how to install the [rocket.chat](https://rocket.chat) software
and set it up at a new domain, following [this guide](https://rocket.chat/docs/installation/docker-containers/):

- get access to a new domain, if `bisq.space` is no longer to be used
- get access to physical or virtualized server to host the service
- add dns record to add an `A` record to the domain to resolve to the ipv4 address of the server
- connect to the server via ssh
- install package updates
- create regular user
- grant sudo access to the regular user
- add ssh key to `.ssh/authorized_keys`
- harden ssh: choose a nonstandard port, disable root access, disable password access
- install and enable `docker.io`, `fail2ban`, `nginx` packages
- install `certbot` following steps at: https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
- install docker-compose with: `sudo curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose`
- configure iptables: `sudo iptables-restore < iptables.conf`
- provision https certificate via letsencrypt.org with `certbot --nginx`, which also updates nginx config
- edit `/etc/nginx/sites-available/default` config to correspond to [`nginx-sites-default`](conf/nginx-sites-default)
- restart nginx with `sudo systemctl restart nginx`
- create data directories:
  - `sudo mkdir -p /var/www/rocket.chat/data/dump`
  - `sudo mkdir -p /var/www/rocket.chat/data/runtime/db`
- edit the [`docker-compose.yml`](conf/docker-compose.yml) to specify hubot password and domain name
- place the edited `docker-compose.yml` file in `/var/www/rocket.chat/`
- enable and start the systemd services [`rocket-db.service`](conf/rocket-db.service), [`rocket-chat.service`](conf/rocket-chat.service) and [`rocket-hubot.service`](conf/rocket-hubot.service)
  - copy the `.service` files to `/lib/systemd/system/` directory and do `sudo systemctl daemon-reload`
- the service should be running and accessible via https now!
  - visit it and create the hubot account with credentials as in `docker-compose.yml` manually

## hardware

The service currently runs on a single dedicated server:

- CPU: Intel® Celeron® Processor G3900T 2C/2T (2M Cache, 2.60 GHz)
- RAM: 16GB DDR4 ECC
- 1 HDD: 3.5" 1TB 6GB/S SATA3
- 2 HDD: 3.5" 1TB 6GB/S SATA3
- RAID Array: RAID 1 (Mirroring)

## maintenance

- follow nginx logs with `sudo tail -f /var/log/nginx/*.log`
- follow main service logs with `sudo journalctl -fu rocket-chat`
- follow all system logs with `sudo journalctl --all -f`
- add new ip ranges of misbehaving bots to `iptables.conf` and update with `sudo iptables-restore < iptables.conf`
- watch system metrics locally with `htop`

## backups

See the [`backup.sh`](scripts/backup.sh) script for a tool that can be run locally to archive configs
and data. Run from root of repo as:

```
$ bash scripts/backup.sh
```

We want to automatically run the script above to capture any changes to configs, and to have daily backup
of data in the form of tarballs, which should be encrypted to a small number of contributors.

There is a one-time setup step to copy the companion script `backup_remote.sh` remotely:

```
$ scp scripts/backup_remote.sh s3:/usr/local/bin/
```

## monitoring

We want to detect automatically if the service is unavailable and to be notified so we can
address the issue.

### blackbox

We want to monitor that:

- dns records for `bisq.space` are as expected
- server responds to ping
- `tcp/443` socket can be opened
- https response contains expected strings
- (maybe) user can log in and send messages

### whitebox

We want to have metrics and timeseries on:

- log exporting / aggregation
- system metrics: disk, cpu, memory, load
- (maybe) number of users, channels, messages

## known issues

### registration is slow

When registering as a new user, there's a "loading" screen after sign-up that takes
a very long time or never completes. When the user reloads, the chat service loads fine.
