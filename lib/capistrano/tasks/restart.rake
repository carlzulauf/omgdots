namespace :deploy do
  after :finished, :restart_puma do
    on roles(:all) do
      execute "sudo systemctl restart omgdots_puma.service"
    end
  end
end
