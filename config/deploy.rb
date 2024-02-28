# Change these
set :scm, :rsync
set :rsync_options, %w[--recursive --delete --delete-excluded --exclude .git*]
set :build_dir, '../nandudu_build'

set :repo_url, 'ssh://git@git.nandianyunshang.com:7890/ndys/nandudu_api'
set :application,     'nandudu'

# If using Digital Ocean's Ruby on Rails Marketplace framework, your username is 'rails'
set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :rbenv_ruby,      "2.5.3"
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

## Defaults:
# set :scm,           :git
# set :branch,        :main
# set :format,        :pretty
# set :log_level,     :debug
set :keep_releases, 5

# files we want symlinking to specific entries in shared.
set :linked_files, %w{config/database.yml config/secrets.yml .env}

# dirs we want symlinking to shared
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads public/hls public/shared public/graphviz public/attachFiles public/static private/uploads private/export}

namespace :puma do
  Rake::Task[:restart].clear_actions
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  desc 'Check Puma Status'
  task :check_status do
    on roles(:app) do
      puts "检查 puma 的状态"
      execute "systemctl status puma"
    end
  end

  desc '重启动 Puma'
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :puma
    end
  end

  before 'deploy:starting', 'puma:make_dirs'
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do

      # Update this to your branch name: master, main, etc. Here it's main
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  #desc 'Restart application'
  #  task :restart do
  #    on roles(:app), in: :sequence, wait: 5 do
  #      puts "进行 重启 puma........"
  #      invoke 'puma:restart'
  #    end
  #end

  desc "Restart Puma"
  task :restart_puma do
    on roles(:app), in: :sequence, wait: 5 do
      puts "进行 重启 puma........"
      execute :sudo, :systemctl, :restart, :puma
    end
  end

  task :check_bundle_install do
    on roles(:app) do

      puts "进行 check_bundle_install"
      execute "ls -al"
    end
  end

  task :compile_assets do
    on roles(:app) do

      puts "进行 compile_assets"
      #execute "puts 1111111"
    end
  end

  before :starting,     :check_revision
  before "bundler:install",  "deploy:check_bundle_install"
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart_puma
  # after  :finishing,    :restart
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma