# Telenor Digital Swagger specs

This repo contains all Telenor Digital API endpoint swagger specs.

# Install
You need to have swagger-codegen installed. On osx: `brew install swagger-codegen`

# Create Clients from command line 
To create a client in a given lagnuage (eg. Ruby gem client) run the following

```
    cd path/to/root/of/td-swagger/
    swagger-codegen generate -i ./payment-api-swagger.yml -l ruby -o ./bin/client/telenor-digital-payment-ruby-client/ -c ./config-files/ruby-client-config.json
```

Now you should have your very own ruby client in you desired output folder (in this example `./bin/client/telenor-digital-payment-ruby-client/`).

Available languages can be found [Swagger-codegen github page](https://github.com/swagger-api/swagger-codegen/blob/master/README.md).

# Change to production mode in client

This one depends on the output client language you chose. They are all similar, but still different due to the language.

```
    #Boilerplate start:
    # Load the gem
    require 'telenor_digital_client_api'

    # Setup authorization
    TelenorDigitalClientApi.configure do |config|
    # Configure HTTP basic authorization: telenorDigitalBasicAuth
    config.username = 'YOUR USERNAME'
    config.password = 'YOUR PASSWORD'
    end

    api_instance = TelenorDigitalClientApi::DefaultApi.new
    #Boilerplate end.
    
    #Change to production mode:
    api_instance.host = "api.telenordigital.com"
```

The important part is to change the `host` property on the api_instance in the gives client language. This changes what server the client talks to. The default is the sandbox-server.
