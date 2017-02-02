namespace :deploy do
  after :finished, :restart_puma do
    on roles(:all) do
      execute "sudo systemctl restart omgdots_puma"
      # HOW TO LIMIT `deploy` USER TO JUST RESTARTING THIS ONE SERVICE:
      # in /etc/sudoers or /etc/sudoers.d/ add the following
      # %deploy ALL=NOPASSWD: /bin/systemctl restart omgdots_puma
    end
  end
end
