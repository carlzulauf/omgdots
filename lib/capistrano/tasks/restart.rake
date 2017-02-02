namespace :deploy do
  after :finished, :restart_puma do
    on roles(:all) do
      # execute "sudo systemctl restart puma.service"
      execute "touch #{File.join(release_path, 'tmp', 'restart.txt')}"
      # within release_path do
      # end
    end
  end
end
