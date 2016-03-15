## god -c config.god で起動する.
## godとloop do ... end 以外のブロック処理の相性が悪いらしいので間にforemanを挟むことで回避する.

FILE_PATH = スクリプトのパス
God.watch do |w|
  # Godに登録するプロセスの名前
  w.name = "twikeshigeter"
  w.interval = 10.second
  # Godでプロセスを起動する際のコマンド
  # "ruby /hello.rb"のように記述する
  w.start = "foreman start -d #{FILE_PATH}"

  # プロセスを起動する条件の設定
  w.start_if do |start|
    start.condition(:process_running) do |c|  # プロセスの稼働状況をトリガーにする
      c.running = false       # プロセスが動いていない
    end
  end
end
