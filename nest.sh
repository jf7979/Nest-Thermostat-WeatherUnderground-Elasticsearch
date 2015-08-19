#! /bin/bash
# 8/19/2015
# Script that pulls Nest Thermostat info from Nest API and prepares for import in to Elasticsearch using Logstash

# Set up variables used per script run time
timestamp=$(date -u +%FT%H:%M:%S)
pull_time=$(date +%s)
index_name=$(date +%F)
elasticsearch_ip=[ip address]
file_path="/home/files/"
wunder_api_key=[key]
state=[ST]
city=[City]

# Curl command that goes to Nest API for info
curl --silent -L -k 'https://developer-api.nest.com/devices.json?auth=c.[redacted token]' > $file_path$pull_time.nest


# Pull out data that wont be used and seperate fields per line
sed -i -e 's/{"thermostats":{"[nest_id]"://' -e 's/}}}//' -e 's/$/,/' -e 's/,/,\n/g' $file_path$pull_time.nest



# Convert true and false values to also included integers for graphing status
grep "true" $file_path$pull_time.nest |sed 's/\":true/_int\":1/' >> $file_path$pull_time.nest # Add's the "trues"
grep "false" $file_path$pull_time.nest |sed 's/\":false/_int\":0/' >> $file_path$pull_time.nest # Add's the "falses"


# Get hvac_state integers set and added
hvac_state=$(sed -n 's/.*hvac_state\":\"\(.*\)\".*/\1/p' $file_path$pull_time.nest)
if [[ $hvac_state == "cooling" ]]
then
echo '"hvac_cool":1,' >> $file_path$pull_time.nest
echo '"hvac_heat":0,' >> $file_path$pull_time.nest
elif [[ $hvac_state == "heating" ]]
then
echo '"hvac_cool":0,' >> $file_path$pull_time.nest
echo '"hvac_heat":1,' >> $file_path$pull_time.nest
else
echo '"hvac_cool":0,' >> $file_path$pull_time.nest
echo '"hvac_heat":0,' >> $file_path$pull_time.nest
fi

# Set has leaf integer
has_leaf=$(sed -n 's/.*has_leaf\":\([a-z]\+\).*/\1/p' $file_path$pull_time.nest)
if [[ $has_leaf == "true" ]]
then
echo '"has_leaf":1,' >> $file_path$pull_time.nest
else
echo '"has_leaf":0,' >> $file_path$pull_time.nest
fi

# And finally add the timestamp
echo '"@timestamp":"'$timestamp'"}' >> $file_path$pull_time.nest


# Post data directly to ElasticSearch
curl -XPOST "http://$elasticsearch_ip:9200/$index_name/Nest_Event/$pull_time" --data-binary @$file_path$pull_time.nest

# Remove raw JSON after upload
rm $file_path$pull_time.nest


################################################################################################################
# Pull weather data from weatherunderground and add it to ElasticSearch

# Remove the old file and download a new one
rm $file_pathweather.raw
curl -L --silent "http://api.wunderground.com/api/$wunder_api_key/conditions/q/$state/$city.json" > $file_pathweather.raw

# Since the old was removed, only proceed if a new one was downloaded.
if [[ -f $file_pathweather.raw ]]
then
# Start the json formatting
echo '{' > $file_pathweather.json
for data in weather temp_f relative_humidity wind_dir wind_mph wind_gust_mph pressure_mb dewpoint_f heat_index_f visibility_mi solarradiation precip_1hr_in precip_today_in
do
# Pull out the fields you want and format them nice for elasticsearch
grep "\"$data\"" $file_pathweather.raw|sed -e 's/\"NA\"/0/' -e 's/%//' -e 's/:\"\([0-9\.-]\+\)\"/:\1/' -e 's/ //g' >> $file_pathweather.json
done
# Complete json formatting with the timestamp
echo '"@timestamp":"'$timestamp'"}' >> $file_pathweather.json
# POST the data to the Elasticsearch cluster
curl -XPOST "http://$elasticsearch_ip:9200/$index_name/Weather_Event/$pull_time" --data-binary @$file_pathweather.json
fi







