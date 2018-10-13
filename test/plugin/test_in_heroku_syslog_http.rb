# frozen_string_literal: true

require 'helper'
require 'fluent/test/driver/input'
require 'fluent/plugin/in_heroku_syslog_http'
require 'fluent/plugin/filter_heroku_syslog_http'

require 'net/http'

class HerokuSyslogHttpInputTest < Test::Unit::TestCase
  class << self
    def startup
      socket_manager_path = ServerEngine::SocketManager::Server.generate_path
      @server = ServerEngine::SocketManager::Server.open(socket_manager_path)
      ENV['SERVERENGINE_SOCKETMANAGER_PATH'] = socket_manager_path.to_s
    end

    def shutdown
      @server.close
    end
  end

  def setup
    Fluent::Test.setup
  end

  PORT = unused_port
  CONFIG = %(
    @type heroku_syslog_http
    port #{PORT}
    bind 127.0.0.1
    body_size_limit 10m
    keepalive_timeout 5
  )

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HerokuSyslogHttpInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal PORT, d.instance.port
    assert_equal '127.0.0.1', d.instance.bind
    assert_equal 10 * 1024 * 1024, d.instance.body_size_limit
    assert_equal 5, d.instance.keepalive_timeout
  end

  def test_time_format
    d = create_driver
    messages = [
      '59 <13>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo',
      '59 <13>1 2014-01-30T07:35:00.123456+09:00 host app web.1 - bar'
    ]

    event_times = [
      Time.strptime('2014-01-29T06:25:52+00:00', '%Y-%m-%dT%H:%M:%S%z').to_i,
      Time.strptime('2014-01-30T07:35:00+09:00', '%Y-%m-%dT%H:%M:%S%z').to_i
    ]

    d.run(expect_records: 2, timeout: 5) do
      res = post(messages)
      assert_equal '', res.body
      assert_equal '200', res.code
    end

    assert_equal event_times[0], d.events[0][1]
    assert_equal event_times[1], d.events[1][1]
  end

  def test_msg_size
    d = create_driver

    messages = [
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 100,
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 1024
    ]

    event_messages = [
      'x' * 100,
      'x' * 1024
    ]
    d.run(expect_records: 2, timeout: 5) do
      res = post(messages)
      assert_equal '200', res.code
    end

    assert_equal event_messages[0], d.events[0][2]['message']
    assert_equal event_messages[1], d.events[1][2]['message']
  end

  def test_accept_matched_drain_id_multiple
    d = create_driver(CONFIG + %(
      drain_ids ["abc", "d.fc6b856b-3332-4546-93de-7d0ee272c3bd"]
    ))

    messages = [
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - foo',
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - bar'
    ]

    d.run(expect_records: 2, timeout: 5) do
      res = post(messages)
      assert_equal '200', res.code
    end
    assert_equal 2, d.events.length
  end

  def test_ignore_unmatched_drain_id
    d = create_driver(CONFIG + %(
      drain_ids ["abc"]
    ))

    messages = [
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - foo',
      '00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - bar'
    ]

    d.run(expect_records: 0, timeout: 5) do
      res = post(messages)
      assert_equal '200', res.code
    end

    assert_equal 0, d.events.length
  end

  def post(messages)
    # https://github.com/heroku/logplex/blob/master/doc/README.http_drains.md
    http = Net::HTTP.new('127.0.0.1', PORT)
    headers = {
      'Content-Type' => 'application/logplex-1',
      'Logplex-Msg-Count' => messages.length.to_s,
      'Logplex-Frame-Id' => '09C557EAFCFB6CF2740EE62F62971098',
      'Logplex-Drain-Token' => 'd.fc6b856b-3332-4546-93de-7d0ee272c3bd',
      'User-Agent' => 'Logplex/v49'
    }
    req = Net::HTTP::Post.new('/heroku', headers)
    req.body = messages.join("\n")
    http.request(req)
  end
end
