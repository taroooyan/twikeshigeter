# -*- coding: utf-8 -*-
require 'twitter'
require 'date'
require 'dotenv'
require 'slack'

# Ctrl + C で停止させられた場合の処理を登録
Signal.trap(:INT){
  puts " SIGINT"
  exit(0)
}

# send to slack of #deleted-tweet channel
def notice_slack(message)
  Slack.configure do |config|
    Dotenv.load
    config.token = ENV["SLACK_API_TOKEN"]
  end
  Slack.chat_postMessage(text: message, channel: '#deleted-tweet')
end

# user別にtxtファイルに保存
def save(filename, text)
  File::open("#{filename}.txt", "a") do |file|
    file.sync = true
    file.puts text
  end
end

class TwitterInfo
  def initialize
    Dotenv.load
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV["CONSUMER_KEY"]
      config.consumer_secret = ENV["CONSUMER_SECRET"]
      config.access_token = ENV["ACCESS_TOKEN"]
      config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
    end
  end

  def following
    following_ids = @client.friend_ids.to_a
    begin
      followings = following_ids.each_slice(100).to_a.inject ([]) do |users, ids|
        users.concat(@client.users(ids))
      end
      return followings # Array
    rescue Twitter::Error::TooManyRequests => error
      sleep error.rate_limit.reset_in
      retry
    end
  end

  # 自分のタイムラインを取得してuser別に保存 前回の取得した時間を引数にとる
  def home_timeline(date_b)
    begin
      timelines = @client.home_timeline(count: 100)
      timelines.each do |tweet|
        if date_b.strftime("%Y/%m/%d %X") < tweet.created_at.strftime("%Y/%m/%d %X")
          text = "#{tweet.created_at.strftime("%Y/%m/%d %X")}: #{tweet.text}"
          puts "TL #{text} :by @#{tweet.user.screen_name}"
          save(tweet.user.screen_name, text)
        end
      end
    rescue Twitter::Error::TooManyRequests => error
      sleep error.rate_limit.reset_in
      retry
    end
  end

  def find_dtweet(user)
    tweets = Array.new
    lines = Array.new # fileから読み込んだもの
    delete_tweets = Array.new
    ## userの100件のタイムラインをtweetsに格納
    ## ツイートに改行が含まれている際の処理を改行で区切って対処することにする
    user_all_info = @client.user_timeline(user.screen_name, { count: 100})
    user_all_info.each do |user_info|
      text = "#{user_info.created_at.strftime("%Y/%m/%d %X")}: #{user_info.text}".split("\n")
      tweets.push(text)
    end
    tweets.flatten!
    p tweets
    ## /

    ## ファイルから逆順に一行ずつ読み込みlines格納し、linesの先頭100行を取る
    ## ことでファイルから逆順で100行をlinesに格納することを実現している
    # ファイルが存在するかどうか
    if File.exist?("#{user.screen_name}.txt")
      file_lines = String.new
      File::open("#{user.screen_name}.txt", "r") { |f| file_lines = f.read }
      file_lines.split("\n").each do |line|
        if line == "\n"
          next
        else
          lines.unshift(line.chomp)
        end
      end
      lines = lines.slice(0,99)
      puts '-'*80
      p lines
      puts '-'*80
      # ファイルにあってタイムラインに無いもののみを表示
      p delete_tweets =  lines - tweets
      # slackに一回で投稿するため
      notice_slack("[Deleted] @#{user.screen_name}\n#{delete_tweets.join("\n")}")
      puts '-'*80
    else
      File::open("#{user.screen_name}.txt", "w") do |file|
      end
    end # /File.exist?
    ## /
  end
end

def main
  notice_slack("[Startup] twikeshigeter")
  twitter = TwitterInfo.new()
  date_before = Time.now
  following_users = twitter.following
  # TLの取得回数
  count = 0
  loop do
    following_users.each do |user|
      twitter.find_dtweet(user)
      sleep(40)
      date_after = Time.now
      if (date_after-date_before).to_i > 60
        twitter.home_timeline(date_before)
        date_before = date_after
        count += 1
        notice_slack("[Running] #{count}回目のTL取得}") if count%60 == 0
      end
      sleep(30)
    end
  end # /loop
end

main
