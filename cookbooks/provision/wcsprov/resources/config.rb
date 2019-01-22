actions [:provision]
default_action :provision

action :provision do

  wcs_dir = '/usr/local/etc/wcs/ami'
  chef_conf_dir = "#{wcs_dir}/chef_conf"

  [ wcs_dir, chef_conf_dir ].each do |path|
    directory path do
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end

  bash 'change owner' do
    user 'root'
    code <<-EOH
    chown -R root:root #{wcs_dir}
    EOH
  end

  cookbook_file "/etc/motd" do
   source 'motd'
   owner 'root'
   group 'root'
   mode '0644'
   action :create
  end

  bash 'remove dinamyc motd' do
    code "rm -f /etc/update-motd.d/*"
  end

  chef_gem 'aws-sdk-ec2' do
    action :install
  end

  git "#{wcs_dir}/community-stack" do
    repository 'https://github.com/wizzie-io/community-stack.git'
    revision '1.1.0'
    action :checkout
  end

  file "#{wcs_dir}/.env" do
    content ''
    owner 'root'
    group 'root'
    mode '0644'
  end

  bash 'pull wcs images' do
    code <<-EOH
    PREFIX=/usr/local docker-compose -f #{wcs_dir}/community-stack/compose/docker-compose.yaml build
    PREFIX=/usr/local docker-compose -f #{wcs_dir}/community-stack/compose/docker-compose.yaml pull --ignore-pull-failures
    rm -f #{wcs_dir}/.env
    EOH
  end

  template '/etc/cloud/cloud.cfg.d/01-wdp.cfg' do
    source 'wdp-cloud-config.cfg.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  cookbook_file "#{wcs_dir}/bootstrap.sh" do
    source 'bootstrap.sh'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  cookbook_path = "#{wcs_dir}/bootstrap-cookbooks"
  template "#{chef_conf_dir}/solo.rb" do
    source 'solo.rb.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(:cookbook_path => cookbook_path)
    action :create
  end

  template "#{chef_conf_dir}/node.json" do
    source 'node.json.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end
