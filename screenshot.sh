#!/bin/bash

if [ $# = 0 ]; then
	echo "Help - Thanks for using <3"
	echo "screenshot.sh (windows | select | all) [path]"
	exit 0
fi

toClip=true
savePath=""
if [ $# = 2 ]; then
	if [ -d "$2" ]; then
		toClip=false
		savePath="$2"
	else
		echo "Path $2 does not exist"
		exit 1
	fi
fi
echo $toClip

if [ "$1" = "windows" ]; then
	# Getting all workspaces visible on all monitors
	workspaces=$(hyprctl monitors -j | jq -r 'map(.activeWorkspace.id) | join(",")')
	# Select all the Windows which are on visible workspaces on each monitor and get the position rectangle
	areas=$(hyprctl clients -j | jq -r ".. | select(.pid? and (.hidden|not) and (.workspace.id | IN($workspaces))) | \"\(.at[0]), \(.at[1]) \(.size[0])x\(.size[1])\"")

	# Select all existing monitors and transform their coordinates
	monitors=$(hyprctl monitors -j | jq -r 'map(
        { x:(.x/.scale), y:(.y/.scale), width:(.width/.scale), height:(.height/.scale), t:.transform})
        | map(
            (select(.t==0 or .t==2) | {x:.x, y:.y, width:.width, height:.height}),
            (select(.t==1 or .t==3) | {x:.x, y:.y, width:.height, height:.width})
            )
            | .[] | "\(.x), \(.y) \(.width)x\(.height)"')

	# Call slurp with both the monitors and areas of the windows
	selection=$(echo "$areas
    $monitors" | slurp)

	# Make the screenshot and save to
	if [ $toClip == true ]; then
		echo "Saving to Clipboard Windows"
		wayshot -s "$selection" --stdout | wl-copy
	else
		echo "Saving to $2 Windows"
		cd "$savePath" && wayshot -s "$selection"
	fi
	exit 0
fi

if [ "$1" = "select" ]; then
	if [ $toClip == true ]; then
		echo "Saving to Clipboard Selection"
		wayshot -s "$(slurp -d)" --stdout | wl-copy
	else
		echo "Saving to $2 Selection"
		cd "$savePath" && wayshot -s "$(slurp -d)"
	fi
	exit 0
fi

if [ "$1" = "all" ]; then
	if [ $toClip == true ]; then
		echo "Saving to Clipboard All"
		wayshot --stdout | wl-copy
	else
		echo "Saving to $2 All"
		cd "$savePath" && wayshot
	fi
	exit 0
fi

echo "I don't know how you got here but check the usage by executing without arguments"
exit 1
