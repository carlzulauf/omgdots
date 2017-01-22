namespace :deploy do
  after :finished, :restart_puma do
    on roles(:all) do
      # execute "sudo systemctl restart puma.service"
      within release_path do
        execute "mkdir -p tmp"
        execute "touch tmp/restart.txt"
      end
    end
  end
end
