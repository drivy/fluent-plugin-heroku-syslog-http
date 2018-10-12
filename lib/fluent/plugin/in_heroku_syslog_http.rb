require 'fluent/plugin/in_http'
require 'fluent/plugin/parser_regexp'

module Fluent::Plugin
  class HerokuSyslogHttpParser < RegexpParser
    Fluent::Plugin.register_parser('heroku_syslog_http', self)

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
    }

    PRIORITY_MAP = {
      0  => 'emerg',
      1  => 'alert',
      2  => 'crit',
      3  => 'err',
      4  => 'warn',
      5  => 'notice',
      6  => 'info',
      7  => 'debug'
    }

    def parse_prival(record)
      pri = record['pri'].to_i
      record['facility'] = FACILITY_MAP[pri >> 3]
      record['priority'] = PRIORITY_MAP[pri & 0b111]
      record
    end

    config_param :expression, :regexp, :default => /^([0-9]+)\s+\<(?<pri>[0-9]+)\>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?<pid>[a-zA-Z0-9\.]+)? *- *(?<message>.*)$/

    def parse(text)
      super(text) do |time, record|
        yield time, parse_prival(record)
      end
    end
  end

  class HerokuSyslogHttpInput < HttpInput
    Fluent::Plugin.register_input('heroku_syslog_http', self)

    config_section :parse do
      config_set_default :@type, 'heroku_syslog_http'
    end
    config_param :drain_ids, :array, :default => nil

    private

    def parse_params_with_parser(params)
      if content = params[EVENT_RECORD_PARAMETER]
        records = []
        messages = content.split("\n")
        messages.each do |msg|
          @parser.parse(msg) { |time, record|
            raise "Received event is not #{@format}: #{content}" if record.nil?

            record["time"] ||= Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S%z')
            record['drain_id'] = params['HTTP_LOGPLEX_DRAIN_TOKEN']
            unless @drain_ids.nil? || @drain_ids.include?(record['drain_id'])
              log.warn "drain_id not match: #{msg.inspect}"
              next
            end
            records << record
          }
        end
        return nil, records
      else
        raise "'#{EVENT_RECORD_PARAMETER}' parameter is required"
      end
    end
  end
end
