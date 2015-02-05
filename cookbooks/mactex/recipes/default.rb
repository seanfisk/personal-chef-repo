# -*- coding: utf-8 -*-
#
# Cookbook Name:: mactex
# Recipe:: default
#
# Copyright 2014, Sean Fisk
#
# Licensed under the Apache License, Version 2.0 (the "License"),
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

# Although this is now just a Homebrew Cask, it's useful to have as its own
# recipe so that it can be selectively added to the run_list. It's a huge
# download and install.

include_recipe 'homebrew::cask'

homebrew_cask 'mactex'

# rubocop:disable LineLength

# Blacklisting fonts as in MacTeX 2013 is no longer necessary with MacTeX 2014.
# For the old issues, see:
#
# - http://tex.stackexchange.com/questions/140840/lualatex-luaotfload-broke-after-upgrading-to-mavericks
# - https://github.com/lualatex/luaotfload/issues/139

# rubocop:enable LineLength
