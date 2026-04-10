#!/bin/bash
# Daily cloud sync — runs at 04:00 on VPS
DATE=$(date +%Y-%m-%d)
LOG="/var/log/bee-cloud-sync.log"
RCLONE="/usr/bin/rclone"
CONF="/home/claude/.config/rclone/rclone.conf"

echo "[$DATE] Starting cloud sync..." >> $LOG

# Sync vault to B2
$RCLONE --config $CONF sync /home/claude/vps/ b2:bee-backups/vault/ --log-file=$LOG --log-level INFO

# Monthly: sync to Google Drive (on 1st of month)
if [ "$(date +%d)" = "01" ]; then
  $RCLONE --config $CONF sync b2:bee-backups/ gdrive:Bee-Backups/ --log-file=$LOG --log-level INFO
  echo "[$DATE] Monthly GDrive sync complete" >> $LOG
fi

echo "[$DATE] Cloud sync complete" >> $LOG
