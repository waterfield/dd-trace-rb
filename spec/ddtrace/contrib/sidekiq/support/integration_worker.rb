require 'sidekiq'

class IntegrationWorker
  include Sidekiq::Worker

  def perform(i=0)
    # puts "Threads: #{Thread.list.count}"
    # puts "Open file descriptors: #{Dir['/dev/fd/*'].size}"

    puts i
    return if i == 10000
    IntegrationWorker.perform_async(i+1)
  end
end
