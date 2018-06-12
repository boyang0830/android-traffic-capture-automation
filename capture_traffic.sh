#!/bin/bash
#this script takes in a directory containing a list of apks and
#installs, then runs the apps using monkey and saves all traffic to a 
#file corresponding to the package name of the app

#NOTE: apk filenames need to be "package.name.apk" if aapt is installed this restriction could be removed

#directory containing apks to run
appList=$1

for app in $appList/*/*.apk; do
    [ -e "$app" ] || continue
    
    adb install -r "$app"
    
    packageNameWithPath=${app%.apk}
    #catogory=$(cut -d'/' -f2 <<<"$packageNameWithPath")
    catogory=$(basename $(dirname $packageNameWithPath))
    mkdir "traffic_result/Lincoln_NE/$catogory"
    packageName=${packageNameWithPath##*/}

    dumpName="traffic_result/Lincoln_NE/$catogory/$packageName"".flow"

    #run proxy
    mitmdump -q -p 8080 -w $dumpName &

    #specify end time for this app, 600 seconds = 10 minutes
    #disable status bar and home bar
    
    adb shell monkey -p "$packageName" 1

    #adb shell settings put global policy_control immersive.full=*

    sleep 20s

    end=$((SECONDS+300))

    while [ $SECONDS -lt $end ]; do
        #run monkey for 1000 events
        adb shell monkey -p "$packageName" 1000
    done

    #stop proxy to dump the results
    pkill mitmdump

    #uninstall
    adb uninstall "$packageName"

    #sudo fuser -k 8080/tcp
done
