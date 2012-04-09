#
# Cookbook Name:: cmon
# Recipe:: default
#
# Copyright 2012, Severalnines AB.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# cmon Agent
#
#include_recipe "cmon::agent_packages"
#include_recipe "cmon::agent"

#
# cmon Controller
#
#include_recipe "cmon::controller_packages"
include_recipe "cmon::controller"

#
# cmon Web app
#
#include_recipe "cmon::web_packages"
include_recipe "cmon::web"
