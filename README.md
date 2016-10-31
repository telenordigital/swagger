# Telenor Digital Swagger specs

This repository contains all Telenor Digital API endpoint swagger specs.

# Prerequisites
You need to have swagger-codegen installed for these scripts to work. 

## OSx
`brew install swagger-codegen`


# Create clients with bash script
There is an included `codegen.sh` which can be used to create clients as well as server-templates for the payment api. The clients and servers can be generated in a multitude of languages. Use `codegen.sh list` to see all available.

To create the default clients (java, ruby, and javascript) run:

```sh
    codegen.sh client
```

The generated clients will be put in the `bin` directory of this project, and put in further sub-folders `client` or `server`.  

You can also choose which language to output, for example `java`:

```sh
    codegen.sh client java
```

There exists two special parameters, the `all-clients` and `all-servers`, which will respectively create, as the name implies, all available clients or servers.

More information about the codegen can be found at the [Swagger-codegen github page](https://github.com/swagger-api/swagger-codegen/).

# Change to production mode in client

This one depends on the output client language you chose. They are all similar, but still different due to the language.

```ruby
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
