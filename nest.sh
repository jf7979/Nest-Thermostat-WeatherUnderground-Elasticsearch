#! /bin/bash
# 8/19/2015
# Script that pulls Nest Thermostat info from Nest API and prepares for import in to Elasticsearch using Logstash

# Set up variables used per script run time
timestamp=$(date -u +%FT%H:%M:%S)
pull_time=$(date +%s)
index_name=$(date +%F)


# Curl command that goes to Nest API for info
curl --silent -L -k 'https://developer-api.nest.com/devices.json?auth=c.[redacted token]' > /home/logstash/files/$pull_time.nest


# Pull out data that wont be used and seperate fields per line
sed -i -e 's/{"thermostats":{"[nest id]"://' -e 's/}}}//' -e 's/$/,/' -e 's/,/,\n/g' /home/logstash/files/$pull_time.nest



# Convert true and false values to also included integers for graphing status
grep "true" /home/logstash/files/$pull_time.nest |sed 's/\":true/_int\":1/' >> /home/logstash/files/$pull_time.nest # Add's the "trues"
grep "false" /home/logstash/files/$pull_time.nest |sed 's/\":false/_int\":0/' >> /home/logstash/files/$pull_time.nest # Add's the "falses"


# Get hvac_state integers set and added
hvac_state=$(sed -n 's/.*hvac_state\":\"\(.*\)\".*/\1/p' /home/logstash/files/$pull_time.nest)
if [[ $hvac_state == "cooling" ]]
then
	echo '"hvac_cool":1,' >> /home/logstash/files/$pull_time.nest
	echo '"hvac_heat":0,' >> /home/logstash/files/$pull_time.nest
elif [[ $hvac_state == "heating" ]]
then
	echo '"hvac_cool":0,' >> /home/logstash/files/$pull_time.nest
	echo '"hvac_heat":1,' >> /home/logstash/files/$pull_time.nest
else
	echo '"hvac_cool":0,' >> /home/logstash/files/$pull_time.nest
	echo '"hvac_heat":0,' >> /home/logstash/files/$pull_time.nest
fi

# Set has leaf integer
has_leaf=$(sed -n 's/.*has_leaf\":\([a-z]\+\).*/\1/p' /home/logstash/files/$pull_time.nest)
if [[ $has_leaf == "true" ]]
then
	echo '"has_leaf":1,' >> /home/logstash/files/$pull_time.nest
else
	echo '"has_leaf":0,' >> /home/logstash/files/$pull_time.nest
fi

# And finally add the timestamp
echo '"@timestamp":"'$timestamp'"}' >> /home/logstash/files/$pull_time.nest


# Post data directly to ElasticSearch
curl -XPOST "http://192.168.1.57:9200/$index_name/Nest_Event/$pull_time" --data-binary @/home/logstash/files/$pull_time.nest

# Remove raw JSON after upload
rm /home/logstash/files/$pull_time.nest





