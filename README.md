# Freezing Saddles Docker Compose Files

This project is for deploying the Freezing Saddles application, using [Docker Compose](https://docs.docker.com/compose/).

## Deploy

This repository can be used to deploy the Freezing Saddles application for production.  Before you get started, we assume you
have already installed [Docker](http://docker.com) and [Docker Compose](https://docs.docker.com/compose/).

### Clone Repo

Start by cloning this repository on your production server.  For simplicity, we are going to assume you are performing these tasks
as root -- or a user that is part of `docker` group and can write to these direcotries, etc.

For example:

```
sudo git clone https://github.com/freezingsaddles/freezing-compose /opt/compose
```

Now you can confirm that docker-compose is working correctly by changing to that directory and executing `docker-compose` commands.

```
cd /opt/Compose
docker-compose ps
```

You should see lots of warnings about undefined configuration variables.  This meanGood! -- We'll get to that next.

### Configure

Copy the `example.env` file to a file named `.env`.  This is where `docker-compose` will look for environment variables.

Here is an annotated example of production configuration:

```shell
# FQDNs and SSL
# -------------
#
# These domain names are used for letsencrypt and nginx reverse proxies.  You need to actually
# own these domains and have them setup to point to your server public IP address.

# The FREEZING_NQ_FQDN is the domain name that we configure with Strava to act as a webhook for the application.
# See https://developers.strava.com/docs/webhooks/ for guide on configuring webhooks.
FREEZING_NQ_FQDN=hook.freezingsaddles.org

# This is the main URL for the website. You likely want to include www. prefix here.
FREEZING_WEB_FQDN=freezingsaddles.org,www.freezingsaddles.org

# You will also need to set an email address to use for the letsencrypt (SSL cert) email.
LETSENCRYPT_EMAIL=admin@example.com

# Logging Settings
# ----------------

# If you have a datadog account, put the API and APP keys here.
DATADOG_API_KEY=deadbeef
DATADOG_APP_KEY=deadbeef

# Set the endpoint to use for syslog.  This examples shows using papertrail:
SYSLOG_ENDPOINT=syslog://logs6.papertrailapp.com:<MY_PORT_NUM>

# App Settings
# ------------

# Display stack traces, etc.
DEBUG=true

# This is used for Flask session keying.  Set it to something unique, for example:
#  python -c 'import uuid; print(uuid.uuid4())'
SECRET_KEY=deadbeef

# The URL to the database.
# (Currently this is MySQL still)
SQLALCHEMY_URL=mysql+pymysql://freezing:<password>@dbhostname/freezing?charset=utf8mb4&binary_prefix=true

# The ID/Key for the Strava app.
STRAVA_CLIENT_ID=12345
STRAVA_CLIENT_SECRET=deadbeef

# The verify token is used for webhook registration
STRAVA_VERIFY_TOKEN=FREEZE

# And you need a key for getting the weather data too.
WUNDERGROUND_API_KEY=deadbeef

# A comma-separated list of Strava team IDs.
TEAMS=12345,54321,98765

# The start date for the competition.  For Freezing Saddles this is traditionally midnight Jan 1.
# Important: include the time zone offset here for where the competition is based, or it'll assume GMT.
START_DATE=2018-01-01T00:00:00-05:00

# When does the competition end?  (This can be an exact time; API will stop fetching after this time.)
# Again, include the time zone here or it'll assume GMT.
END_DATE=2018-03-20T00:01:00-04:00
```

These environment variables will be passed in to the various services that need them (look through them
  `docker-compose.yml` file to see how that works).

## Develop

You can also use the `docker-compose.dev.yml` file, in conjunction with the main `docker-compose.yml` file,
to spin up services that might be needed during development, but not production.

For example, the `docker-compose.yml` file does not define a service for the database, but the `docker-compose.dev.yml` file does.

### Common Steps

To begin, you'll need to clone the repo, just as we did for production install.

Also, you'll want to create a `.env` file, as above.  You won't need all the values, so don't worry about needing to set up
a Strava app or Datadog account, etc.

### Part 1: Starting Just MySQL

Here is an example of starting up MySQL using docker-compose and then importing a snapshot of the production data.

First, edit your `.env` to specify some MySQL parameters:

```shell
# The root password, unsurprisngly:
MYSQL_ROOT_PASSWORD=somepassword

# This is the database that will be created:
MYSQL_DATABASE=freezing
# This is the user/password with access to the app database:
MYSQL_USER=freezing
MYSQL_PASSWORD=anotherpassword
```

Then when you start up the container, those values will be used.

```shell
# If you have not already, you first need to create the named volumes
docker volume create --name=freezing-data
docker volume create --name=beanstalkd-data

# Then you can start MySQL container
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d mysql
```

Hint: if you ever want to blow away your MySQL db.  Just remove the container and volume and re "up" it:

```shell
docker-compose -f docker-compose.yml -f docker-compose.dev.yml stop mysql
docker-compose -f docker-compose.yml -f docker-compose.dev.yml rm mysql

docker volume rm freezing-data
docker volume create --name=freezing-data
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d mysql
```

#### Loading in Data

If you have a MySQL dump (e.g. of the production database), you can load it into a fresh database like this:
```shell
mysql -h 127.0.0.1 -u root -p freezing < freezing-snap.dump
Enter password: <type in the root password you configured above>
```

Note: it is important to specify the `127.0.0.1` host, since otherwise mysql assumes a server listening on local
unix socket.  MySQL in the container is only listening on TCP.

### Part 2: Running other Containers Too

Now that MySQL is running, you can also start up the freezing-web container to actually have the website running locally.

(I recommend not bothering with nginx, letsencrypt, etc. as those expect real domain names, etc.)

The website expects some minimum configuration to be specified, so you may need to check your `.env` file:
```shell
# Set this to something random. For example, generate a UUID and paste it in (without any quotes)
# python -c 'import uuid; print(uuid.uuid4())'
SECRET_KEY=deadbeef

# For the SA URL, you need to use the user & password you configured for your app db above.
# The host should be 'mysql.container' which will be resolved by docker to the myslq container's IP address
SQLALCHEMY_URL=mysql+pymysql://freezing:anotherpassword@mysql.container/freezing?charset=utf8mb4&binary_prefix=true

# Some of the website reports, etc. expects the start date and end date and teams to be configured.
```

Now you can start up the `freezing-web` container!

```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d freezing-web
```

Note that if you want to do website development, it's easier to just set up a python virtual environment instead.

See the README for [freezing-web](https://github.com/freezingsaddles/freezing-web) for those instructions.
