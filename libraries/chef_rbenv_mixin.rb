#
# Cookbook:: ruby_rbenv
# Library:: Chef::Rbenv::Mixin
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright:: 2011-2017, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  module Rbenv
    module Mixin
      module ShellOut
        def shell_out!(*command_args)
          options = command_args.last.is_a?(Hash) ? command_args.pop : {}
          options[:env] = shell_environment.merge(options[:env] || {})

          super(*command_args.push(options))
        end

        def shell_environment
          if rbenv_user
            { 'USER' => rbenv_user, 'HOME' => Etc.getpwnam(rbenv_user).dir }
          else
            {}
          end
        end

        # Ensures $HOME is temporarily set to the given user. The original
        # $HOME is preserved and re-set after the block has been yielded
        # to.
        #
        # This is a workaround for CHEF-3940. TL;DR Certain versions of
        # `git` misbehave if configuration is inaccessible in $HOME.
        #
        # More info here:
        #
        #   https://github.com/git/git/commit/4698c8feb1bb56497215e0c10003dd046df352fa
        #
        def with_home_for_user(username, &block)
  
          time = Time.now.to_i
  
          ruby_block "set HOME for #{username} at #{time}" do
            block do
              ENV['OLD_HOME'] = ENV['HOME']
              ENV['HOME'] = begin
                require 'etc'
                Etc.getpwnam(username).dir
              rescue ArgumentError # user not found
                "/home/#{username}"
              end
            end
          end
  
          yield
  
          ruby_block "unset HOME for #{username} #{time}" do
            block do
              ENV['HOME'] = ENV['OLD_HOME']
            end
          end
        end
      end

      module ResourceString
        def to_s
          "#{@resource_name}[#{@rbenv_version || 'global'}::#{@name}] (#{@user || 'system'})"
        end
      end
    end
  end
end
