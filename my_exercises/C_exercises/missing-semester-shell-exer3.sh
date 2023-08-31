#!/bin/zsh

count=0

echo > stdout.txt 2> stderr.txt
./script-to-be-executed.sh

while [[ "$?" -eq 0 ]]
do
	count=$((count+1))
	./script-to-be-executed.sh
done

echo "./script-to-be-executed.sh failed after $count times success"

