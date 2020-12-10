#!/bin/sh

# Setup/variables:

# Each snapshot name must be unique, timestamp is a good choice.
# You can also use Solaris date, but I don't know the correct syntax.
snapshot_string=DO_NOT_DELETE_remote_replication_
timestamp=$(/bin/date '+%Y%m%d%H%M%S')
root_source_pool=rpool
root_destination_pool=rpool_backup
root_new_snap="$root_source_pool"@"$snapshot_string""$timestamp"
boot_source_pool=bpool
boot_destination_pool=bpool_backup
boot_new_snap="$boot_source_pool"@"$snapshot_string""$timestamp"

# Initial send:
if [ "$1" = "full" ]; then
	echo "Full snap $timestamp";
	/usr/sbin/zfs snapshot -r "$root_new_snap"
	/usr/sbin/zfs snapshot -r "$boot_new_snap"
 	/usr/sbin/zfs send -R "$root_new_snap" > /media/backup/$root_destination_pool
	/usr/sbin/zfs send -R "$boot_new_snap" > /media/backup/$boot_destination_pool
else
 	echo "Incremental $timestamp";
	root_destination_pool="$root_destination_pool"_"$timestamp"
	boot_destination_pool="$boot_destination_pool"_"$timestamp"

# Get old snapshot name.
	root_old_snap=$(/usr/sbin/zfs list -H -o name -t snapshot -r "$root_source_pool" | grep "$root_source_pool"@"$snapshot_string" | tail --lines=1)
# # Create new recursive snapshot of the whole pool.
	/usr/sbin/zfs snapshot -r "$root_new_snap"
# # Incremental replication via SSH.
	/usr/sbin/zfs send -R -I "$root_old_snap" "$root_new_snap" > /media/backup/$root_destination_pool

	boot_old_snap=$(/usr/sbin/zfs list -H -o name -t snapshot -r "$boot_source_pool" | grep "$boot_source_pool"@"$snapshot_string" | tail --lines=1)
# # Create new recursive snapshot of the whole pool.
	/usr/sbin/zfs snapshot -r "$boot_new_snap"
# # Incremental replication via SSH.
	/usr/sbin/zfs send -R -I "$boot_old_snap" "$boot_new_snap" > /media/backup/$boot_destination_pool
# # Delete older snaps on the local source (grep -v inverts the selection)
delete_from=$(/usr/sbin/zfs list -H -o name -t snapshot -r "$root_source_pool" | grep "$snapshot_string" | grep -v "$timestamp")
for snap in $delete_from; do
    /usr/sbin/zfs destroy "$snap"
done
delete_from=$(/usr/sbin/zfs list -H -o name -t snapshot -r "$boot_source_pool" | grep "$snapshot_string" | grep -v "$timestamp")
for snap in $delete_from; do
    /usr/sbin/zfs destroy "$snap"
done
fi
