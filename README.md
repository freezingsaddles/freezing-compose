# Freezing Saddles Docker Compose Files

This project is for deploying the Freezing Saddles application for either development or production.

Before you get started, we assume you have already installed [Docker](https://docker.com) and [Docker Compose](https://docs.docker.com/compose/).


## 1. Development

You can use the `docker-compose.dev.yml` file, in conjunction with the main `docker-compose.yml` file,
to spin up services that might be needed during development, but not production.

The `docker-compose.yml` file does not define a service for the database, but the `docker-compose.dev.yml` file does.

### 1.1 Clone Repository

Start by cloning this repository on your development workstation.

For example:

```shell
git clone https://github.com/freezingsaddles/freezing-compose
```

Now you can confirm that docker-compose is working correctly by changing to that directory and executing `docker-compose` commands.

```shell
cd freezing-compose
docker-compose ps
```

You should see lots of warnings about undefined configuration variables. Good! We will get to that next.

### 1.2 Configure Environment Variables for `docker-compose` in `.env` file

Copy the `example.env` file to a file named `.env`.  This is where `docker-compose` will look for environment variables.
```shell
cp sample-env .env
# edit the environment
vi .env
```

See [sample.env](sample.env) for a complete annotated example of a docker-compose `.env` file.

These environment variables will be passed in to the various services that need them. Look through them the `docker-compose.yml` file to see how that works.

For development, you won't need all the values, so don't worry about needing to set up a Strava app or Datadog account before you begin developing.

### 1.3 Configure and Start MySQL Only

We recommend that for development, you run MySQL through Docker and `docker-compose`. To start up 
start up MySQL using `docker-compose`, follow these steps:

1. Make sure that you have edited your `.env` file to have different passwords for MYSQL_ROOT_PASSWORD and MYSQL_PASSWORD
2. Create the named volume Docker will use for the MySQL database
3. Start the MySQL container

```shell
# Edit your .env file and pick new passwords
vi .env

# If you have not already, you first need to create these named volumes:
docker volume create --name=freezing-data

# Then you can start MySQL container
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d mysql

# MySQL will take up to 60 seconds to become ready, you can monitor 
docker logs freezing-mysql 2>&1 | tail
```

The output from the `docker logs` command will look something like this once the server is up and running:

```
2019-12-01 04:04:23 1 [Note] RSA public key file not found: /var/lib/mysql//public_key.pem. Some authentication plugins will not work.
2019-12-01 04:04:23 1 [Note] Server hostname (bind-address): '*'; port: 3306
2019-12-01 04:04:23 1 [Note] IPv6 is available.
2019-12-01 04:04:23 1 [Note]   - '::' resolves to '::';
2019-12-01 04:04:23 1 [Note] Server socket created on IP: '::'.
2019-12-01 04:04:23 1 [Warning] Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory.
2019-12-01 04:04:23 1 [Warning] 'proxies_priv' entry '@ root@freezing-mysql' ignored in --skip-name-resolve mode.
2019-12-01 04:04:23 1 [Note] Event Scheduler: Loaded 0 events
2019-12-01 04:04:23 1 [Note] mysqld: ready for connections.
Version: '5.6.46'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server (GPL)
```


### 1.3 Connecting to the database
To connect to the database, you can run a local mysql client if you already have one installed.

You can use Docker to connect to the database. The commands required are long and tedious, so create a shell alias for it. Substitute your values for the password and other configurable settings into the aliases below and run these at a shell prompt:
```shell
alias mysql-freezing='docker run -it --rm --network=host mysql:5.6 mysql --host=127.0.0.1 --port=3306 --user=freezing --password=please-change-me-as-this-is-a-default --database=freezing --default-character-set=utf8mb4'
alias mysql-freezing-non-interactive='docker run -i --rm --network=host mysql:5.6 mysql --host=127.0.0.1 --port=3306 --user=freezing --password=please-change-me-as-this-is-a-default --database=freezing --default-character-
alias mysql-freezing-root='docker run -it --rm --network=host mysql:5.6 mysql --host=127.0.0.1 --port=3306 --user=root --password=terrible-root-password-which-should-be-changed --database=freezing --default-character-set=utf8mb4'
alias mysql-freezing-root-non-interactive='docker run -i --rm --network=host mysql:5.6 mysql --host=127.0.0.1 --port=3306 --user=root --password=terrible-root-password-which-should-be-changed --database=freezing --default-character-set=utf8mb4'set=utf8mb4'
```

You can put these aliases in your `$HOME/.profile` or `$HOME/.bashrc` files to make them stick.

```shell
$ mysql-freezing
Warning: Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 6
Server version: 5.6.46 MySQL Community Server (GPL)

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> status
--------------
mysql  Ver 14.14 Distrib 5.6.46, for Linux (x86_64) using  EditLine wrapper

Connection id:		6
Current database:	freezing
Current user:		freezing@172.19.0.1
SSL:			Not in use
Current pager:		stdout
Using outfile:		''
Using delimiter:	;
Server version:		5.6.46 MySQL Community Server (GPL)
Protocol version:	10
Connection:		127.0.0.1 via TCP/IP
Server characterset:	utf8mb4
Db     characterset:	utf8mb4
Client characterset:	utf8mb4
Conn.  characterset:	utf8mb4
TCP port:		3306
Uptime:			7 min 55 sec

Threads: 1  Questions: 7  Slow queries: 0  Opens: 67  Flush tables: 1  Open tables: 60  Queries per second avg: 0.014
--------------

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| freezing           |
+--------------------+
2 rows in set (0.01 sec)

mysql> quit
Bye
```
Due to a quirk of Docker, you will need to use the `mysql-freezing-non-interactive` and `mysql-freezing-root-non-interactive` aliases when you redirect the input of MySQL, such as when loading a database dump.

### 1.4 Optional: Loading a MySQL data dump

This is probably the most convenient way to get started with Freezing Saddles development, but it is optional; if you don't have a dump file, the first time the `freezing-web` container is run it will populate the schema and baseline tables using the Alembic database migration toolkit.

If you have a MySQL dump (e.g. of the production database), you can load it into a fresh database like this:
```shell
$ mysql-freezing-root-non-interactive < freezing-2019-03-20-fixed.sql
$ # Or if you have configured the mysql-freezing-root-non-interactive alias:
$ mysql -h 127.0.0.1 -u root -p freezing < freezing-2019-03-20-fixed.sql
Enter password: <type in the root password you configured above>
```

Note: if you have trouble with using `127.0.0.1` try `localhost`. Different combinations of Docker and host operating systems and MySQL may have quirks that make one or the other fail. MySQL may assume that you are using a server that is listening on a local unix socket, which won't work since  MySQL in the container only has an exposed listener via TCP/IP.

### 1.5 Recreating the MySQL database
If you ever want to destroy and recreate your MySQL database, just remove the container and volume and re "up" it:

```shell
docker-compose -f docker-compose.yml -f docker-compose.dev.yml stop mysql
docker-compose -f docker-compose.yml -f docker-compose.dev.yml rm mysql

docker volume rm freezing-data && \
    docker volume create --name=freezing-data && \
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d mysql
# If you have trouble, you might need to do a `docker rm XXXXXX` where XXXXXX is
# the ID of a stopped freezing-mysql container, then repeat the above commands.
```

### 1.6 Running `freezing-web` and Other Containers via `docker-compose`

Now that MySQL is running, you can also start up the freezing-web container to actually have the website running locally.

(For local development, you don't need to bother with running nginx, letsencrypt, etc, as those expect real domain names and actual account credentials.)

The website expects some minimum configuration to be specified, so you may need to check your `.env` file:
```shell
# Set this to something random. For example, generate a UUID and paste it in (without any quotes)
# python -c 'import uuid; print(uuid.uuid4())'
SECRET_KEY=deadbeef

# For the SA URL, you need to use the user & password you configured for your app db above.
# The host should be 'mysql.container' which will be resolved by docker to the MySQL container's IP address
SQLALCHEMY_URL=mysql+pymysql://freezing:please-change-me-as-this-is-a-default@mysql.container/freezing?charset=utf8mb4&binary_prefix=true

# Some of the website reports expect the start date and end date and teams to be configured.

```

Now you can start up the `freezing-web` container!

These commands will start it, wait 20 seconds for it to boot, and then tail the logs of the container:

```shell
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d freezing-web
sleep 20
docker logs -t freezing-web
```
If this starts correctly, it will look like:

```
[2019-12-01 18:56:09 +0000] [6] [INFO] Starting gunicorn 19.7.1
[2019-12-01 18:56:09 +0000] [6] [INFO] Listening at: http://0.0.0.0:8000 (6)
[2019-12-01 18:56:09 +0000] [6] [INFO] Using worker: sync
[2019-12-01 18:56:09 +0000] [9] [INFO] Booting worker with pid: 9
[2019-12-01 18:56:59 +0000] [6] [CRITICAL] WORKER TIMEOUT (pid:9)
[2019-12-01 18:56:59 +0000] [9] [INFO] Worker exiting (pid: 9)
[2019-12-01 18:57:00 +0000] [11] [INFO] Booting worker with pid: 11
```
If it works, you can visit the local development web site at: http://127.0.0.1:8000/

If it fails, it will have a stack trace that complains about the problem. The first thing to check is the `SQLALCHEMY_URL`, as it tries to connect to the database early in the boot process.

*Note*: if you just want to do website development, it is probably easier to just set up a Python 3 virtual environment instead.

See the README for [freezing-web](https://github.com/freezingsaddles/freezing-web) for those instructions.  

## 2. Deploy to Production

This repository can be used to deploy the Freezing Saddles application for production.  Before you get started, we assume you have already installed [Docker](http://docker.com) and [Docker Compose](https://docs.docker.com/compose/).

The current production setup assumes that you will use an external MySQL server, but [future work is contemplated to support running MySQL as a Docker container in production](https://github.com/freezingsaddles/freezing-compose/issues/9).

### 2.1 Clone Repository

Clone the repository this repository onto a server that runs Docker and `docker-compose`. [freezingsaddles.org](https://freezingsaddles.org/) has run on CoreOS since 2018 but works but any modern operating system distribution that has Docker support will probably work. That includes CentOS 7 and 8, Ubuntu 16.04 and 18.04, and many others.

For example:

```shell
sudo git clone https://github.com/freezingsaddles/freezing-compose /opt/compose
# Change ownership back to your regular user so you can update it
sudo chown -R $(id -u):$(id -g) /opt/compose
```

### 2.2 Create Persistent Docker Volumes

Create the persistent volume for beanstalkd-data:
```shell
docker volume create --name=freezing-data
```

### 2.3 Configure Environment
```shell
# Create and edit the .env file, filling it in completely with real values
cd /opt/compose
cp example.env .env
vi .env

# Verify Docker compose is working
docker-compose ps
```

*Note:* The production configuration assumes you will run a MySQL server outside of the environment managed by `docker-compose`. Please configure an external MySQL server, for example an AWS RDS MySQL server, in the `.env` file for production use.

### 2.3 Run Containers
```shell
cd /opt/compose
docker-compose up -d
# wait a minute, then verify that the containers are working
sleep 60
docker-compose ps
```

If any containers are not started, troubleshoot with `docker ps` and `docker logs container-name`. You might need to tweak the configuration multiple times before all containers come up cleanly. Restart the containers after tweaking the `.env` file each time with `docker-compose up -d` until things work.


