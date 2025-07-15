#!/bin/bash

# Setează directoarele
LOCAL_DIR="/home/darianam/source"
REMOTE_DIR="/media/sf_SO_project2025"

# Monitorizare modificări fișiere
inotifywait -mr -e modify,create,delete "$LOCAL_DIR" |
while read path action file; do
    echo "Modificare detectată: $file ($action)"

    # Dacă fișierul a fost șters, îl ștergem și din remote
    if [ "$action" == "DELETE" ]; then
        echo "Fișier șters: $file"
        rm -f "$REMOTE_DIR/$file"
        continue
    fi

    # Verificare hash fișier local
    local_hash=$(sha256sum "$LOCAL_DIR/$file" | awk '{print $1}')

    # Verificare hash fișier remote (dacă există)
    if [ -f "$REMOTE_DIR/$file" ]; then
        remote_hash=$(sha256sum "$REMOTE_DIR/$file" | awk '{print $1}')
    else
        remote_hash="MISSING"
    fi

    # Dacă fișierul nu există pe remote, copiază-l direct
    if [ "$remote_hash" == "MISSING" ]; then
        echo "Fișierul nu există pe remote, sincronizare..."
        cp "$LOCAL_DIR/$file" "$REMOTE_DIR/.temp_file"
        if ! lsof "$REMOTE_DIR/$file" &>/dev/null; then
            mv "$REMOTE_DIR/.temp_file" "$REMOTE_DIR/$file"
        else
            echo "Fișierul $file este folosit. Nu a fost înlocuit."
        fi
        continue
    fi

    # Dacă s-a modificat, copiază fișierul pe remote (folosind temporar)
    if [ "$local_hash" != "$remote_hash" ]; then
        echo "Sincronizare fișier: $file"
        cp "$LOCAL_DIR/$file" "$REMOTE_DIR/.temp_file"
        if ! lsof "$REMOTE_DIR/$file" &>/dev/null; then
            mv "$REMOTE_DIR/.temp_file" "$REMOTE_DIR/$file"
        else
            echo "Fișierul $file este folosit. Nu a fost înlocuit."
        fi
    fi
done

