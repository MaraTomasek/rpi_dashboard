#!/bin/bash

# Built for a Screen with $LINES=40 and $COLUMNS=60


# Artful header consisting of user and hostname
display_header() {
    figlet -w 60 -cf slant $USER'@'$HOSTNAME \
        | lolcat -f
}

display_date_today() {
    date +%F
}

display_date_tomorrow() {
    date --date='tomorrow' +%F
}

# Weather for today and tomorrow
# + Extra handling to disable line wrapping if tomorrows weather-text is too long
display_weather() {
    echo -e "\e[0;36m  Wetter heute, $(display_date_today)\t  Wetter morgen, $(display_date_tomorrow)\e[0m\n"
    printf '\033[?7l'
    paste /home/smb/rpi_dashboard/display_weather_today /home/smb/rpi_dashboard/display_weather_tomorrow
    printf '\033[?7h'
}

display_time() {
    figlet -w 60 -kcf big $(date +"%H:%M")
}

display_system_info_header() {
    printf "\e[0;36m                    Systeminformationen                    \e[0m\n"
}

display_cpu_and_memory_usage() {
    CPU_USAGE=$(iostat -c \
        | sed '4q;d' \
        | awk '{print 100.0-$6"%"}')

    # This bit is uncool and will change, I don't want to call neofetched every 60s
    MEMORY_USAGE=$(echo -e "$NEOFETCHED" \
        | grep Memory \
        | awk '{print int($2)"/"int($4)" MB"}')

    echo -e "\e[0;32mCPU Auslastung:\e[0m\t\t$CPU_USAGE\t\t$MEMORY_USAGE"
}

display_disk_space() {
    DISK_SPACE=$(df -h \
        | awk '$1 == "/dev/mmcblk0p2" {print $1"\t"int($4)" GB frei"}')

    DISK_SPEED=$(iostat -dk \
        | grep mmcblk0 \
        | awk '{print "(\033[32m↑"int($3),"\033[0m \033[34m↓"int($4)"\033[0m) kB/s"}')

    echo -e "\e[0;32mDisk:\e[0m $DISK_SPACE\t$DISK_SPEED"
}

display_network_statistics() {
    IP_ADDRESS=$(ip addr show wlan0 \
        | grep inet \
        | grep -v inet6 \
        | awk '{print $2}' \
        | cut -d/ -f1)

    # Only show ip-address if we've got one
    if [ -z $IP_ADDRESS ]; then
        echo -e "\e[0;32mNetwork:\e[0m wlan0 is \e[0;31mdown\e[0m"
    else
        echo -e "\e[0;32mNetwork:\e[0m wlan0 is \e[0;32mup\e[0m\t$IP_ADDRESS\t$NETWORK_SPEED"
    fi
}

display_uptime() {
    # Justified to the bottom right corner
    printf "%60s" "$(uptime -p)"
}

display_kehrwoche() {
    KEHRWOCHE=$(grep -w $(date +%-V) /home/smb/rpi_dashboard/2026_kehrwochen.txt | awk 'BEGIN { FS = "," } ; {print $2}')
    echo "$KEHRWOCHE"
}

display_trash_pickup(){
    TRASH=$(grep display_date_tomorrow /home/smb/rpi_dashboard/2026_trash_pickup_dates.txt | awk 'BEGIN { FS = "," } ; {print $2}')
    echo "$TRASH"
}

# Decoupled from display_network_statistics because it takes a second to calculate and i don't want the refresh to stutter on this line
calculate_network_speed() {
    NETWORK_SPEED=$(awk '{if(l1){print "(\033[32m↓"int(($2-l1)/1024),"\033[0m \033[34m↑"int(($10-l2)/1024)"\033[0m) kB/s"} else{l1=$2; l2=$10;}}' \
        <(grep wlan0 /proc/net/dev) \
        <(sleep 1; grep wlan0 /proc/net/dev))
}

line_break() {
    echo -e ''
}


clear

# Calculate the network speed once at the very start
calculate_network_speed

# Infinite loop to keep the dashboard running
while true; do
    NEOFETCHED=$(neofetch)

    # Display system metrics
    display_header
        line_break
        line_break
    display_weather
        line_break
    display_time
    display_kehrwoche
    display_trash_pickup
        line_break
        line_break
    display_system_info_header
        line_break
        line_break
    display_disk_space
        line_break
        line_break
    display_network_statistics
        line_break
        line_break
    display_uptime

    # Calculate the network speed after the display, so nothing stutters
    calculate_network_speed

    # Wait for a while before the next refresh
    sleep 60
    clear
done
