require 'sidekiq'

class IntegrationWorker
  include Sidekiq::Worker

  def perform(how_hard="super hard", how_long=0.1)
    puts "Threads: #{Thread.list.count}"
    puts "FDS: #{Dir['/dev/fd/*'].size}"

    sleep how_long
    puts "Workin' #{how_hard}"
    IntegrationWorker.perform_async
  end
end
