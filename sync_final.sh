#!/bin/bash

# Setează directoarele
LOCAL_DIR="/home/darianam/source"
REMOTE_DIR="/home/darianapopescu/destination"

# Monitorizare modificări fișiere
inotifywait -mr -e modify,create,delete "$LOCAL_DIR" |
while read path action file; do
    echo "Modificare detectată: $file ($action)"

    # Dacă fișierul a fost șters, îl ștergem și din remote
    if [ "$action" == "DELETE" ]; then
        echo "Fișier șters: $file"
        ssh darianapopescu@localhost "rm -f \"$REMOTE_DIR/$file\""
        continue
    fi

    # Verificare hash fișier local
    local_hash=$(sha256sum "$LOCAL_DIR/$file" | awk '{print $1}')

    # Verificare hash fișier remote (dacă există)
    remote_hash=$(ssh darianapopescu@localhost "sha256sum $REMOTE_DIR/$file 2>/dev/null || echo MISSING")

    # Dacă fișierul nu există pe remote, copiază-l direct
    remote_file_exists=$(ssh darianapopescu@localhost "test -e $REMOTE_DIR/$file && echo 'exists' || echo 'missing'")
    if [ "$remote_file_exists" == "missing" ]; then
        echo "Fișierul nu există pe remote, sincronizare..."
        scp "$LOCAL_DIR/$file" darianapopescu@localhost:"$REMOTE_DIR/.temp_file"
        ssh darianapopescu@localhost "
            if ! lsof $REMOTE_DIR/$file &>/dev/null; then
                mv $REMOTE_DIR/.temp_file $REMOTE_DIR/$file
            else
                echo 'Fișierul $file este folosit. Nu a fost înlocuit.'
            fi"
        continue
    fi

    # Dacă s-a modificat, copiază fișierul pe remote (folosind temporar)
    if [ "$local_hash" != "$remote_hash" ]; then
        echo "Sincronizare fișier: $file"
        scp "$LOCAL_DIR/$file" darianapopescu@localhost:"$REMOTE_DIR/.temp_file"
        ssh darianapopescu@localhost "
            if ! lsof $REMOTE_DIR/$file &>/dev/null; then
                mv $REMOTE_DIR/.temp_file $REMOTE_DIR/$file
            else
                echo 'Fișierul $file este folosit. Nu a fost înlocuit.'
            fi"
    fi
done

