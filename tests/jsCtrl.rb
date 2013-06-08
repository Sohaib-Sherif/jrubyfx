#!/usr/bin/env jruby
=begin
JRubyFX - Write JavaFX and FXML in Ruby
Copyright (C) 2013 The JRubyFX Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end
require 'jrubyfx'

fxml_root File.dirname(__FILE__)

class ScriptFXApplication < JRubyFX::Application
  def start(stage)
    stage.title = "FXML with JavaScript"
    stage.width = 100
    stage.height = 100
    stage.fxml = ScriptFXController
    stage.show
  end
end

class ScriptFXController
  include JRubyFX::Controller
  fxml "jsCtrl.fxml"
  def hello
    puts "Whoa! Called from JavaScript! Groovy!"
  end
end
ScriptFXController.become_java!
ScriptFXApplication.launch
