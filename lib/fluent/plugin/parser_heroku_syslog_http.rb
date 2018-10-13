# frozen_string_literal: true

require 'fluent/plugin/in_http'
require 'fluent/plugin/parser_regexp'

module Fluent
  module Plugin
    class HerokuSyslogHttpParser < RegexpParser
      Fluent::Plugin.register_parser('heroku_syslog_http', self)

      SYSLOG_HTTP_REGEXP = %r{^([0-9]+) +\<(?<syslog.pri>[0-9]+)\>([0-9]+) (?<syslog.timestamp>[^ ]+) (?<syslog.hostname>[^ ]+) (?<syslog.appname>[^ ]+) (?<syslog.procid>[^ ]+) - *(?<message>.*)$}

      FACILITY_MAP = {
        0   => 'kern',
        1   => 'user',
        2   => 'mail',
        3   => 'daemon',
        4   => 'auth',
        5   => 'syslog',
        6   => 'lpr',
        7   => 'news',
        8   => 'uucp',
        9   => 'cron',
        10  => 'authpriv',
        11  => 'ftp',
        12  => 'ntp',
        13  => 'audit',
        14  => 'alert',
        15  => 'at',
        16  => 'local0',
        17  => 'local1',
        18  => 'local2',
        19  => 'local3',
        20  => 'local4',
        21  => 'local5',
        22  => 'local6',
        23  => 'local7'
      }.freeze

      PRIORITY_MAP = {
        0  => 'emerg',
        1  => 'alert',
        2  => 'crit',
        3  => 'err',
        4  => 'warn',
        5  => 'notice',
        6  => 'info',
        7  => 'debug'
      }.freeze

      config_set_default :expression, SYSLOG_HTTP_REGEXP
      config_set_default :time_key, 'syslog.timestamp'
      config_set_default :keep_time_key, true

      def parse_prival(record)
        if record && record['syslog.pri']
          pri = record['syslog.pri'].to_i
          record['syslog.facility'] = FACILITY_MAP[pri >> 3]
          record['syslog.priority'] = PRIORITY_MAP[pri & 0b111]
        end
        record
      end

      def parse(text)
        super(text) do |time, record|
          yield time, parse_prival(record)
        end
      end
    end
  end
end
