#!/bin/bash

set -e

cd "$(dirname "$0")"
mkdir -p backups

STAMP=$(date +%Y-%m-%d_%H-%M)
FILE="jenkins_backup_$STAMP.tar.gz"
KEEP=3

docker run --rm \
  -v "$(pwd)/jenkins_home":/data:ro \
  -v "$(pwd)/backups":/backup \
  debian:stable-slim \
  sh -c "tar czf /backup/$FILE \
           --exclude=./workspace --exclude=./caches \
           --exclude=./war --exclude=./logs \
           -C /data . \
         && chown $(id -u):$(id -g) /backup/$FILE"

ls -1t backups/jenkins_backup_*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm --

echo "$(date '+%F %T') Backup created: backups/$FILE ($(du -h backups/$FILE | cut -f1))"
