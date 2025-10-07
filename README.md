# Gitea Server

## Requirements

- docker

## Setup

Create a `.env` file like `.env.example` and fill in your values.

Start the containers:

```bash
docker compose up -d
```

Open the web interface at https://git.$DOMAIN

1. the database config should be filled out according to the docker-compose.yaml file
1. the Server Domain should be set to https://git.$DOMAIN
1. the SSH Port should be set to 22
1. make sure to check `Optional Settings` > `Server and Third-Party Service Settings` > `Disable Self-Registration`
1. create an admin account
1. click `Install Gitea`
1. done.

## Migration

### Backup Gitea Installation

```bash
# switch to user git
su git
# switch to dump directory
cd /dump
# create dump
./gitea dump -c /path/to/app.ini
```

You should end up with a file called `gitea-dump-<date>.zip` in the current directory, which contains all repositories and the database dump.

### Configuration

#### Actions

Actions have to be enabled per repository. This can be done in the UI.

##### Action Runners

To create an action runner, set up a new Ubuntu machine, install docker and follow the instructions from the [Gitea Docs](https://docs.gitea.com/usage/actions/act-runner).

Set up a CRON job in your runner to prune docker images:

```bash
crontab -e
0 2 * * * docker system prune -f --filter "until=12h"
```

This will prune all unused docker images older than 12 hours every day at 2am.

### Restore Gitea Installation

copy the dump files to the server and place them in the `/dump` directory. Then follow these steps, which are also described in the [Gitea Docs](https://docs.gitea.io/en-us/backup-and-restore/).

#### Repositories

```bash
# enter gitea container
docker exec -it 2a83b293548e bash
cd /dump/
unzip gitea-dump-<date>.zip

# restore the gitea data
cp -r data/* /data/gitea/

# restore the repositories itself
cp -r repos/* /data/git/repositories/
# maybe you have to create the directory first with
mkdir -p /data/git/repositories/

# restore the gitea config (see notes below)
mv -f gitea/conf/app.ini /data/gitea/conf/app.ini

# adjust file permissions
chown -R git:git /data

# done
exit
```

Note: the container id `2a83b293548e` is just an example, you have to use the correct one.

##### Gitea Config

If you just want to migrate the repositories and users, you don't want to restore the gitea config in `app.ini`. Just start the gitea container, and follow the setup process in the webinterface as described in the [Setup](#setup) section. Then replace the apps database with your dump and add the dumped repositories and other data to the shared volume `./gitea`.

#### Database

```bash
# enter database container
docker exec -it gitea_db_1 bash

# enter mysql shell
mysql -u root -p gitea
# enter root password from .env

# clear existing database
DROP DATABASE gitea;
CREATE DATABASE gitea;

# exit mysql shell
exit

# load dump
mysql -u root -p gitea < /dump/gitea-db.sql
# ... enter root password from .env


```

you might have to change the container name `gitea_db_1` to the correct one.

#### Webhooks

restore the webhooks by opening the web interface and navigating to

### Troubleshooting

#### Change the configuration of a running instance

you might notice that the webinterface displays the settings if you log in with the admin account, but it doesn't allow changing them. To change the settings, you have to edit the `app.ini` file in the gitea container.

```bash
# enter gitea container
docker exec -it 2a83b293548e bash

# edit the config
vi /data/gitea/conf/app.ini

# leave the container
exit

# restart the container
docker restart 2a83b293548e
```
