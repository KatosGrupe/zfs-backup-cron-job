!/bin/sh
NOW=$(date)
NOW=$(date --date="${NOW} -6 day" +%s)
echo $NOW
cd /media/backup
for i in $(ls); do
	if echo $i | grep "[rb]pool_backup_" ; then
		file_date=$(echo $i | sed -E "s/^[rb]pool_backup_([0-9]{8})[0-9]{6}/\1/")
		file_date=$(date -d $file_date +%s)
		if [ $NOW -ge $file_date ]; then
			echo "Removing: $i"
			rm $i
		fi
	fi
done
# ls | grep [rb]pool_backup_ | date -d "$(sed "s/^[rb]pool_backup_//")"

