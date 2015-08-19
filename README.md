# Tempastic
Setup that uses the Nest Thermostats REST API to import data in to Elasticsearch.

#### A few things first
1. You need to be a registered Nest Developer. Register Here: https://developer.nest.com/ 

2. You need to be a registered developer at weatherunderground.com for an API Key. The free 500 requests per day should work if you keep the polling to once every 3 minutes. Register Here: http://www.wunderground.com/weather/api

2. You need a working ElasticSearch (and Kibana if you want to see it) cluster. The script will create one new Index per day. 

3. You need to sort of know what you're doing in general. 

#### Steps

1. Copy the script somehwere.

2. Change options in the script to work for you (paths, ip, keys, etc)
    
3. Set up a cron job to run every couple of minutes ( I do 3 minutes)

4. Set up your Kibana graphs how you want if you're in to that


