## god -c config.god で起動する
God.watch do |w|
  # Godに登録するプロセスの名前
  w.name = "twikeshigeter"
  # Godでプロセスを起動する際のコマンド
  # "ruby /hello.rb"のように記述する
  w.start = ********

  # プロセスを起動する条件の設定
  w.start_if do |start|
    start.condition(:process_running) do |c|  # プロセスの稼働状況をトリガーにする
      c.running = false       # プロセスが動いていない
      c.interval = 5.seconds  # 条件をチェックする間隔
    end
  end
end
