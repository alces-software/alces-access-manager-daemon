#==============================================================================
# Copyright (C) 2007-2016 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Access Manager Daemon.
#
# Alces Access Manager is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Access Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Access Manager Daemon, please visit:
# https://github.com/alces-software/alces-access-manager-daemon
#==============================================================================
source "http://rubygems.org"

# For rvm.
#ruby=2.2.1

ruby ENV['ALCES_RUBY_VERSION'] || '2.2.1'

git_source(:alces_github) { |repo_name| "https://github.com/alces-software/#{repo_name}.git" }

##################################
# Application server
##################################
gem                   'daemon-kit'

##################################
# Alces utility gems
##################################
gem              'alces-tools', :github => 'alces-software/alces-tools', :tag => '0.13.0'

##################################
# Alces Stack
##################################
gem                   'arriba', :github => 'alces-software/arriba', :branch => '0.6-stable'

##################################
# PAM
##################################
gem 		 'rpam-ruby19', alces_github: 'rpam-ruby19'

##################################
# Testing
##################################
group :test do
  gem                  'simplecov'
end

##################################
# Development
##################################
group :development do
end

##################################
# Development and Testing
##################################
group :development, :test do
  gem                      'rspec'
  gem                       'rake'
end
