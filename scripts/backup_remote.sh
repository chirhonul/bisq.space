#
# Archive data directories of the rocket.chat instance.
#
# This script runs remotely on the rocket.chat instance, and produces
# tarballs under /var/backups/rocket.chat. It should be placed on $PATH,
# by copying it remotely with a command like
# `scp backup_remote.sh s3:/usr/local/bin/`.
#
set -euo pipefail

[ $(id -u) -eq 0 ] || {
  echo "failing; this script needs superuser powers"
  exit 1
}

echo "Creating backup at $(date -I).."
cd /var/www/
mkdir -p rocket.chat
tar czfv rocket.chat.backup-$(date -I).tar.gz rocket.chat/
mv rocket.chat.backup-$(date -I).tar.gz /var/backups/rocket.chat/
