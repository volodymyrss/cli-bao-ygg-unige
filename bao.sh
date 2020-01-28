#!/bin/bash


if [ "${1:-ssh}" ==  "mount" ];  then
    sshfs baobab2.unige.ch:/ bao -o ssh_command='sshpass -f '<(keyring get unige savchenk)' ssh';
else
    sshpass -f <(keyring get unige savchenk) ssh -Y baobab2.unige.ch $@;
fi
