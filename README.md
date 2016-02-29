# wsc-api-examples-ruby

#### Wowza Streaming Cloud™ API - Example Application for the Live Stream workflow written in Ruby

This API example application demonstrates the Live Stream workflow using the `/live_streams` endpoint of the Wowza Streaming Cloud™ API Version 1.

> The Wowza Streaming Cloud™ REST API version 1.0 is in a public preview release and isn't intended for use in production environments. All use of the Wowza Streaming Cloud™ REST API is subject to the Wowza Streaming Cloud™ Terms of Use.

If you just want to know how to use the Wowza Streaming Cloud™ API using the Ruby Net::HTTP library, [look at this section](#how_to_ruby_net_http).

## Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Run the application](#run)
- [How to use the example application](#how_to_use)
- [How to use the Wowza Streaming Cloud™ API working with the Ruby Net::HTTP library](#how_to_ruby_net_http)
- [References](#references)
- [Contact](#contact)
- [License](#license)

<a name="prerequisites"></a>
## Prerequisites

To install the example application make sure you have [Ruby](https://www.ruby-lang.org/en/documentation/installation/), [RubyGems](https://rubygems.org/) and [Bundler](http://bundler.io/) ready to use on your system!

<a name="installation"></a>
## Installation

##### 1. In the terminal, make sure you're in your application directory:

```bash
$ cd /wsc-api-example-ruby
```

##### 2. Run bundle install:

```bash
$ bundle install
```

You're done!!

<a name="configuration"></a>
## Configuration

To use the application you need a valid account on Wowza Streaming Cloud™ (https://cloud.wowza.com/) and access to the API.

> You don't have API access? To access the API, you must submit a request form at https://www.wowza.com/products/streaming-cloud/features/api-access-request. After you're accepted to the Wowza Streaming Cloud™ REST API public preview, your API key will be available on the page 'API Access' on https://cloud.wowza.com/.

#### Put the 'API Key' and the 'API Access Key' into the configuration file:

```yml
# config/keys.yml
api_key: "- PLEASE PLACE YOUR API KEY HERE -"
api_access_key: "- PLEASE PLACE YOUR API ACCESS KEY HERE -"
```

#### Change the hostname of the Wowza Streaming Cloud™ environment (optional)

You have two options. To use our Sandbox environment and be save, use this hostname:

```yml
# config/settings.yml
api_base_url: "https://api-sandbox.cloud.wowza.com"
...
```

> This is the default. If you don't change anything you will hit the our free of charge Sandbox service.

If you know what to and want to hit your live account, use this hostname - **NOT free of charge!**:

```yml
# config/settings.yml
api_base_url: "https://api.cloud.wowza.com"
...
```

#### Enable debug output (optional)

If you want to see header response data and response codes for each API call enable it in the settings:

```yml
# config/settings.yml
...
debug: true
```

This is disabled by default.

<a name="run"></a>
## Run the application

##### In the terminal, make sure you're in your application directory and execute the ruby file:

```bash
$ ./live_stream_api_example.rb
```

That's all.

<a name="how_to_use"></a>
## How to use the example application

After launching the application, you see the main menu with several action items. Just enter a number and hit enter and you will be guided through the application, it's easy.

*The screen after launching the application:*
```
"Main Menu"

1. Show the amount of Live Streams in your account
2. List all Live Streams of your account
3. Create a new Live Stream with pre-configured settings     => data/live_stream.json
4. Show the details of an existing Live Stream
5. Update a Live Stream with pre-configured settings         => data/live_stream_update.json
6. Start a Live Stream                                       => only for Live Streams with the state 'stopped'
7. Reset a Live Stream                                       => only for Live Streams with the state 'started'
8. Stop a Live Stream                                        => only for Live Streams with the state 'started'
9. Show the current state of a Live Stream
10. Show the thumbnail URL of a Live Stream                  => only for Live Streams with the state 'started'
11. Delete a Live Stream
12. Run the pre-configured Live Stream workflow
13. Quit :(

What do you want to do? Please enter a number!
```

The **Actions 1 to 11** are using single API calls to your account's data. This should give you an overview what you can do with the `/live_streams` endpoint on Wowza Streaming Cloud™.

**Action 12**'s - 'Run the pre-configured Live Stream workflow' - purpose is to give you an idea about the Live Stream workflow. It uses the same code that is used in the actions 1-11. It is separated into the following steps:

- create a Live Stream
- start the Live Stream
- poll the status of the Live Stream (to know when the Live Stream in your requested location is ready to use)
- poll status of the player that was created with your Live Stream (to know when the player and the hosted page are successfully provisioned and ready to use)
- receive the hosted page URL (where you can watch the stream)
- stop the Live Stream
- delete the Live Stream

You will be guided through each step.

> Note: the Live Stream settings that are used in this sample application are based on an "Other RTSP Pull" encoder setting described in our user interface on https://cloud.wowza.com/. The data is stored in a JSON file in the 'data' directory:

```json
# data/live_stream.json
{
  "live_stream": {
    "name": "My Awesome Live Stream",
    "transcoder_type": "transcoded",
    "billing_mode": "pay_as_you_go",
    "broadcast_location": "us_west_california",
    "encoder": "other_rtsp",
    "delivery_method": "pull",
    "source_url": "1.2.3.4/axis-media/media.amp",
    "aspect_ratio_width": 1920,
    "aspect_ratio_height": 1080
  }
}
```

<a name="how_to_ruby_net_http"></a>
## How to use the Wowza Streaming Cloud™ API working with the Ruby Net::HTTP library

#### Get a list of all Live Streams of your account (GET):

```ruby
require 'net/http'

# build the URI to access the /live_streams endpoint
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/")

# initialize Net::HTTP using SSL
Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|

  # build the HTTP request
  request = Net::HTTP::Get.new uri.path
  # add authentication keys to the request header
  request['wsc-api-key'] = "API_KEY"
  request['wsc-access-key'] = "API_ACCESS_KEY"
  # add the right Content-Type to the header (always required when pushing data)
  request["Content-Type"] = "application/json"

  response = http.request(request)

  # get the response as JSON object
  puts JSON.parse(response.body)
  # get the response code
  puts response.code
  # loop through response headers:
  response.each_header do |key, value|
    puts "#{key} => #{value}"
  end

end
```

Example Response:
```json
# 200 OK
{
    "live_streams": [
        {
              "id": "kdgbsvth",
            "name": "My Awesome Live Stream",
             "...": "..."
        },
        {
              "id": "ftklwjvz",
            "name": "My Second Live Stream",
             "...": "..."
        }
    ]
}
```

> The other examples below only show the differences to the one above.

#### Create a new Live Stream (POST):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/")
...
  request = Net::HTTP::Post.new uri.path
  # add the body to the request and parse the hash to JSON (or load it from a JSON file)
  request.body = {
    "live_stream": { LIVE_STREAM_SETTINGS }
  }.to_json
...
```

Example Response:
```json
# 201 CREATED
{
    "live_stream": {
          "id": "kdgbsvth",
        "name": "My Awesome Live Stream",
         "...": "..."
    }
}
```

#### Details of a Live Stream (GET):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/")
...
  request = Net::HTTP::Get.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
                                   "id": "kdgbsvth",
                                 "name": "My Awesome Live Stream",
                      "transcoder_type": "transcoded",
                         "billing_mode": "pay_as_you_go",
                   "broadcast_location": "us_west_california",
                            "recording": false,
                  "closed_caption_type": "none",
                              "encoder": "other_rtsp",
                      "delivery_method": "pull",
                    "use_stream_source": false,
                   "aspect_ratio_width": 1920,
                  "aspect_ratio_height": 1080,
        "source_connection_information": { "source_url": "rtsp://..." },
                            "player_id": "g7kpkj1n",
                    "player_responsive": false,
                         "player_width": 640,
                     "player_countdown": false,
                    "player_embed_code": "in_progress",
              "player_hds_playback_url": "http://...",
              "player_hls_playback_url": "http://...",
                          "hosted_page": true,
                    "hosted_page_title": "My Awesome Event",
                      "hosted_page_url": "https://...",
            "hosted_page_sharing_icons": true,
                           "created_at": "2016-02-29T17:59:25.251Z",
                           "updated_at": "2016-02-29T17:59:25.604Z"
    }
}
```

#### Update a Live Stream (PATCH):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/")
...
  request = Net::HTTP::Patch.new uri.path
  # add the body to the request and parse the hash to JSON (or load it from a JSON file)
  request.body = {
    "live_stream": { LIVE_STREAM_SETTINGS }
  }.to_json
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
                                   "id": "kdgbsvth",
                                 "name": "My Updated Awesome Live Stream",
                                  "...": "..."
    }
}
```

#### Start a Live Stream (PUT):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/start/")
...
  request = Net::HTTP::Put.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
        "state": "starting"
    }
}
```

#### Reset a Live Stream (PUT):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/reset/")
...
  request = Net::HTTP::Put.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
        "state": "resetting"
    }
}
```

#### Stop a Live Stream (PUT):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/stop/")
...
  request = Net::HTTP::Put.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
        "state": "stopped"
    }
}
```

#### Poll the state of a Live Stream (GET):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/state/")
...
  request = Net::HTTP::Get.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
        "state": "started"
    }
}
```

#### Poll the state of a Player that was created with a Live Stream (GET):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/players/[PLAYER_ID]/state/")
...
  request = Net::HTTP::Get.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "player": {
        "state": "activated"
    }
}
```

#### Thumbnail URL (preview image) of a Live Stream (GET):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/thumbnail_url/")
...
  request = Net::HTTP::Get.new uri.path
...
```

Example Response:
```json
# 200 OK
{
    "live_stream": {
        "thumbnail_url": "http://..."
    }
}
```

#### Delete a Live Stream (DELETE):

```ruby
uri = URI("https://api.cloud.wowza.com/api/v1/live_streams/[LIVE_STREAM_ID]/")
...
  request = Net::HTTP::Delete.new uri.path
...
```

Example Response:
```json
# 204 NO CONTENT
```

<a name="references"></a>
## References

[Get Access to the Public Preview of the Wowza Streaming Cloud™ API](https://www.wowza.com/products/streaming-cloud/features/api-access-request)

[Your API Keys (API access required)](https://cloud.wowza.com/en/manage/access_keys)

[Interactive API Documentation (API access required)](https://sandbox.cloud.wowza.com/apidocs/v1/)

[Wowza Streaming Cloud Forum Articles](https://www.wowza.com/forums/content.php?775-Wowza-Streaming-Cloud-REST-API)

<a name="contact"></a>
## Contact

Wowza Media Systems™, LLC

Wowza Media Systems™ provides developers with a platform to create streaming applications and solutions. See [Wowza Developer Tools](https://www.wowza.com/resources/developers) to learn more about our APIs and SDK.

<a name="license"></a>
## License

TODO: Add legal text here or LICENSE.txt file
