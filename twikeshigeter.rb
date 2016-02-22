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
    search = client.home_timeline(count: 100)
    search.each do |tweet|
      if date_b.strftime("%Y/%m/%d %X") < tweet.created_at.strftime("%Y/%m/%d %X")
      # if true
        text = "#{tweet.created_at.strftime("%Y/%m/%d %X")}: #{tweet.text}"
        puts "TL #{text} :by @#{tweet.user.screen_name}"
        save("@#{tweet.user.screen_name}", text)
      end
    end
  rescue Twitter::Error::TooManyRequests => error
    sleep error.rate_limit.reset_in
    retry
  end
end


def save(username, text)
  File::open("#{username}.txt", "a") do |file|
    file.sync = true
    file.puts text
  end
end


def find_dtweet(client, user)
  tweets = client.user_timeline(user.screen_name, { count: 10})
  # 消されたtweetをすでに出力しているかどうか. 1: している, 0: していない
  printed_flag = 0
  tweets.each do |tweet|
    text = "#{tweet.created_at.strftime("%Y/%m/%d %X")}: #{tweet.text}"
    # ファイルが存在するかどうか
    if File.exist?("@#{user.screen_name}.txt")
      File::open("@#{user.screen_name}.txt", "r") do |file|
        file_tweets = file.each_line
        delete_flag = 1
        d_text = String.new
        file_tweets.each do |file_tweet|
          # puts file_tweet
          if file_tweet.chomp.casecmp(text) == 0
            puts "No deleted #{file_tweet}"
            delete_flag = 0
            break
          end
          d_text = file_tweet
        end #f_tweet.each
        if delete_flag == 1 && printed_flag == 0
          puts "Deleted #{d_text}"
          printed_flag = 1
        end
      end #File
    end #if File.exsit
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

  date_b = Time.now
  #
  following_users = following(client)
  #/
  while true do
    date_a = Time.now
    if (date_a-date_b).to_i > 60
      home_timeline(client, date_b)
      date_b = date_a
      #
      following_users.each do |user|
        sleep(40)
        find_dtweet(client, user)
      end
      #/
    end
    sleep(30)
  end
end


main()
