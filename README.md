# dokku ldap

Ldap plugin for dokku based on
[dokku-mariadb](https://github.com/dokku/dokku-mariadb)/[commit
d203db3](https://github.com/dokku/dokku-mariadb/commit/d203bd3c0ee759c7b6e64bef26eee4555787da5f). Currently defaults to installing
[osixia/openldap 1.1.6](https://hub.docker.com/r/dinkel/openldap/).

## requirements (correct?)

- dokku 0.4.x+
- docker 1.8.x

## installation

```shell
# on 0.4.x+
sudo dokku plugin:install https://github.com/RoboMod/dokku-ldap.git ldap
```

## commands

```
ldap:clone <name> <new-name>        Create container <new-name> then copy directory from <name> into <new-name>
ldap:create <name>                  Create an ldap service with environment variables
ldap:destroy <name>                 Delete the service and stop its container if there are no links left
ldap:enter <name> [command]         Enter or run a command in a running ldap service container
ldap:export <name> > <file>         Export a dump of the ldap service directory
ldap:expose <name> [port]           Expose an ldap service on custom port if provided (random port otherwise)
ldap:import <name> < <file>         Import a dump into the ldap service directory
ldap:info <name>                    Print the connection information
ldap:link <name> <app>              Link the ldap service to the app
ldap:list                           List all ldap services
ldap:logs <name> [-t]               Print the most recent log(s) for this service
ldap:modify <name>                  Modify <name> via ldapmodify interactively
ldap:promote <name> <app>           Promote service <name> as LDAP_URL in <app>
ldap:restart <name>                 Graceful shutdown and restart of the ldap service container
ldap:search <name> [parameters]     Search in the $PLUGIN_SERVICE service directory
ldap:start <name>                   Start a previously stopped ldap service
ldap:stop <name>                    Stop a running ldap service
ldap:unexpose <name>                Unexpose a previously exposed ldap service
ldap:unlink <name> <app>            Unlink the ldap service from the app
```

## usage

```shell
# create a ldap service named lolipop
dokku ldap:create lolipop

# you can also specify the image and image
# version to use for the service
# it *must* be compatible with the
# used ldap image
export LDAP_IMAGE="<image name>"
export LDAP_IMAGE_VERSION="<version>"
dokku ldap:create lolipop

# you can also specify custom environment
# variables to start the ldap service
# in semi-colon separated forma
export LDAP_CUSTOM_ENV="USER=alpha;HOST=beta"
dokku ldap:create lolipop

# get connection information as follows
dokku ldap:info lolipop

# you can also retrieve a specific piece of service info via flags
dokku ldap:info lolipop --config-dir
dokku ldap:info lolipop --data-dir
dokku ldap:info lolipop --dsn
dokku ldap:info lolipop --exposed-ports
dokku ldap:info lolipop --id
dokku ldap:info lolipop --internal-ip
dokku ldap:info lolipop --links
dokku ldap:info lolipop --service-root
dokku ldap:info lolipop --status
dokku ldap:info lolipop --version

# a bash prompt can be opened against a running service
# filesystem changes will not be saved to disk
dokku ldap:enter lolipop

# you may also run a command directly against the service
# filesystem changes will not be saved to disk
dokku ldap:enter lolipop ls -lah /

# an ldap service can be linked to a
# container this will use native docker
# links via the docker-options plugin
# here we link it to our 'playground' app
# NOTE: this will restart your app
dokku ldap:link lolipop playground

## TODO: update following documentation
# the following environment variables will be set automatically by docker (not
# on the app itself, so they won’t be listed when calling dokku config)
#
#   DOKKU_MARIADB_LOLIPOP_NAME=/lolipop/DATABASE
#   DOKKU_MARIADB_LOLIPOP_PORT=tcp://172.17.0.1:3306
#   DOKKU_MARIADB_LOLIPOP_PORT_3306_TCP=tcp://172.17.0.1:3306
#   DOKKU_MARIADB_LOLIPOP_PORT_3306_TCP_PROTO=tcp
#   DOKKU_MARIADB_LOLIPOP_PORT_3306_TCP_PORT=3306
#   DOKKU_MARIADB_LOLIPOP_PORT_3306_TCP_ADDR=172.17.0.1
#
# and the following will be set on the linked application by default
#
#   DATABASE_URL=mysql://ldap:SOME_PASSWORD@dokku-mariadb-lolipop:3306/lolipop
#
# NOTE: the host exposed here only works internally in docker containers. If
# you want your container to be reachable from outside, you should use `expose`.

# another service can be linked to your app
dokku ldap:link other_service playground

# since DATABASE_URL is already in use, another environment variable will be
# generated automatically
#
#   DOKKU_MARIADB_BLUE_URL=mysql://ldap:ANOTHER_PASSWORD@dokku-mariadb-other-service:3306/other_service

# you can then promote the new service to be the primary one
# NOTE: this will restart your app
dokku ldap:promote other_service playground

# this will replace DATABASE_URL with the url from other_service and generate
# another environment variable to hold the previous value if necessary.
# you could end up with the following for example:
#
#   DATABASE_URL=mysql://ldap:ANOTHER_PASSWORD@dokku-mariadb-other_service:3306/other_service
#   DOKKU_MARIADB_BLUE_URL=mysql://ldap:ANOTHER_PASSWORD@dokku-mariadb-other-service:3306/other_service
#   DOKKU_MARIADB_SILVER_URL=mysql://ldap:SOME_PASSWORD@dokku-mariadb-lolipop:3306/lolipop

# you can also unlink a mariadb service
# NOTE: this will restart your app and unset related environment variables

# you can tail logs for a particular service
dokku ldap:logs lolipop
dokku ldap:logs lolipop -t # to tail

# you can dump the database
dokku ldap:export lolipop > lolipop.sql

# you can import a dump
dokku ldap:import lolipop < database.sql

# you can clone an existing database to a new one
dokku ldap:clone lolipop new_database

# finally, you can destroy the container
dokku ldap:destroy lolipop
```

## Changing database adapter

It's possible to change the protocol for DATABASE_URL by setting
the environment variable MARIADB_DATABASE_SCHEME on the app:

```
dokku config:set playground MARIADB_DATABASE_SCHEME=mariadb2
dokku ldap:link lolipop playground
```

Will cause DATABASE_URL to be set as
mariadb2://ldap:SOME_PASSWORD@dokku-mariadb-lolipop:3306/lolipop

CAUTION: Changing MARIADB_DATABASE_SCHEME after linking will cause dokku to
believe the mariadb is not linked when attempting to use `dokku ldap:unlink`
or `dokku ldap:promote`.
You should be able to fix this by

- Changing MARIADB_URL manually to the new value.

OR

- Set MARIADB_DATABASE_SCHEME back to its original setting
- Unlink the service
- Change MARIADB_DATABASE_SCHEME to the desired setting
- Relink the service
