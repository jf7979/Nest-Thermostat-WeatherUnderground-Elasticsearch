#! /bin/bash
# 8/19/2015
# Script that pulls Nest Thermostat info from Nest API and prepares for import in to Elasticsearch using Logstash

### To Get a Token ###
# Step 1
#curl -k --data 'code=[authorization pin]&client_id=[client id]&client_secret=[client secret]&grant_type=authorization_code' https://api.home.nest.com/oauth2/access_token
# Response
#{"access_token":"c.[token]","expires_in":315360000}



# Name full json file based on epoch time
pull_time=$(date +%s)
# Curl command that goes to Nest API for info
curl --silent -L -k 'https://developer-api.nest.com/devices.json?auth=c.[token]' > $pull_time.nest

# Process the saved file and create variables to store for what is needed. Some converted to Integers for graphing
humidity=$(sed 's/.*humidity\":\([0-9\.]\+\),\".*/\1/' $pull_time.nest)
emergency_heat=$(sed 's/.*emergency_heat\":\([truefals]\+\),\".*/\1/' $pull_time.nest|sed -e 's/true/1/' -e 's/false/0/')
ambient_temp=$(sed 's/.*ambient_temperature_f\":\([0-9\.]\+\),\".*/\1/' $pull_time.nest)
target_temp=$(sed 's/.*target_temperature_f\":\([0-9\.]\+\),\".*/\1/' $pull_time.nest)
away_temp_high=$(sed 's/.*away_temperature_high_f\":\([0-9\.]\+\),\".*/\1/' $pull_time.nest)
away_temp_low=$(sed 's/.*away_temperature_low_f\":\([0-9\.]\+\),\".*/\1/' $pull_time.nest)
software=$(sed 's/.*software_version\":\"\([0-9\.]\+\)\",\".*/\1/' $pull_time.nest)
leaf=$(sed 's/.*has_leaf\":\([truefals]\+\),\".*/\1/' $pull_time.nest|sed -e 's/true/1/' -e 's/false/0/')
hvac_mode=$(sed 's/.*hvac_mode\":\"\([a-z]\+\)\",\".*/\1/' $pull_time.nest)
hvac_state=$(sed 's/.*hvac_state\":\"\([a-z]\+\)\".*/\1/' $pull_time.nest|sed -e 's/off/0/' -e 's/cooling/1/' -e 's/heating/2/')
is_online=$(sed 's/.*is_online\":\([truefals]\+\),\".*/\1/' $pull_time.nest|sed -e 's/true/1/' -e 's/false/0/')
last_connection=$(sed 's/.*last_connection\":\"\([0-9TZ:\.-]\+\)\",\".*/\1/' $pull_time.nest)

# Echo out results to a file for logstash to import
#       1(time)      2            3               4            5              6             7          8(str)    9    10(str)      11       12         13(str)
echo "$pull_time $humidity $emergency_heat $ambient_temp $target_temp $away_temp_high $away_temp_low $software $leaf $hvac_mode $hvac_state $is_online $last_connection" >> import.nest
# Grok pattern: (?<time>[A-Za-z0-9\._:-]+) %{NUMBER:humidity:float} %{NUMBER:emergency_heat:float} %{NUMBER:ambient_temp:float} %{NUMBER:target_temp:float} %{NUMBER:away_temp_high:float} %{NUMBER:away_temp_low:float} (?<software>[0-9\.]+) %{NUMBER:leaf:float} (?<hvac_mode>[a-z]+) (?<hvac_state>[0-3]) %{NUMBER:is_online:float} (?<last_connection>[0-9TZ:\.-]+)





