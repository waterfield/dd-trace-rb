require 'sidekiq'

class IntegrationWorker
  include Sidekiq::Worker

  def perform(i=0)
    # puts "Threads: #{Thread.list.count}"
    # puts "FDS: #{Dir['/dev/fd/*'].size}"

    # puts i
    return if i == 10000
    IntegrationWorker.perform_async(i+1)
  end
end

### 5.0.1
# marco.costa      21155   0.2  0.6  4511064 105208   ??  S    10:55am   0:11.31 sidekiq 6.2.1  [0 of 10 busy]
# marco.costa      21250   0.0  0.6  4502872 104264   ??  S    10:56am   0:10.85 sidekiq 6.2.1  [0 of 10 busy]

# runtime metrics
# marco.costa      22786   0.0  0.6  4505312 103912   ??  S    11:03am   0:16.18 sidekiq 6.2.1  [0 of 10 busy]

### 4.8.3
# marco.costa      20782   0.0  0.6  4502872 105104   ??  S    10:53am   0:10.93 sidekiq 6.2.1  [0 of 10 busy]
# marco.costa      20881   0.0  0.6  4502872 104924   ??  S    10:54am   0:11.05 sidekiq 6.2.1  [0 of 10 busy]

# runtime metrics
# marco.costa      22975   0.0  0.5  4503944  90980   ??  S    11:04am   0:11.21 sidekiq 6.2.1  [0 of 10 busy]