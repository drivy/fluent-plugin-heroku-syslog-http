# frozen_string_literal: true

require 'helper'
require 'fluent/test/driver/parser'
require 'fluent/plugin/in_heroku_syslog_http'

require 'net/http'

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
    text = '<13>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo'
    expected_time = Time.strptime('2014-01-29T07:25:52+01:00', '%Y-%m-%dT%H:%M:%S%z').to_i
    event = {
      'syslog.pri' => '13',
      'syslog.facility' => 'user',
      'syslog.severity' => 'notice',
      'syslog.hostname' => 'host',
      'syslog.appname' => 'app',
      'syslog.procid' => 'web.1',
      'syslog.timestamp' => '2014-01-29T06:25:52.589365+00:00',
      'message' => 'foo'
    }
    d = create_driver
    d.instance.parse(text) do |time, record|
      assert_equal expected_time, time
      assert_equal event, record
    end
  end

  def test_parsing_pri_conf
    d = create_driver

    d.instance.parse('<13>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo') do |_, record|
      assert_equal 'notice', record['syslog.severity']
      assert_equal 'user', record['syslog.facility']
    end
    d.instance.parse('<42>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo') do |_, record|
      assert_equal 'crit', record['syslog.severity']
      assert_equal 'syslog', record['syslog.facility']
    end
    d.instance.parse('<27>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo') do |_, record|
      assert_equal 'err', record['syslog.severity']
      assert_equal 'daemon', record['syslog.facility']
    end
  end
end
