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
;;;# What are the ;;;  and ### for?
;;;# lines that start with ;;; will be removed when we are embedded
;;;# lines that start with ### will be uncommented when we are embedded
;;;if $0 == __FILE__ && ARGV.length >=2 && ARGV[0] == "jar-ify"
  ;;;  lines = File.readlines(__FILE__)
  ;;;  lines = lines.find_all { |line| !line.strip.match(/^;;;/) }
  ;;;  File.open(ARGV[1], "w+") { |io| lines.each { |line| io.write line } }
  ;;;  exit 0
  ;;;end

require 'java'
;;;begin
  ;;;  require 'jrubyfx.jar'
  ;;;rescue LoadError
  ;;;  # lets pray its embedded
  ;;;  puts "[Warning] jrubyfx.jar not found - assuming its already loaded"
  ;;;end
require 'jruby/core_ext'

#not sure if I like this hackyness, but is nice for just running scripts.
#This is also in the rakefile
require ((Java.java.lang.System.getProperties["java.runtime.version"].match(/^1.7.[0123456789]+.(0[456789]|[1])/) != nil) ?
    Java.java.lang.System.getProperties["sun.boot.library.path"].gsub(/[\/\\][ix345678_]+$/, "") + "/" : "") + 'jfxrt.jar'

module JRubyFX
  java_import 'javafx.animation.FadeTransition'
  java_import 'javafx.animation.Interpolator'
  java_import 'javafx.animation.KeyFrame'
  java_import 'javafx.animation.KeyValue'
  java_import 'javafx.animation.ParallelTransition'
  java_import 'javafx.animation.RotateTransition'
  java_import 'javafx.animation.ScaleTransition'
  java_import 'javafx.animation.Timeline'
  java_import 'javafx.beans.property.SimpleDoubleProperty'
  java_import 'javafx.beans.value.ChangeListener'
  java_import 'javafx.collections.FXCollections'
  java_import 'javafx.event.ActionEvent'
  java_import 'javafx.event.EventHandler'
  java_import 'javafx.geometry.HPos'
  java_import 'javafx.geometry.VPos'
  java_import 'javafx.scene.Group'
  java_import 'javafx.scene.Scene'
  java_import 'javafx.scene.control.Button'
  java_import 'javafx.scene.control.Label'
  java_import 'javafx.scene.control.TableColumn'
  java_import 'javafx.scene.control.TableView'
  java_import 'javafx.scene.control.TextField'
  java_import 'javafx.scene.effect.Bloom'
  java_import 'javafx.scene.effect.GaussianBlur'
  java_import 'javafx.scene.effect.Reflection'
  java_import 'javafx.scene.effect.SepiaTone'
  java_import 'javafx.scene.image.Image'
  java_import 'javafx.scene.image.ImageView'
  java_import 'javafx.scene.layout.ColumnConstraints'
  java_import 'javafx.scene.layout.GridPane'
  java_import 'javafx.scene.layout.Priority'
  java_import 'javafx.scene.layout.HBox'
  java_import 'javafx.scene.layout.VBox'
  java_import 'javafx.scene.media.Media'
  java_import 'javafx.scene.media.MediaPlayer'
  java_import 'javafx.scene.media.MediaView'
  java_import 'javafx.scene.paint.Color'
  java_import 'javafx.scene.paint.CycleMethod'
  java_import 'javafx.scene.paint.RadialGradient'
  java_import 'javafx.scene.paint.Stop'
  java_import 'javafx.scene.shape.ArcTo'
  java_import 'javafx.scene.shape.Circle'
  java_import 'javafx.scene.shape.Line'
  java_import 'javafx.scene.shape.LineTo'
  java_import 'javafx.scene.shape.MoveTo'
  java_import 'javafx.scene.shape.Path'
  java_import 'javafx.scene.shape.Rectangle'
  java_import 'javafx.scene.text.Font'
  java_import 'javafx.scene.text.Text'
  java_import 'javafx.scene.transform.Rotate'
  java_import 'javafx.scene.web.WebView'
  java_import 'javafx.stage.Stage'
  java_import 'javafx.stage.StageStyle'
  java_import 'javafx.util.Duration'

  module ClassUtils
    def start(*args)
      JRubyFX.start(new(*args))
    end
  end

  def self.included(mod)
    mod.extend(ClassUtils)
  end

  def self.start(app)
    Java.org.jruby.ext.jrubyfx.JRubyFX.start(app)
  end
  
  def load_fxml(filename, ctrlr)
    fx = Java.javafx.fxml.FXMLLoader.new()
    fx.location = Java.java.net.URL.new(
      Java.java.net.URL.new("file:"), filename)
    fx.controller = ctrlr
    return fx.load
  end

  ##
  # Set properties (e.g. setters) on the passed in object plus also invoke
  # any block passed against this object.
  # === Examples
  #
  #   with(grid, vgap: 2, hgap: 2) do
  #     set_pref_size(500, 400)
  #     children << location << go << view
  #   end
  #
  def with(obj, properties = {}, &block)
    if block_given?
      obj.extend(JRubyFX)
      obj.instance_eval(&block)
    end
    properties.each_pair { |k, v| obj.send(k.to_s + '=', v) }
    obj
  end

  ##
  # Create "build" a new JavaFX instance with the provided class and
  # set properties (e.g. setters) on that new instance plus also invoke
  # any block passed against this new instance
  # === Examples
  #
  #   grid = build(GridPane, vgap: 2, hgap: 2) do
  #     set_pref_size(500, 400)
  #     children << location << go << view
  #   end
  #
  def build(klass, *args, &block)
    if !args.empty? and args.last.respond_to? :each_pair
      properties = args.pop 
    else 
      properties = {}
    end

    with(klass.new(*args), properties, &block)
  end

  def listener(mod, name, &block)
    obj = Class.new { include mod }.new
    obj.instance_eval do
      @name = name
      @block = block
      def method_missing(msg, *a, &b)
        @block.call(*a, &b) if msg == @name
      end
    end
    obj
  end
