# -*- coding: utf-8 -*-
require 'dotenv'
require 'twitter'
Dotenv.load

client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV["CONSUMER_KEY2"]
  config.consumer_secret = ENV["CONSUMER_SECRET2"]
  config.access_token = ENV["ACCESS_TOKEN2"]
  config.access_token_secret = ENV["ACCESS_TOKEN_SECRET2"]
end
for i in 0..100 do
  client.update(i)
  sleep(40)
end
