# Long-term retention for secure MySQL backups

This Docker image will backup your MySQL/MariaDB, and Postgres databases following the Grandfather-Father-Son (GFS) retention scheme.

## Features

* GFS backups retention scheme
* AES256 encryption/decryption
* Single or multiple databases backups
* Grouped or individual archives
* Parallelized compression

## GFS retention scheme

This means that you'll always have:

* A backup for every day of the last week (6)
* A backup for every week of the last month (4)
* A backup for every month of the last year (12)
* A backup for every previous year (unlimited)

For a 100MB backup, it will cost you around 2GB for the current year + 100MB for each previous year.

In SuperSafe mode, you'll have:

* A backup for every day of the last month (28~31)
* A backup for every week of the last year (48)
* A backup for every previous year (unlimited)

For a 100MB backup, backups will cost you around 8GB for the current year + 100MB for each previous year.

Backups are run by default every day at 00:00 UTC.

## Usage

```bash
docker run -d \
    --network mysql \
    -e DATABASE_USER=root \
    -e DATABASE_PASSWORD=password \
    -e CHOWN_FILES='1000:1000' \
    -e MAX_CPU=4 \
    -v /path/to/backups:/backup \
    ishtiyaq/secure-database-backups:1
```

## Variables

All variables can be appended with `_FILE` in case you want to populate them from secrets.

As an example, you can use: `MYSQL_PASSWORD_FILE=/run/secret/mysql-root-password`

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `SUPERSAFE_MODE` | Run backups in SuperSafe mode. This means many more backups ([see details](#gfs-retention-scheme)). | `false` |
| `DATABASE` | The type of your database (mysql, postgres). | `mysql` |
| `DATABASE_HOST` | The host of your MySQL/MariaDB database. | `mysql` |
| `DATABASE_PORT` | The port number of your MySQL/MariaDB database. | `3306` |
| `DATABASE_USER` | The username of your MySQL/MariaDB database. | `root` |
| `DATABASE_PASSWORD` | The username of your MySQL/MariaDB database. | empty |
| `DATABASE_DBNAME` | The database name to dump, or a space separated list of databases to dump. | all user databases |
| `CRON_MINUTE` | The minute interval of cron job to dump database. Don't use `CRON_TIME` if you use this. | `0` |
| `CRON_HOUR` | The hour interval of cron job to dump database. Don't use `CRON_TIME` if you use this. | `0` |
| `CRON_TIME` | The interval of cron job to dump database. Use it to override the cron job. Warning: overriding this variable my lead to inconsistent GFS backups. | `0 0 * * *` |
| `BACKUP_NAME` | The name of the backup. It will produce files like `main-backup.day1-Monday.tgz` | `main-backup` |
| `INDIVIDUAL_BACKUPS` | Set to true if you want to create one archive per database, instead of a global archive for all databases. It will produce files like `main-backup.my_db.day1-Monday.tgz`| `false` |
| `MAX_CPU` | Maximum CPU count to use while compressing the archive. | all CPUs |
| `CHOWN_FILES` | Set permissions to the created archives and files within them. | `root:root` |
| `AES_PASSPHRASE` | If set, all archives will be encrypted with AES-256-CBC algorithm. | empty |

## Manually run a backup

If you want to bypass the cron and run a manual backup, run this command:

```bash
docker run --rm \
    --network mysql \
    -e DATABASE_USER=root \
    -e DATABASE_PASSWORD=password \
    -e CHOWN_FILES='1000:1000' \
    -e MAX_CPU=4 \
    -v /path/to/backups:/backup \
    ishtiyaq/secure-database-backups:latest \
    backup
```

This will create a new file named `main-backup.day3-Wednesday.tgz` which you can untar normally.

## Decrypting encrypted backup

Currently there's not yet an automatic backup restoration command.

In the meantime, use this script to decrypt an archive:

```bash
docker run --rm \
    -e AES_PASSPHRASE=my_passphrase \
    -e CHOWN_FILES='1000:1000' \
    -v /path/to/backups:/backup \
    ishtiyaq/secure-database-backups:latest \
    decrypt main-backup.day3-Wednesday.tgz.aes
```

This will create a new file named `main-backup.day3-Wednesday.tgz` which you can untar normally.

## Usage with Docker Compose

```yaml
version: '3.8'

services:
    database:
        image: mysql:8
        restart: 'no'
        environment:
            - MYSQL_DATABASE=my_db
            - MYSQL_ROOT_PASSWORD=root

    backup:
        image: ishtiyaq/secure-database-backups:latest
        restart: 'no'
        volumes:
            - ./backup:/backup
        environment:
            DATABASE: mysql # or postrges
            DATABASE_HOST: database
            DATABASE_USER: root
            DATABASE_PASSWORD: root
            CHOWN_FILES: '1000:1000'
            MAX_CPU: 4
            AES_PASSPHRASE: my_passphrase
```

Then you can run a manual backup like this:

```bash
docker-compose run --rm backup backup
```

Or decrypting an archive:

```bash
docker-compose run --rm backup decrypt main-backup.day3-Wednesday.tgz.aes
```

## Available tags

Use a numbered tag if you want to avoid BC breaks.

* `1.0.0`, `1.0`, `1`, `latest`

## Credits

This project is an extended version of the [secure-mysql-backups](https://github.com/williarin/secure-mysql-backups) project with Postgres database support. Thank you ❤️ [williarin](https://github.com/williarin) for this awesome code.

## Why I created this?

I wanted to take GFS backup for postgress as well and may be many more in near future.
