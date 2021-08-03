
#!/bin/bash
#------------------------------------------------------------------------------
#  Copyright (c) 2021 Empirix Inc. All rights reserved.
#------------------------------------------------------------------------------
KEEP_RUNNING=0
if [ ! -z "$1" ] && [ "$1" -eq 1 ]; then
  KEEP_RUNNING=1
fi

copy_to_nfs()
{
  rm -rf /usr/share/mediation-apps/*
  directory=$(find /opt/mediation-apps/data -type d -name "*")
  for folder in $directory
  do
      if [[ $(find $folder -type d -name "* *") ]]; then
         continue
      else
         dir1=$(echo $folder | sed "s|/opt/mediation-apps/data|/usr/share/mediation-apps|g")
         mkdir -p ${dir1}
      fi
  done

  for dir in $directory
  do
     mapfile -t files < <(find $dir -type f)
     for f in "${files[@]}"; do
        path=$(echo $f | sed "s|/opt/mediation-apps/data/|/usr/share/mediation-apps/|g")
        cp -f "${f}" "${path}"
        if [ $? -ne 0 ]; then
           echo "Copy operation failed"
           exit 1
        fi
        file="file $f copied successfully"
        echo $( jq -n \
                  --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                  --arg fi "$file" \
                  '{timestamp: $ts, level: "INFO", component: "mediation-apps", message: $fi}' ) | jq '.'
   done
done

metadata_dir=$(find /opt/mediation-apps/metadata -type d -name "*")
for directory in $metadata_dir
do
    dir1=$(echo $directory | sed "s|/opt/mediation-apps/metadata|/usr/share/mediation-apps|g")
    mkdir -p ${dir1}
done

  for folder in $metadata_dir
  do
     mapfile -t files < <(find $folder -type f)
     for f in "${files[@]}"; do
         path=$(echo $f | sed "s|/opt/mediation-apps/metadata/|/usr/share/mediation-apps/|g")
         cp -f "${f}" "${path}"
         if [ $? -ne 0 ]; then
             echo "Copy operation failed"
             exit 1
         fi
         JSON_STRING=$( jq -n \
                  --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                  --arg file "$f" \
                  '{timestamp: $ts, level: "INFO", component: "mediation-apps", message: "file $file copied successfully"}' )
         echo $JSON_STRING | jq '.'
     done
  done
}
copy_to_nfs
echo "Mediation Apps data copied to shared NFS volume"

if [ $KEEP_RUNNING -eq 1 ]; then
    tail -f /dev/null
fi

exit 0
