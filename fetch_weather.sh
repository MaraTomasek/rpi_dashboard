#! /bin/bash

# Called as a cronjob - see 'crontab -e'


# --- Fetching --- #

# Fetch todays weather
curl de.wttr.in/Tuebingen?0Q \
    | cut -c 3- \
    > /home/smb/rpi_dashboard/fetched_weather_today;

# Fetch tomorrows weather and remove trailing spaces (in order to prevent line wrapping on the display)
curl de.wttr.in/Tuebingen@$(date --date='tomorrow' +%F)?0Q \
    | cut -c 3- \
    | sed -e 's/[[:space:]]*$//' \
    > /home/smb/rpi_dashboard/fetched_weather_tomorrow;


# --- Processing --- #

# Padding function -- https://stackoverflow.com/a/72068155
# $1: string to pad
# $2: integer padding-length, positive for left-padding, negative for right-padding
pad () {
    [ "$#" -gt 1 ] && [ -n "$2" ] && printf "%$2.${2#-}s" "$1" && printf "\n";
}

# Get and set width of the first line of todays weather text
WEATHER_TEXT=$(pad "$(cat /home/smb/rpi_dashboard/fetched_weather_today | sed 's/^[^A-Z]*\([A-Z][a-zA-Z \,]\+\)/\1/g; 1 q')" -15)

# Trim and pad the first line of todays weather text in place
sed -i "s/\([^A-Z]*\)\([A-Z][a-zA-Z, ]*$\)/\1$WEATHER_TEXT/g;" /home/smb/rpi_dashboard/fetched_weather_today


# --- Safety Buffer --- #

# Only overwrite stored weather if curl requests succeeded
if [ -s /home/smb/rpi_dashboard/fetched_weather_today ]; then
    cp /home/smb/rpi_dashboard/fetched_weather_today /home/smb/rpi_dashboard/display_weather_today
fi

if [ -s /home/smb/rpi_dashboard/fetched_weather_tomorrow ]; then
    cp /home/smb/rpi_dashboard/fetched_weather_tomorrow /home/smb/rpi_dashboard/display_weather_tomorrow
fi
