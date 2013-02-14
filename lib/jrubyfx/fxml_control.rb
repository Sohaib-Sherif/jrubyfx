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

# Inherit from this class for FXML controllers
module JRubyFX::Control
  include JRubyFX::DSL
  java_import 'java.net.URL'
  java_import 'javafx.fxml.FXMLLoader'

  attr_accessor :scene

  def self.included(base)
    base.extend(ClassMethods)
    # register ourselves as a control. overridable with custom_fxml_control
    base.instance_variable_set("@relative_to", caller[0][/(.*):[0-9]+:in /, 1])
    register_type base
  end

  # class methods for FXML controllers
  module ClassMethods
    include JRubyFX
    include JRubyFX::DSL

    # This is the default override for custom controls
    # Normal FXML controllers will use Control#new
    def new(*args, &block)
      # Custom controls don't always need to be pure java
      become_java! if @force_java

      # like new, without initialize
      ctrl = allocate

      # JRuby complains loudly (probably broken behavior) if we don't call the ctor
      # FIXME: we should be able to take arguments
      self.superclass.instance_method(:initialize).bind(ctrl).call

      # load the FXML file with the current control as the root
      fx = Control.get_fxml_loader(@filename || guess_filename(ctrl), ctrl, @relative_to)
      fx.root = ctrl
      fx.load

      # custom controls are their own scene
      ctrl.scene = ctrl

      # return the controller
      ctrl.initialize_controller *args, &block
    end

    #decorator to force becoming java class
    def become_java
      @force_java = true
    end

    # Set the filename of the fxml this control is part of
    def custom_fxml_control(fxml=nil, name = nil, relative_to = nil)
      @filename = fxml
      # snag the filename from the caller
      @relative_to = relative_to || caller[0][/(.*):[0-9]+:in /, 1]
      register_type(self, name) if name
    end

    # guess the fxml filename if nobody set it
    def guess_filename(obj)
      firstTry = obj.class.name[/([\w]*)$/, 1] + ".fxml"
      #TODO: check to see if snake_case version is on disk
      firstTry
    end

    # FXMLLoader#load also calls initialize
    # if defined, move initialize so we can call it when we're ready
    def method_added(meth)
      if meth == :initialize and not @ignore_method_added
        @ignore_method_added = true
        alias_method :initialize_callback, :initialize
        self.send(:define_method, :initialize) {|do_not_call_me|}
      end
    end


    ##
    # Event Handlers
    ##

    ##
    # call-seq:
    #   on(callback) { |event_info| block } => Method
    #   on(callback, EventType) { |event_info| block } => Method
    #   on_type(callback) { |event_info| block } => Method
    #
    # Registers a function of name `name` for a FXML defined event with the body in the block
    # Note: there are overrides for most of the default types, so you should never
    # need to manually specify the `type` argument unless you have custom events.
    # The overrides are in the format on_* where * is the event type (ex: on_key for KeyEvent).
    #
    # === Convienence Methods
    # * on_key           is for KeyEvent
    # * on_mouse         is for MouseEvent
    # * on_touch         is for TouchEvent
    # * on_gesture       is for GestureEvent
    # * on_context       is for ContextMenuEvent
    # * on_context_menu  is for ContextMenuEvent
    # * on_drag          is for DragEvent
    # * on_ime           is for InputMethodEvent
    # * on_input_method  is for InputMethodEvent
    # * on_window        is for WindowEvent
    # * on_action        is for ActionEvent
    # * on_generic       is for Event
    #
    # === Examples
    #   on :click do
    #     puts "button clicked"
    #   end
    #
    #   on_mouse :moved do |event|
    #     puts "Mouse Moved"
    #     p event
    #   end
    #
    #   on_key :keypress do
    #     puts "Key Pressed"
    #   end
    #
    # === Equivalent Java
    #   @FXML
    #   private void click(ActionEvent event) {
    #     System.out.println("button clicked");
    #   }
    #
    #   @FXML
    #   private void moved(MouseEvent event) {
    #     System.out.println("Mouse Moved");
    #   }
    #
    #   @FXML
    #   private void keypress(KeyEvent event) {
    #     System.out.println("Key Pressed");
    #   }
    #
    def on(names, type=ActionEvent, &block)
      [names].flatten.each do |name|
        class_eval do
          # must define this way so block executes in class scope, not static scope
          define_method name, block
          # the first arg is the return type, the rest are params
          add_method_signature name, [Void::TYPE, type]
        end
      end
    end

    {
      :key          => KeyEvent,
      :mouse        => MouseEvent,
      :touch        => TouchEvent,
      :gesture      => GestureEvent,
      :context      => ContextMenuEvent,
      :context_menu => ContextMenuEvent,
      :drag         => DragEvent,
      :ime          => InputMethodEvent,
      :input_method => InputMethodEvent,
      :window       => WindowEvent,
      :action       => ActionEvent,
      :generic      => Event
    }.each do |method, klass|
      # define the handy overloads that just pass our arguments in
      define_method("on_#{method}") { |name, &block| on name, klass, &block }
    end
  end

  # Initialize all controllers
  def initialize_controller(*args, &block)
    @nodes_by_id = {}

    # Everything is ready, call initialize_callback
    if private_methods.include? :initialize_callback
      self.send :initialize_callback, *args, &block
    end

    #return ourself
    self
  end

  ##
  #  Node Lookup Methods
  ##

  # searches for an element by id (or fx:id, prefering id)
  def method_missing(meth, *args, &block)
    # if scene is attached, and the method is an id of a node in scene
    if @scene
      @nodes_by_id[meth] ||= find "##{meth}"
      return @nodes_by_id[meth] if @nodes_by_id[meth]
    end

    super
  end

  # return first matched node or nil
  def find(css_selector)
    @scene.lookup css_selector
  end

  # Return first matched node or throw exception
  def find!(css_selector)
    res = find(css_selector)
    raise "Selector(#{css_selector}) returned no results!" unless res
    res
  end

  # return an array of matched nodes
  def css(css_selector)
    @scene.get_root.lookup_all(css_selector).map {|e| e}
  end


  ##
  # call-seq:
  #   get_fxml_loader(filename) => FXMLLoader
  #   get_fxml_loader(filename, controller_instance) => FXMLLoader
  #   get_fxml_loader(filename, controller_instance, relative_to) => FXMLLoader
  #
  # Load a FXML file given a filename and a controller and return the loader
  # relative_to can be a file that this should be relative to, or an index
  # of the caller number.
  # === Examples
  #   root = JRubyFX::Controller.get_fxml_loader("Demo.fxml").load
  #
  #   root = JRubyFX::Controller.get_fxml_loader("Demo.fxml", my_controller).load
  #
  # === Equivalent Java
  #   Parent root = FXMLLoader.load(getClass().getResource("Demo.fxml"));
  #
  def self.get_fxml_loader(filename, controller = nil, relative_to = nil)
    fx = FXMLLoader.new
    fx.location =
      if JRubyFX::Application.in_jar?
      # If we are in a jar file, use the class loader to get the file from the jar (like java)
      JRuby.runtime.jruby_class_loader.get_resource filename
    else
      # caller[0] returns a string like so:
      # "/home/user/.rvm/rubies/jruby-1.7.1/lib/ruby/1.9/irb/workspace.rb:80:in `eval'"
      relative_to ||= caller[1][/(.*):[0-9]+:in /, 1] # the 1 is the first match, aka everything up to the :
      # If we are in the normal filesystem, create a file url path relative to relative_to or this file
      URL.new "file:#{File.join File.dirname(relative_to), filename}"
    end
    # we must set this here for JFX to call our events
    fx.controller = controller
    fx
  end
end