end

# inherit from this class for FXML controllers
class FXMLController
  java_import 'javafx.event.ActionEvent'
  java_import 'java.lang.Void'
  java_import 'java.net.URL'
  java_import 'java.util.ResourceBundle'
  
  include Java.javafx.fxml.Initializable #interfaces
  
  # block construct to define methods and automatically add action events
  def self.fxml_event(name, &block)
    class_eval do
      #must define this way so block executes in class scope, not static scope
      define_method(name, block)
      #the first arg is the return type, the rest are params
      add_method_signature name, [Void::TYPE, ActionEvent]
    end
  end
  
  # when initialize method is created, add java signature
  def self.method_added(name)
    if name == :initialize
      add_method_signature :initialize, [Void::TYPE, URL, ResourceBundle]
    end
  end
  
  # FXML linked variable names by class
  @@fxml_linked_args = {}
  
  def self.fxml_linked(name)
    # we must distinguish between subclasses, hence self.
    (@@fxml_linked_args[self] ||= []) << name
  end
  
  # set scene object (setter), and update fxml-injected values
  def scene=(s)
    @scene = s
    (@@fxml_linked_args[self.class] ||= []).each do |name|
      #set each instance variable from the lookup on the scene
      instance_variable_set("@#{name}".to_sym, s.lookup(name.to_s))
    end
  end
  
  # return the scene object (getter)
  def scene()
    @scene
  end
  
  #magic self-java-ifying new call
  def self.new_java
    self.become_java!
    self.new
  end
end

class JRubyFXApp < Java.javafx.application.Application
  
  java_import 'java.lang.Void'
  def self.run
    #Java.javafx.application.Application::launch
    Java.org.jruby.ext.jrubyfx.JRubyFX.start(JRubyFXApp.java_class)
  end
  add_method_signature :start, [Void::TYPE, Java.javafx.stage.Stage]
  def start(stage)
    puts "Started with"
    p stage
  end
  def initialize(arg)
    puts "initlize"
    p arg
  end
  
  def newInstance(arg)
    p arg
    puts "iniited"
  end
end

JRubyFXApp.become_java!
JRubyFXApp.run