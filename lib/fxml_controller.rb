=begin
JRubyFXML - Write JavaFX and FXML in Ruby
Copyright (C) 2013 Patrick Plenefisch

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
  include JRubyFX
  include JRubyFX::DSL
  java_import 'java.net.URL'
  java_import 'javafx.fxml.FXMLLoader'
  
  attr_accessor :stage
  
  # block construct to define methods and automatically add action events
  def self.fx_handler(names, type=ActionEvent, &block)
    [names].flatten.each do |name|
      class_eval do
        #must define this way so block executes in class scope, not static scope
        define_method(name, block)
        #the first arg is the return type, the rest are params
        add_method_signature name, [Void::TYPE, type]
      end
    end
  end
  
  # get the singleton class, and add special overloads as fx_EVENT_handler
  # This funky syntax allows us to define methods on self (like define_method("self.method"),
  # except that does not work)
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
        # define the handy overloads that just pass our arguments in
        define_method("fx_#{method}_handler") do |name, &block|
          fx_handler(name, klass, &block)
        end
      end
    end
  end
  
  # FXML linked variable names by subclass
  @@fxml_linked_args = {}
  
  def self.fx_id(*name)
    # we must distinguish between subclasses, hence self.
    (@@fxml_linked_args[self] ||= []).concat(name)
  end
  
  def self.fx_id_optional(*names)
    fx_id names.map {|i| {i => :quiet} }
  end
  
  # set scene object (setter), and update fxml-injected values
  def scene=(s)
    @scene = s
    (@@fxml_linked_args[self.class] ||= []).each do |name|
      quiet = false
      # you can specify name => [quiet/verbose], so we need to check for that
      if name.is_a? Hash
        quiet = name.values[0] == :quiet
        name = name.keys[0]
      end
      # set each instance variable from the lookup on the scene
      val = s.lookup("##{name}")
      if val == nil && !quiet
        puts "[WARNING] fx_id not found: #{name}. Is id set to a different value than fx:id? (if this is expected, use fx_id_optional)"
      end
      instance_variable_set("@#{name}".to_sym, val)
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
  
  # Load given fxml file onto the given stage.
  def self.load_fxml(filename, stage, settings={})
    # Create our class as a java class with any arguments it wants
    ctrl = self.new_java *(settings[:initialize] || [])
    # save the stage so we can reference it if needed later
    ctrl.stage = stage
    # load the FXML file
    parent = load_fxml_resource(filename, ctrl, settings[:relative_to] || 1)
    # set the controller and stage scene, so that all the fx_id variables are hooked up
    ctrl.scene = stage.scene = if parent.is_a? Scene
      parent
    elsif settings.has_key? :fill
      Scene.new(parent, settings[:width] || -1, settings[:height] || -1, settings[:fill] || Color::WHITE)
    else
      Scene.new(parent, settings[:width] || -1, settings[:height] || -1, settings[:depth_buffer] || settings[:depthBuffer] || false)
    end
    # return the controller. If they want the new scene, they can call the scene() method on it
    return ctrl
  end
  
  # Load a FXML file given a filename and a controller and return the root element
  # relative_to can be a file that this should be relative to, or an index
  # of the caller number. If you are calling this from a function, pass 0 
  # as you are the immediate caller of this function
  def self.load_fxml_resource(filename, ctrlr=nil, relative_to=0)
    fx = FXMLLoader.new()
    fx.location = if FXApplication.in_jar?
      # If we are in a jar file, use the class loader to get the file from the jar (like java)
      JRuby.runtime.jruby_class_loader.get_resource(filename)
    else
      if relative_to.is_a? Fixnum or relative_to == nil
        # caller[0] returns a string like so:
        # "/home/user/.rvm/rubies/jruby-1.7.1/lib/ruby/1.9/irb/workspace.rb:80:in `eval'"
        # and then we use a regex to filter out the filename
        relative_to = caller[relative_to||0][/(.*):[0-9]+:in /, 1] # the 1 is the first match, aka everything up to the :
      end
      # If we are in the normal filesystem, create a normal file url path relative to the main file
      URL.new(URL.new("file:"), "#{File.dirname(relative_to)}/#{filename}")
    end
    # we must set this here for JFX to call our events
    fx.controller = ctrlr
    return fx.load()
  end
end
