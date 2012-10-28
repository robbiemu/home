#!/bin/bash

who=`roll=$RANDOM
let "roll %= 3"
case "$roll" in
	0) echo 1111 ;; #Lao Tzu
	1) echo 968  ;; #Buddha
	2) echo 271  ;; #Confucius
esac`

wget -q -O - www.toomanyquotes.com/quote_of_the_day/person/${who}.xml | xmllint --xpath //item/description - |sed 's/<[^>]*>/\n/g'|ruby -ne 'print unless ~/^$/'
