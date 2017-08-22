# Set up Laravel after main deployment. Called from CodeDeploy's
# appspec.yml.

# Move the previously downloaded .env file to the right place.
mv /tmp/production.env /var/www/app/.env

# Run new migrations. While this is run on all instances, only the
# first execution will do anything. As long as we're using CodeDeploy's
# OneAtATime configuration we can't have a race condition.
sudo -Hu apache php /var/www/app/artisan migrate --force

# Run production optimizations.
sudo -Hu apache php /var/www/app/artisan config:cache
sudo -Hu apache php /var/www/app/artisan optimize
sudo -Hu apache php /var/www/app/artisan route:cache

# Reload apache to clear OPcache.
service httpd reload

touch /tmp/deployment-done
