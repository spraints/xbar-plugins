#!/usr/bin/env ruby

require "json"
require "net/http"
require "socket"

# From https://stackoverflow.com/questions/15637226/ruby-1-9-3-simple-get-request-to-unicorn-through-socket
module Net
  #  Overrides the connect method to simply connect to a unix domain socket.
  class SocketHttp < HTTP
    attr_reader :socket_path

    #  URI should be a relative URI giving the path on the HTTP server.
    #  socket_path is the filesystem path to the socket the server is listening to.
    def initialize(uri, socket_path)
      @socket_path = socket_path
      super(uri)
    end

    #  Create the socket object.
    def connect
      @socket = Net::BufferedIO.new(UNIXSocket.new(socket_path))
      on_connect
    end

    #  Override to prevent errors concatenating relative URI objects.
    def addr_port
      File.basename(socket_path)
    end
  end
end

Net::SocketHttp.new("--docker--", "/var/run/docker.sock").start do |http|
  resp = http.get("/containers/json")
  containers = JSON.parse(resp.body)
  puts "🐳 #{containers.size}"
  puts "---"
  containers.each do |container|
    puts(container["Names"].join(", "))
  end
end

<<RUBY_v1
ps = `/usr/local/bin/docker ps --format '{{.Names}}'`
containers = ps.lines.map(&:strip).select { |s| s != "" }.sort

puts "🐳 \#{containers.size}"
puts "---"
puts containers
RUBY_v1

<<OLD

#!/bin/bash

# <bitbar.title>NumContainers</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>cghamburg</bitbar.author>
# <bitbar.author.github>cghamburg</bitbar.author.github>
# <bitbar.desc>Print number of running Docker containers with whale unicode char</bitbar.desc>
# <bitbar.dependencies>docker</bitbar.dependencies>

CONTAINERS=$(/usr/local/bin/docker ps --format '{{.Names}}' | sort)
NUM_CONTAINERS=0
if [ -n "$CONTAINERS" ]
then
	NUM_CONTAINERS=$(echo "${CONTAINERS}" | wc -l | tr -d '[:space:]')
fi
echo "$(printf "🐳 %.0f \n" "${NUM_CONTAINERS}") | size=13"
echo "---"
echo "${CONTAINERS}"

OLD

# Changes:
# - 2021-11-23 - rewrote in ruby so that it only runs one subprocess.
# - 2021-11-23 - rewrote in ruby so that it talks directly to docker.
