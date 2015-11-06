#!/bin/bash

if [ -f "scripts/""$1""."* ]; then

	scriptname=`echo scripts/$1.*`
	extension="${scriptname#*.}"

	if [ $extension = "py" ]; then
		python $scriptname "${@: -1}"
	elif [ $extension = "sh" ]; then
		./$scriptname "${@: -1}"
	elif [ $extension = "R" ]; then
		Rscript $scriptname "${@: -1}"
	else
		echo "[pipe finder]: Unknown script type: $1"
	fi

else
	echo "[pipe finder]: Missing segment: $1"
fi
