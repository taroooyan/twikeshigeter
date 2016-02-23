# -*- coding: utf-8 -*-
require 'slack'
require 'dotenv'

Slack.configure { |config|
  Dotenv.load
  config.token = ENV["SLACK_API_TOKEN"]
}
Slack.chat_postMessage(text: 'test',channel: '#deleted-tweet')
