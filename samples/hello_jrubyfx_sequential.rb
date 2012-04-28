# Original version is here: http://www.oracle.com/technetwork/jp/ondemand/java/20110519-java-a-2-sato-400530-ja.pdf
# Modified by Hiroshi Nakamura <nahi@ruby-lang.org>

require 'jrubyfx'

class JRubyFXSequential
  include JRubyFX

  def init
  end

  def start(stage)
    stage.title = 'Hello JRubyFX'
    stage.width = 300
    stage.height = 200
    group = Group.new
    scene = Scene.new(group)
    scene.fill = Color::DARKBLUE
    stage.scene = scene
    rect = Rectangle.new
    rect.x = 10
    rect.y = 40
    rect.width = 50
    rect.height = 50
    rect.fill = Color::RED
    group.children << rect
    timeline = Timeline.new
    timeline.cycle_count = Timeline::INDEFINITE
    timeline.auto_reverse = true
    kf1 = KeyFrame.new(Duration::ZERO, KeyValue.new(rect.translateXProperty, 0))
    kf2 = KeyFrame.new(Duration.new(1000), KeyValue.new(rect.translateXProperty, 200))
    timeline.key_frames << kf1<< kf2
    timeline.play
    stage.show
  end

  def stop
  end
end

JRubyFX.start(JRubyFXSequential.new)
