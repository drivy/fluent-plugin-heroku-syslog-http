# frozen_string_literal: true

require 'fluent/plugin/in_http'
require 'fluent/plugin/parser_regexp'

module Fluent
  module Plugin
    class HerokuSyslogHttpInput < HttpInput
      Fluent::Plugin.register_input('heroku_syslog_http', self)

      config_section :parse do
        config_set_default :@type, 'heroku_syslog_http'
      end
      config_param :drain_ids, :array, default: nil

      private

      def parse_params_with_parser(params)
        content = params[EVENT_RECORD_PARAMETER]
        raise "'#{EVENT_RECORD_PARAMETER}' parameter is required" unless content

        records = []
        messages = content.split("\n")
        messages.each do |msg|
          @parser.parse(msg) do |time, record|
            raise "Could not parse event: #{content}" if record.nil?

            record['syslog.timestamp'] ||= Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S%z')
            record['logplex.drain_id'] = params['HTTP_LOGPLEX_DRAIN_TOKEN']
            record['logplex.frame_id'] = params['HTTP_LOGPLEX_FRAME_ID']
            unless @drain_ids.nil? || @drain_ids.include?(record['logplex.drain_id'])
              log.warn "drain_id not match: #{msg.inspect}"
              next
            end
            records << record
          end
        end
        [nil, records]
      end
    end
  end
end
