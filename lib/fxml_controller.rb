=begin
JRubyFXML - Write JavaFX and FXML in Ruby
Copyright (C) 2012 Patrick Plenefisch

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as 
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'jrubyfxml'

# inherit from this class for FXML controllers
class FXController
  include JFXImports
  java_import 'java.net.URL'
  java_import 'javafx.fxml.FXMLLoader'
  
  # block construct to define methods and automatically add action events
  def self.fx_handler(name, type=ActionEvent, &block)
    class_eval do
      #must define this way so block executes in class scope, not static scope
      define_method(name, block)
      #the first arg is the return type, the rest are params
      add_method_signature name, [Void::TYPE, type]
    end
  end
  
  #get the singleton class, and add special overloads as fx_EVENT_handler
  class << self
    include JFXImports
    {:key => KeyEvent,
      :mouse => MouseEvent,
      :touch => TouchEvent,
      :gesture => GestureEvent,
      :context => ContextMenuEvent,
      :context_menu => ContextMenuEvent,
      :drag => DragEvent,
      :ime => InputMethodEvent,
      :input_method => InputMethodEvent,
      :window => WindowEvent,
      :action => ActionEvent,
      :generic => Event}.each do |method, klass|
      #instance_eval on the self instance so that these are defined as class methods
      self.instance_eval do
        define_method("fx_#{method}_handler") do |name, &block|
          fx_handler(name, klass, &block)
        end
      end
    end
  end
  
  # FXML linked variable names by class
  @@fxml_linked_args = {}
  
  def self.fx_id(name)
    # we must distinguish between subclasses, hence self.
    (@@fxml_linked_args[self] ||= []) << name
  end
  
  # set scene object (setter), and update fxml-injected values
  def scene=(s)
    @scene = s
    (@@fxml_linked_args[self.class] ||= []).each do |name|
      #set each instance variable from the lookup on the scene
      instance_variable_set("@#{name}".to_sym, s.lookup("##{name}"))
    end
  end
  
  # return the scene object (getter)
  def scene()
    @scene
  end
  
  #magic self-java-ifying new call
  def self.new_java(*args)
    self.become_java!
    self.new(*args)
  end
  
  def self.load_fxml(filename, stage, settings={})
    ctrl = self.new_java *(settings[:initialize] || [])
    parent = load_fxml_resource(filename, ctrl)
    ctrl.scene = stage.scene = if parent.is_a? Scene
      parent
    elsif settings.has_key? :fill
      Scene.new(parent, settings[:width] || -1, settings[:height] || -1, settings[:fill] || Color::WHITE)
    else
      Scene.new(parent, settings[:width] || -1, settings[:height] || -1, settings[:depth_buffer] || settings[:depthBuffer] || false)
    end
    return ctrl
  end
  
  # Load a FXML file given a filename and a controller and return the root element
  def self.load_fxml_resource(filename, ctrlr)
    fx = FXMLLoader.new()
    fx.location = if FXApplication.in_jar?
      JRuby.runtime.jruby_class_loader.get_resource(filename)
    else
      URL.new(URL.new("file:"), "#{File.dirname($0)}/#{filename}") #hope the start file is relative!
    end
    fx.controller = ctrlr
    return fx.load()
  end
end
