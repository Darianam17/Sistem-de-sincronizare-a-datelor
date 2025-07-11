#!/bin/bash

# Setează directoarele
LOCAL_DIR="/home/darianam/source"
REMOTE_DIR="/home/darianapopescu/destination"

# Monitorizare modificări fișiere
inotifywait -mr -e modify,create,delete "$LOCAL_DIR" |
while read path action file; do
    echo "Modificare detectată: $file ($action)"
    # Dacă fișierul a fost șters, nu încercăm să-l sincronizăm
    if [ "$action" == "DELETE" ]; then
        echo "Fișier șters: $file"
        continue
    fi
    
    # Verificare hash fișier local
    local_hash=$(sha256sum "$LOCAL_DIR/$file" | awk '{print $1}')
    
    # Verificare hash fișier remote (dacă există)
    remote_hash=$(ssh darianapopescu@localhost "sha256sum $REMOTE_DIR/$file 2>/dev/null || echo MISSING")
    
    # Dacă s-a modificat, copiază fișierul pe remote
    if [ "$local_hash" != "$remote_hash" ]; then
        echo "Sincronizare fișier: $file"
        scp "$LOCAL_DIR/$file" darianapopescu@localhost:"$REMOTE_DIR/"
         # Verifică dacă fișierul nu este folosit pe remote
        ssh darianapopescu@localhost "
            if ! lsof /home/darianapopescu/destination/$file &>/dev/null; then
                # Dacă nu este folosit, înlocuiește fișierul original cu cel temporar
                mv /home/darianapopescu/destination/.temp_file /home/darianapopescu/destination/$file
            fi"



    fi
done

