#
# Create backups of config files and data for bisq.space.
#
# Run this script locally with `bash backup.sh`. It assumes
# the `~/.ssh/config` has an entry like `s3` for the server,
# and you have an SSH key loaded which grants access to the
# server.
#
set -euo pipefail

echo "Creating backups of configs and data.."
cd conf
echo "Copying remote configs locally.."
scp s3:/var/www/rocket.chat/docker-compose.yml .
scp s3:/etc/iptables.conf .
scp s3:/etc/nginx/sites-available/default nginx-sites-default
scp s3:/lib/systemd/system/docker.service .
scp s3:/lib/systemd/system/rocket-db.service .
scp s3:/lib/systemd/system/rocket-chat.service .
scp s3:/lib/systemd/system/rocket-hubot.service .
echo "Redacting ROCKETCHAT_PASSWORD in docker-compose.yml.."
sed -i 's/ROCKETCHAT_PASSWORD=[[:alnum:]]*/ROCKETCHAT_PASSWORD=<PASSWORD GOES HERE>/g' docker-compose.yml

echo "Creating backup on remote instance.."
ssh s3 sudo bash backup_remote.sh

echo "Syncing backups directory locally.."
rsync -vaz s3:/var/backups/rocket.chat /media/backups

echo "All done."
