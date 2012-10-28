#!/bin/bash

gh_name=robbiemu
gh_pswd=`nss-passwords github.com|awk '{print $6}'`

echo "\${font PizzaDude Bullets:size=14}2 \${font Droid Sans:size=8}User on github: \${alignr}$gh_name"

notifications=`curl -s -u $gh_name:$gh_pswd https://api.github.com/notifications|ruby -ne '$_.gsub! /[\[\]]/, ""; print unless ~/^\s$/'`
if [ -n "$notifications" ]; then
	echo -e "\${voffset 8}Notifications\n\${hr 1}\n$notifications"
else
	echo -e "\${voffset 8}\${font Droid Sans:italic:size=8}no notifications\$font"
	
	repos=`curl -s -u $gh_name:$gh_pswd https://api.github.com/users/$gh_name/repos|grep full_name|sed "s/.*$gh_name\///"|sed 's/[",]*$//g'`
	if [ -n "$repos" ]; then
		echo -e "\${voffset 8}Repos\n\${hr 1}\n$repos"
	fi
fi
