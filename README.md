# Tempastic
Setup that uses the Nest Thermostats REST API to import data in to Elasticsearch.

#### A few things first
1. You need to be a registered Nest Developer. Register here: https://developer.nest.com/ 

2. You need a working ElasticSearch/Kibana cluster and access to it. The script will create one new Index per day. 

3. You need to sort of know what you're doing in general. 

#### Steps

1. Copy the script somehwere.

2. Change options in the script to work for you:

    a. Directory structure
    
    b. Nest ID to be removed at the top of the JSON
    
    c. ElasticSearch IP
    
    d. Possibly Index name
    
3. Set up a cron job to run every couple of minutes

4. Set up your Kibana graphs how you want 


