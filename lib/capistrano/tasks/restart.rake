namespace :deploy do
  after :finished, :restart_puma do
    on roles(:all) do
      execute "touch #{release_path}/tmp/restart.txt"
    end
  end
end
