#!/bin/bash
DATE=$(date +%Y-%m-%d)
LOG="/var/log/bee-cloud-sync.log"
echo "[$DATE $(date +%H:%M)] B2 vault sync starting..." >> $LOG
rclone sync /home/claude/vps/ b2:bee-backups/vault/ --log-file=$LOG --log-level ERROR --transfers=4
if [ "$(date +%d)" = "01" ]; then
  echo "[$DATE] Monthly: B2 → GDrive..." >> $LOG
  rclone sync b2:bee-backups/ gdrive:Bee-Backups/ --log-file=$LOG --log-level ERROR
fi
echo "[$DATE $(date +%H:%M)] Sync complete" >> $LOG
