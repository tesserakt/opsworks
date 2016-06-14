#
# Cookbook Name:: cs_spree_app_servers
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'build-essential'
include_recipe 'postgresql::client'
app = search(:aws_opsworks_app).first
rds_db_instance = search(:aws_opsworks_rds_db_instance).first
app_path = "/srv/#{app['shortname']}"

# For debugging
# Chef::Log.info("rds_db_instance")
# Chef::Log.info(rds_db_instance)
# Chef::Log.info("app")
# Chef::Log.info(app)

file '/root/.ssh/github.key' do
  content app["app_source"]["ssh_key"]
    mode '0600'
end

template '/root/.ssh/config' do
  source 'config.erb'
end

package 'git'

application app_path do

  ruby_runtime app['shortname'] do
    provider :ruby_build
    version '2.3.1'
  end

  git app_path do
    repository app["app_source"]["url"]
    revision app["app_source"]["revision"]
    deploy_key app["app_source"]["ssh_key"]
  end

  bundle_install do
    deployment true
    without %w{development test}
  end

  rails do
    database ''
    secret_token app['environment']['SECRET_KEY_BASE']
    migrate true
  end

  unicorn do
    port 8000
  end
end
