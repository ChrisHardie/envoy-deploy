#!/bin/bash

version=`php artisan --version`

if [[ ${version} != *"Laravel Framework"* ]]; then
				echo "Not a Laravel app, exiting."
				exit;
fi

path=$(pwd)
basedir=$(dirname "$path")
date=$(date '+%Y%m%d%H%M%s')
release=$path/releases/$date

if [ ! -d $path/storage ]; then
				echo "No storage directory, something's wrong, exiting."
				exit;
fi

if [ -d $path/releases ]; then
				echo "Releases directory already exists, exiting."
				exit;
fi

# Turn on maintenance mode
php artisan down || true

cd $basedir
mv $path $path.temp
mkdir -p $path/releases
mv $path.temp $release
mv $release/storage $path/storage
mv $release/.env $path/.env
chown www-data:www-data $path
chmod g+w $path
chown -R deploy:deploy $path/releases
chown -R www-data:www-data $path/storage

if [ -d $release/database/snapshots ]; then
				mkdir $path/storage/app/laravel-db-snapshots
				mv $release/database/snapshots/* $path/storage/app/laravel-db-snapshots/
				chmod g+w $path/storage/app/laravel-db-snapshots
fi

ln -s $path/storage $release/storage
ln -s $path/.env $release/.env
ln -nfs $release $path/current
chown -h deploy:deploy $path/current $release/storage $release/.env
cd $path

echo "Done, but application is still down. Now:"
echo ""
echo "Update nginx with new root:"
echo "root $path/current/public;"
echo "service nginx configtest && service nginx reload"
echo ""
echo "Update cron job with new path:"
echo "crontab -e -u www-data"
echo "* * * * * php $path/current/artisan schedule:run >> /dev/null 2>&1"
echo ""
echo "Update supervisor cmd and logfile out paths:"
echo "command=php $path/current/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600"
echo "supervisorctl reread && supervisorctl reread && supervisorctl update"
echo ""
echo "As deploy user, run optimize:"
echo "php $path/current/artisan optimize"
echo ""
echo "Then, also as deploy user, bring the app back up:"
echo "$path/current/artisan up"
echo ""