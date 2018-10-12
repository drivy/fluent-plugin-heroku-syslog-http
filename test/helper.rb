require 'rubygems'
require 'bundler'

require 'fluent/log'
require 'fluent/test'

def unused_port
  s = TCPServer.open(0)
  port = s.addr[1]
  s.close
  port
end
