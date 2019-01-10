# Description
 This document describe process for backing up Drone.

# Precondition
  Able to log in(ssh) drone-server.

# Workflow
1. Get GS_PROJECT_ID GS_CLIENT_EMAIL GS_PRIVATE_KEY GS_PRIVATE_KEY_ID corresponding value via access https://gitlab.eng.vmware.com/core-build/vic-internal/blob/master/drone-0.8/secrets_vic-product.sh(need access permissions)
2. Install using tools via below cmdlines:(python version requested 2.7.x)
```
   $> wget https://bootstrap.pypa.io/get-pip.py
   $> python ./get-pip.py
   $> pip install --upgrade gsutil
   $> apt-get update
   $> apt-get install sqlite3
```
3. back up db, assuming db is /var/lib/drone/drone.sqlite, execute below backup cmdline:(xxx.sqlite is backup file name, e.g: drone_db_backup.sqlite.)
```  
   $> sqlite3 /var/lib/drone/drone.sqlite ".backup 'xxx.sqlite'"
```
4. Unpack backup file as .zip format via below cmd:
```
   $> zip -9 -j xxx.zip drone_db_backup.sqlite
```
5. Configure google cloud credentials via below cmdlines:
```
   $> cat > $HOME/drone-db-backup.json <<EOF
      {
      "type": "service_account",
      "project_id": "$GS_PROJECT_ID",
      "private_key_id": "$GS_PRIVATE_KEY_ID",
      "private_key": "$GS_PRIVATE_KEY",
      "client_email": "$GS_CLIENT_EMAIL",
      "client_id": "$GS_PROJECT_ID",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://accounts.google.com/o/oauth2/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": ""
     }
      EOF
   $> chmod 400 $HOME/drone-db-backup.json
   $> cat > $HOME/.boto <<EOF
     [Credentials]
     gs_service_key_file = $HOME/drone-db-backup.json
     gs_service_client_id = $GS_CLIENT_EMAIL
     [GSUtil]
     content_language = en
     default_project_id = $GS_PROJECT_ID
     EOF
```
6. Upload zip file to google storage via below cmds:
```
   $> gsutil cp xxx.zip gs://drone-db-backup
   $> gsutil -D version -l
```
   Upload full path: https://console.cloud.google.com/storage/browser/drone-db-backup?project=$GS_PROJECT_ID, open url check whether the upload was successful. 
     
