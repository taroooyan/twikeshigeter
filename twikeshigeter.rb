# -*- coding: utf-8 -*-
require 'twitter'
require 'date'
require 'dotenv'


def following(client)
  # followings = []
  following_ids = client.friend_ids("taroooyan").to_a
  begin
    followings = following_ids.each_slice(100).to_a.inject ([]) do |users, ids|
      users.concat(client.users(ids))
    end
    return followings
  rescue Twitter::Error::TooManyRequests => error
    sleep error.rate_limit.reset_in
    retry
  end
end


def home_timeline(client, date_b)
  begin
    # timeline of specific user
    # search = client.user_timeline(USERNAME, { count: 100, since: 2016-02-20 })
    search = client.home_timeline(count: 100)
    search.each do |tweet|
      if date_b.strftime("%Y/%m/%d %X") < tweet.created_at.strftime("%Y/%m/%d %X")
        puts "#{tweet.created_at.strftime("%Y/%m/%d %X")}: #{tweet.text} :by @#{tweet.user.screen_name}"
        # puts tweet.methods
      end
    end
  rescue Twitter::Error::TooManyRequests => error
    sleep error.rate_limit.reset_in
    retry
  end
end


def main
  Dotenv.load
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV["CONSUMER_KEY"]
    config.consumer_secret = ENV["CONSUMER_SECRET"]
    config.access_token = ENV["ACCESS_TOKEN"]
    config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
  end

  # following_users = following(client)
  # following_users.each_with_index do|user, i|
  #   puts "#{i+1}: #{user.screen_name}"
  # end
  date_b = Time.now
  while true do
    date_a = Time.now
    if (date_a-date_b).to_i > 60
      # p date_b
      # p date_a
      home_timeline(client, date_b)
      date_b = date_a
    end
    # if date.strftime()
    # p Time.now.strftime("%Y/%m/%d %X")
    sleep(10)
  end

  
end


main()


