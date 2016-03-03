/**
 * <<<live_stream_example.rb>>> and all components (c) Copyright 2006 - 2016, Wowza Media Systems, LLC.  All rights reserved.  This <<module>> is licensed pursuant to the Wowza Public License version 1.0, available at www.wowza.com/legal.
 */

#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'highline'
require 'net/http'
require 'awesome_print'
require 'shell-spinner'

class LiveStreamApiExample

  # init application
  #
  def initialize
    init_config
  end

  # returns the amount of Live Streams in your account, using:
  #
  # GET /live_streams
  #
  # returns the full API response object
  #
  def count
    response = call_api method: :get
    json = JSON.parse(response.body)
    if response.code.to_i==200
      ap("Found #{json['live_streams'].size} Live Streams total.", color: {string: :green})
    else
      ap(JSON.parse(response.body))
    end
    return response
  end

  # returns a list of Live Streams in your account, using:
  #
  # GET /live_streams
  #
  # options:
  #  simple: true|false (optional, default: false)
  #          if set to true a simple list with name and id is returned
  #          if set to false (or nil) the original JSON list is returned
  #
  def list options={}
    response = call_api method: :get
    if options[:simple]
      json = JSON.parse(response.body)
      json['live_streams'].collect{ |ls| puts "#{ls['id']}: #{ls['name']}" }
    else
      ap JSON.parse(response.body), index: false
    end
    return response
  end

  # creates a pre-configured Live Stream, using:
  #
  # POST /live_streams
  #
  # the JSON data with the settings of the Live Stream that is pushed to the API
  # is stored in a file 'data/live_stream.json'
  #
  # returns the full API response object
  #
  def create create_json
    response = call_api method: :post, body: create_json
    ap JSON.parse(response.body)
    return response
  end

  # shows the details of a Live Stream, using:
  #
  # GET /live_streams/[ID]
  #
  # returns the full API response object
  #
  def show uid
    response = call_api method: :get, id: uid
    ap JSON.parse(response.body)
    return response
  end

  # updates a Live Stream with pre-configured settings, using:
  #
  # PATCH /live_streams/[ID]
  #
  # the JSON data with the settings of the Live Stream that is pushed to the API
  # is stored in a file 'data/live_stream/update_example.json'
  #
  # returns the full API response object
  #
  def update uid
    update_json = JSON.parse(File.read('./data/live_stream/update_example.json'))
    response = call_api method: :patch, id: uid, body: update_json
    ap JSON.parse(response.body)
    return response
  end

  # starts a Live Stream, using:
  #
  # PUT /live_streams/[ID]/start
  #
  # returns the full API response object
  #
  def start uid
    response = call_api method: :put, id: uid, action: '/start'
    ap JSON.parse(response.body)
    return response
  end

  # resets a Live Stream, using:
  #
  # PUT /live_streams/[ID]/reset
  #
  # returns the full API response object
  #
  def reset uid
    response = call_api method: :put, id: uid, action: '/reset'
    ap JSON.parse(response.body)
    return response
  end

  # stops a Live Stream, using:
  #
  # PUT /live_streams/[ID]/stop
  #
  # returns the full API response object
  #
  def stop uid
    response = call_api method: :put, id: uid, action: '/stop'
    ap JSON.parse(response.body)
    return response
  end

  # shows the state of a Live Stream, using:
  #
  # GET /live_streams/[ID]/state
  #
  # returns the full API response object
  #
  def state uid
    response = call_api method: :get, id: uid, action: '/state'
    ap JSON.parse(response.body)
    return response
  end

  # shows the thumbnail URL (preview image) of a Live Stream, using:
  #
  # GET /live_streams/[ID]/thumbnail_url
  #
  # returns the full API response object
  #
  def thumbnail_url uid
    response = call_api method: :get, id: uid, action: '/thumbnail_url'
    ap JSON.parse(response.body)
    return response
  end

  # deletes a Live Stream, using:
  #
  # DELETE /live_streams/[ID]
  #
  # returns the full API response object
  #
  def delete uid
    response = call_api method: :delete, id: uid
    ap "#{uid} deleted!", color: {string: :green} if response.code=="204"
    return response
  end

  # shows the state of a Player, using:
  #
  # GET /players/[ID]/state
  #
  # returns the full API response object
  #
  def player_state uid
    response = call_api method: :get, endpoint: 'players', id: uid, action: '/state'
    ap JSON.parse(response.body)
    return response
  end

  # demonstrates a pre-defined workflow of a Live Stream in multiple steps:
  #
  # - create Live Stream
  # - start Live Stream
  # - poll status of Live Stream
  # - poll status of Player
  # - receive hosted page URL of Live Stream
  # - stop Live Stream
  # - delete Live Stream
  #
  def workflow
    next_step_text = "Are you ready? Hit Enter to continue with the next step!"
    next_step = 1

    # First Step: create
    ap "Step #{next_step}: We are going to create a new pre-configured Live Stream.", color: {string: :purpleish}
    puts "\n"
    @cli.ask next_step_text
    # we are going to use the pre-configured 'Other RTSP Pull' example
    encoder_json = JSON.parse(File.read('./data/live_stream/encoder_types/other_rtsp_pull.json'))
    response = create encoder_json
    response_json = JSON.parse(response.body)

    # error handling
    unless response.code=="201"
      puts "\n"
      ap "An error occured. Please check the error above! Returning to Main Menu...", color: {string: :red}
      menu
      return
    end

    # save the id and the player id of the live stream for later use
    id = response_json['live_stream']['id']
    player_id = response_json['live_stream']['player_id']
    next_step += 1

    # Next Step: start
    puts "\n"
    ap "Step #{next_step}: Next we are going to start this Live Stream.", color: {string: :purpleish}
    puts "\n"
    @cli.ask next_step_text
    response = start id
    state = JSON.parse(response.body)['live_stream']['state']
    next_step += 1

    # Next Step: state
    puts "\n"
    ap "Step #{next_step}: Now we are going to check the state of this Live Stream every 10 seconds and wait until it is started.", color: {string: :purpleish}
    puts "\n"
    @cli.ask next_step_text
    while state=='starting' do
      response = state id
      state = JSON.parse(response.body)['live_stream']['state']
      if state=='starting'
        ap "State: '#{state}'. Let's wait a bit and poll again...", color: {string: :yellowish}
        puts "\n"
        sleep 10
      end
    end
    next_step += 1

    # Continue with workflow if Live Stream was started successfully
    if state=="started"
      ap "Nice! Stream #{state}.", color: {string: :green}

      # Next Step: player state
      puts "\n"
      ap "Step #{next_step}: Now we are going to check the state of the player (that was created with the Live Stream) every 10 seconds and wait until the provisioning is finished.", color: {string: :purpleish}
      puts "\n"
      @cli.ask next_step_text
      p_state ='requested'
      while p_state=='requested' do
        response = player_state player_id
        p_state = JSON.parse(response.body)['player']['state']
        if p_state=='requested'
          ap "State: '#{p_state}'. Let's wait a bit and poll again...", color: {string: :yellowish}
          puts "\n"
          sleep 10
        end
      end
      next_step += 1

      # Continue with workflow if Player was provisioned successfully
      if p_state=='activated'
        # Next Step: show
        puts "\n"
        ap "Step #{next_step}: Now we want to see the updated details of the started Live Stream to get the URL of the hosted page.", color: {string: :purpleish}
        puts "\n"
        @cli.ask next_step_text
        response = show id
        hosted_page_url = JSON.parse(response.body)['live_stream']['hosted_page_url']
        ap "There it is! If you like to see a hosted page and a player with your Live Stream, feel free to open this URL in your browser:", color: {string: :yellowish}
        puts "\n#{hosted_page_url}\n\n"
        ap "And by the way: Now would also be a good time to tweet it or announce it somewhere programmatically.", color: {string: :yellowish}
        next_step += 1
      else
        puts "\n"
        ap "Unfortunately something went wrong provisioning the Player of your Live Stream. Let's continue with the next step.", color: {string: :red}
      end

      # Next Step: stop
      puts "\n"
      ap "Step #{next_step}: Ok, let's go ahead and stop the Live Stream again.", color: {string: :purpleish}
      puts "\n"
      @cli.ask next_step_text
      stop id
      next_step += 1

      # Next Step: delete
      puts "\n"
      ap "Step #{next_step}: And finally we clean up a bit and delete the Live Stream.", color: {string: :purpleish}
      puts "\n"
      @cli.ask next_step_text
      delete id
      next_step += 1

      puts "\n"
      ap "Workflow finished!", color: {string: :yellowish}
      puts "\n"
      @cli.ask "Thank you! Hit Enter to return to Main Menu!"
    # Error handling if the Live Stream failed to start
    else
      puts "\n"
      ap "Unfortunately something went wrong starting the Live Stream. Going to delete the Live Stream and return to Main Menu!", color: {string: :red}
      puts "\n"
      delete id
      menu
      return
    end
  end

  # calling the WSC API, using the Ruby Net::HTTP library
  #
  # available options (options[:NAME]):
  #
  # method: the HTTP method you want to use to call the API
  #  supported values: :get, :post, :patch, :put, :delete
  #
  # endpoint: the endpoint to call, default: live_streams (optional)
  #  supported values: any existing endpoint of the Wowza Streaming Cloud API
  #
  # id: the unique id of a live stream (optional)
  #  supported values: any existing id of a live stream of your account on https://cloud.wowza.com
  #
  # action: the action you want to call (optional)
  #  supported values: '/state', '/start', '/reset', '/stop', '/thumbnail_url'
  #
  # body: a JSON interpretation of live stream settings you want to push to the API (optional)
  #  supported values: any JSON that contains valid properties and is wrapped in a root element 'live_streams'
  #
  def call_api options = {}
    endpoint = options[:endpoint] ||'live_streams'
    api_uri = URI("#{@settings["api_base_url"]}/api/#{@settings["api_version"]}/#{endpoint}/#{options[:id]}#{options[:action]}")
    response = nil
    ShellSpinner "calling #{options[:method].upcase} #{api_uri.to_s}" do # each call to the external API is showing a little spinner while running
      puts "\n"
      Net::HTTP.start(api_uri.host, api_uri.port, use_ssl: api_uri.scheme == 'https') do |http|
        case options[:method]
        when :get
          request = Net::HTTP::Get.new api_uri.path
        when :post
          request = Net::HTTP::Post.new api_uri.path
          request.body = options[:body].to_json
        when :patch
          request = Net::HTTP::Patch.new api_uri.path
          request.body = options[:body].to_json
        when :put
          request = Net::HTTP::Put.new api_uri.path
          request.body = options[:body].to_json
        when :delete
          request = Net::HTTP::Delete.new api_uri.path
        end
        # add keys to Header for authentication
        request['wsc-api-key'] = @keys["api_key"]
        request['wsc-access-key'] = @keys["api_access_key"]
        # add the right Content-Type to Header (always required when pushing data)
        request["Content-Type"] = "application/json"

        response = http.request(request)
      end
    end

    # print response code and headers if debug setting turned on
    if @settings["debug"]
      puts "###### DEBUG #####"
      puts "HTTP Response Code: #{response.code}\n"
      puts "HTTP Response Headers:"
      response.each_header do |key, value|
        p "#{key} => #{value}"
      end
      puts "###### DEBUG #####\n"
    end

    return response
  end


  ##############################################################################
  # HELPER METHODS
  ##############################################################################

  # loads configuration from /config folder
  # error handling for missing properties
  #
  def init_config
    # load API keys YAML from config
    @keys = YAML.load_file('config/keys.yml')

    # error handling for missing API keys
    if @keys["api_key"].nil? || @keys["api_key"].empty?
      puts "No api_key specified in config/keys.yml!\n\n"
      quit
    end
    if @keys["api_access_key"].nil? || @keys["api_access_key"].empty?
      puts "No api_access_key specified in config/keys.yml!\n\n"
      quit
    end

    # load settings YAML from config
    @settings = YAML.load_file('config/settings.yml')

    # error handling for missing app settings
    if @settings["api_base_url"].nil? || @settings["api_base_url"].empty?
      puts "No api_base_url specified in config/settings.yml!\n\n"
      quit
    end
    if @settings["api_version"].nil? || @settings["api_version"].empty?
      puts "No api_version specified in config/settings.yml!\n\n"
      quit
    end
  end

  # launches application:
  # showing Wowza Intro and opening Main Menu
  #
  def launch!
    intro
    menu
  end

  # prints Wowza Intro
  #
  def intro
    puts "\n"
    puts "--------------------------------------------------------------------------------------------------------------\n\n"
    puts "              Wowza Streaming Cloud API - An example application for the Live Stream workflow  \n\n"
    puts "--------------------------------------------------------------------------------------------------------------\n\n"
    file = File.open("assets/wsc-logo-ascii.txt", "r")
    puts "#{file.read}\n"
    puts "--------------------------------------------------------------------------------------------------------------\n\n"
    puts "                                                   © 2013-#{Time.now.year} Wowza Media Systems™, LLC. All rights reserved.\n\n"
  end

  # displays Main Menu
  #
  def menu
    options = {
      count:         "Show the number of live streams in your account",
      list:          "List all live streams of your account",
      create:        "Create a live stream with pre-configured settings         => data/live_stream/encoder_types/*.json",
      show:          "Show the details of an existing live stream",
      update:        "Update a live stream with pre-configured settings         => data/live_stream/update_example.json",
      start:         "Start a live stream                                       => only for Live Streams with the state 'stopped'",
      reset:         "Reset a live stream                                       => only for Live Streams with the state 'started'",
      stop:          "Stop a live stream                                        => only for Live Streams with the state 'started'",
      state:         "Show the current state of a live stream",
      thumbnail_url: "Show the thumbnail URL of a live stream                  => only for Live Streams with the state 'started'",
      delete:        "Delete a live stream",
      workflow:      "Run the pre-configured live stream workflow",
      quit:          "Quit :("
    }
    @cli = HighLine.new
    loop do
      @cli.choose do |menu|
        puts "\n"
        ap "Main Menu"
        puts "\n"
        menu.prompt = "\nEnter the number for the action you want to execute."
        options.each_with_index do |(method, description), index|
          menu.choice(description) do
            puts "\n"
            puts "-----------------------------"
            ap "Processing Option #{index+1}: #{description}", color: {string: :cyanish}
            puts "-----------------------------\n\n"
            # list action with submenu for simple or detailed
            case method
            when :list
              @cli.choose do |menu|
                ap "Submenu"
                puts "\n"
                menu.prompt = "\nSimple or detailed? Please enter a number!"
                menu.choice("Simple (just id and name)") do
                  list simple: true
                end
                menu.choice("Detailed (full JSON response)") do
                  list
                end
                menu.choice("Back to Main Menu") do
                  menu
                end
              end
            # choose one of the pre-configured live stream setups
            when :create
              # build submenu with files from the data/live_streams directory
              @cli.choose do |menu|
                puts "\n"
                ap "Submenu"
                puts "\n"
                menu.prompt = "\nWhat pre-configured camera or encoder will you use to connect to Wowza Streaming Cloud? Please enter a number!"
                # let's search through the example directory
                Dir.glob("./data/live_stream/encoder_types/*.json").each do |f|
                  encoder_json = JSON.parse(File.read(f))
                  name = encoder_json['live_stream']['name'] rescue 'Unknown Name. Please change the content of the JSON and add a name!'
                  menu.choice(name) do
                    create encoder_json
                  end
                end
                menu.choice("Back to Main Menu") do
                  menu
                end
              end
            # actions without additional parameters
            when :workflow, :count, :quit
              send method
            # actions that needs a Live Stream ID to be selected from a list
            else
              # build submenu with existing Live Streams / call list live streams
              response = call_api method: :get
              json = JSON.parse(response.body)
              @cli.choose do |menu|
                puts "\n"
                ap "Submenu"
                puts "\n"
                menu.prompt = "\nWhich Live Stream do you want to call? Please enter a number!"
                json['live_streams'].each do |live_stream|
                  menu.choice("#{live_stream['name']} (#{live_stream['id']})") do
                    send method, live_stream['id']
                  end
                end
                menu.choice("Back to Main Menu") do
                  menu
                end
              end
            end
            puts "\n-----------------------------\n"
          end
        end
      end
    end
  end

  # exits the application
  #
  def quit
    puts "Goodbye!\n"
    exit
  end

end

# init and launch application
#
lswe = LiveStreamApiExample.new
lswe.launch!
