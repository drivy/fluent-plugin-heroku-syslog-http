# frozen_string_literal: true

require 'helper'
require 'fluent/test/driver/parser'
require 'fluent/plugin/in_heroku_syslog_http'
require 'fluent/plugin/filter_heroku_syslog_http'

require 'net/http'
require 'pry'

# Stolen from fluentd/test/helper.rb
class Hash
  def corresponding_proxies
    @corresponding_proxies ||= []
  end
  def to_masked_element
    self
  end
end

class HerokuSyslogHttpParseTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = {})
    d = Struct.new(:instance).new
    d.instance = Fluent::Plugin::HerokuSyslogHttpParser.new
    d.instance.configure(conf)
    d
  end

  def test_parsing_with_default_conf
    text = '59 <13>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo'
    event = {
      'drain_id' => 'host',
      'facility' => 'user',
      'ident' => 'app',
      'message' => 'foo',
      'pid' => 'web.1',
      'pri' => '13',
      'priority' => 'notice'
    }
    d = create_driver
    d.instance.parse(text) do |time, record|
      assert_equal Time.strptime('2014-01-29T07:25:52+01:00', '%Y-%m-%dT%H:%M:%S%z').to_i, time
      assert_equal event, record
    end
  end
end
