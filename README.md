# fluent-plugin-heroku-syslog-http

Plugins to accept and parse syslog input from [heroku http(s) drains](https://devcenter.heroku.com/articles/log-drains#http-s-drains), based on fluentd'd [http input](https://docs.fluentd.org/v1.0/articles/in_http) and [regexp parser](https://docs.fluentd.org/v1.0/articles/parser_regexp)

## Installation

Install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-heroku-syslog-http

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-heroku-syslog-http
```

## Usage

### Configure heroku_syslog_http input

```
<source>
  type heroku_syslog_http
  port 9880
  bind 0.0.0.0
  tag  heroku
  drain_ids ["YOUR-HEROKU-DRAIN-ID"] # optional
</source>
```

### Example

Heroku's http syslog format:
`00 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - foo`

Will parse the following key/values:
```
{
  'syslog.pri' => '13',
  'syslog.facility' => 'user',
  'syslog.severity' => 'notice',
  'syslog.hostname' => 'host',
  'syslog.appname' => 'app',
  'syslog.procid' => 'web.1',
  'syslog.timestamp' => '2014-01-29T06:25:52.589365+00:00',
  'message' => 'foo'
}
```


## Copyright

- Copyright
  - Copytight(C) 2018- Drivy
  - Copyright(C) 2014-2018 Kazuyuki Honda (hakobera)
- License
  - Apache License, Version 2.0
