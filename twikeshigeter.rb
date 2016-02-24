# -*- coding: utf-8 -*-
require 'twitter'
require 'date'
require 'dotenv'
require 'slack'
$stdout.sync = true
# Ctrl + C で停止させられた場合の処理を登録
Signal.trap(:INT){
    puts " SIGINT"
      exit(0)
}


def progress_bar(i, max = 100)
  i = max if i > max
  rest_size = 1 + 5 + 1      # space + progress_num + %
  bar_width = 79 - rest_size # (width - 1) - rest_size = 72
  percent = i * 100.0 / max
  bar_length = i * bar_width.to_f / max
  bar_str = ('#' * bar_length).ljust(bar_width)
#  bar_str = '%-*s' % [bar_width, ('#' * bar_length)]
  progress_num = '%3.1f' % percent
  print "\r#{bar_str} #{'%5s' % progress_num}%"
end


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
        # puts "TL #{text} :by @#{tweet.user.screen_name}"
        save("@#{tweet.user.screen_name}", text)
      end
    end
  rescue Twitter::Error::TooManyRequests => error
    sleep error.rate_limit.reset_in
    retry
  end
end

# user別にtxtファイルに保存
def save(username, text)
  File::open("#{username}.txt", "a") do |file|
    file.sync = true
    file.puts text
  end
end


# フォロー中のユーザのtweetを100まで取得して保存する
def initializetion(client)
  followings = following(client)
  followings.each_with_index do |user, i|
    tweets = client.user_timeline(user.screen_name, { count: 100})
    tweets.each do |tweet|
      text = "#{tweet.created_at.strftime("%Y/%m/%d %X")}: #{tweet.text}"
      save("@#{tweet.user.screen_name}", text)
    end
    progress_bar(i, followings.size)
    sleep(60)
  end
end

# send to slack of #deleted-tweet channel
def notice_slack(message)
  Slack.configure do |config|
    Dotenv.load
    config.token = ENV["SLACK_API_TOKEN"]
  end
  Slack.chat_postMessage(text: message, channel: '#deleted-tweet')
end


def main
  Dotenv.load
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV["CONSUMER_KEY"]
    config.consumer_secret = ENV["CONSUMER_SECRET"]
    config.access_token = ENV["ACCESS_TOKEN"]
    config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
  end

  notice_slack("[Startup] twikeshigeter")
  date_b = Time.now
  following_users = following(client)
  # TLの取得回数
  count = 0
  while true do
    following_users.each do |user|
      find_dtweet(client, user)
      sleep(40)
      date_a = Time.now
      if (date_a-date_b).to_i > 60
        home_timeline(client, date_b)
        date_b = date_a
        count += 1
        notice_slack("[Running] #{count}回目の取得成功}") if count%60 == 0
      end
      sleep(30)
    end
  end
end


def create_user_file(client)
  followings = following(client)
  followings.each_with_index do |follower, i|
    text = ""
    save("@#{follower.screen_name}", text)
  end
end


def test
  Dotenv.load
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV["CONSUMER_KEY"]
    config.consumer_secret = ENV["CONSUMER_SECRET"]
    config.access_token = ENV["ACCESS_TOKEN"]
    config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
  end
  find_dtweet(client, client.user("USER"))
  # initializetion(client)
end


def find_dtweet(client, user)
  tweets = Array.new
  lines = Array.new
  delete_tweets = Array.new
  ## userの100件のタイムラインをtweetsに格納
  ## ツイートに改行が含まれている際の処理を改行で区切って対処することにする
  user_all_info = client.user_timeline(user.screen_name, { count: 100})
  user_all_info.each do |user_info|
    text = "#{user_info.created_at.strftime("%Y/%m/%d %X")}: #{user_info.text}".split("\n")
    tweets.push(text)
  end
  tweets.flatten!
  p tweets
  ## /

  ## ファイルから40行だけ逆順に一行ずつ読み込みlines格納
  # ファイルが存在するかどうか
  if File.exist?("@#{user.screen_name}.txt")
    File::open("@#{user.screen_name}.txt", "r") do |file|
      file_lines = file.each_line
      file_lines.each_with_index do |line, i|
        if i > 40
          break
        elsif line == "\n"
          next
        else
          lines.unshift(line.chomp)
        end
      end
    end # /File
  end # /if
  ## /
  puts '-'*80
  p lines
  puts '-'*80
  # ファイルにあってタイムラインに無いもののみを表示
  p delete_tweets =  lines - tweets
  delete_tweets.each do |delete_tweet|
    notice_slack("#{delete_tweet} :by @#{user.screen_name}")
  end
  puts '-'*80
end


main
# test

