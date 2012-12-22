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


# Update load path to include the JavaFX runtime and fail nicely if we can't find it
begin
  if ENV['JFX_DIR']
    $LOAD_PATH << ENV['JFX_DIR']
  else #should we check for 1.7 vs 1.8? oh well, adding extra paths won't hurt anybody (maybe performance loading)
    $LOAD_PATH << ENV_JAVA["sun.boot.library.path"].gsub(/[\/\\][amdix345678_]+$/, "") # strip i386 or amd64 (including variants). TODO: ARM
  end
  require 'jfxrt.jar'
rescue
  fail "JavaFX runtime not found.  Please install Java 7u4 or newer or set environment variable JAVAFX_DIR to the folder that contains jfxrt.jar"
end

# This feels kinda like a hack. If anyone has a better idea, please let me know
class Hash
  def stringify_tree
    self.inject([]) do |res, pair|
      name = "#{pair[0].to_s}."
      name = "" if name == "."
      
      values = pair[1]
      if values.is_a? Hash
        values = values.stringify_tree
      end
      # assume its an array...
      res.concat(values.map{|i| "#{name}#{i}"})
    end
  end
end

# If you need JavaFX, just include this module. Its sole purpose in life is to
# import all JavaFX stuff, plus a few useful Java classes (like Void)
module JFXImports
  
  # If something is missing, just java_import it in your code.
  # And then ask us to put it in this list
  JFX_CLASS_HIERARCHY = { :javafx => {
      :animation => %w[
        Animation
        AnimationTimer
        FadeTransition
        FillTransition
        Interpolator
        KeyFrame
        KeyValue
        ParallelTransition
        PathTransition
        PauseTransition
        RotateTransition
        ScaleTransition
        SequentialTransition
        StrokeTransition
        Timeline
        Transition
        TranslateTransition],
      :application => ['Platform'],
      :beans => {
        :property => ['SimpleDoubleProperty'],
        #TODO: import more
        :value => ['ChangeListener']  
      },
      :collections => ['FXCollections'],
      :event => %w[
        Event
        ActionEvent
        EventHandler],
      :fxml => ['Initializable', 'LoadException'],
      :geometry => %w[
        HorizontalDirection
        HPos
        Insets
        Orientation
        Pos
        Side
        VerticalDirection
        VPos],
      :scene => {
        :'' => %w[
          Group
          Node
          Parent
          Scene],
        :canvas => ['Canvas'],
        :chart => %w[
          CategoryAxis
          LineChart
          NumberAxis
          XYChart],
        # TODO: import more of these
        :control => %w[
          Accordion
          Button
          CheckBox
          CheckBoxTreeItem
          CheckMenuItem
          ChoiceBox
          ColorPicker
          ComboBox
          ContextMenu
          Hyperlink
          Label
          ListCell
          ListView
          Menu
          MenuBar
          MenuButton
          MenuItem
          Pagination
          PasswordField
          PopupControl
          ProgressBar
          ProgressIndicator
          RadioButton
          RadioMenuItem
          ScrollBar
          ScrollPane
          Separator
          SeparatorMenuItem
          Slider
          SplitMenuButton
          SplitPane
          Tab
          TableView
          TabPane
          TextArea
          TextField
          ToggleButton
          ToggleGroup
          ToolBar
          Tooltip
          TreeItem
          TreeView
          ContentDisplay
          OverrunStyle
          SelectionMode],
        :effect => %w[
          Blend
          BlendMode
          Bloom
          BlurType
          DropShadow
          GaussianBlur
          Reflection
          SepiaTone],
        :image => %w[
          Image
          ImageView
          PixelReader
          PixelWriter],
        :input => %w[
          Clipboard
          ContextMenuEvent
          DragEvent
          GestureEvent
          InputEvent
          InputMethodEvent
          KeyEvent
          Mnemonic
          MouseDragEvent
          MouseEvent
          RotateEvent
          ScrollEvent
          SwipeEvent
          TouchEvent
          ZoomEvent],
        :layout => %w[
          AnchorPane
          BorderPane
          ColumnConstraints
          FlowPane
          GridPane
          HBox
          Priority
          RowConstraints
          StackPane
          TilePane
          VBox],
        :media => %w[
          Media
          MediaPlayer
          MediaView],
        # TODO: fill this out
        :paint => %w[
          Color
          CycleMethod
          ImagePattern
          LinearGradient
          Paint
          RadialGradient
          Stop],
        :shape => %w[
          Arc
          ArcTo
          ArcType
          Circle
          ClosePath
          CubicCurve
          CubicCurveTo
          Ellipse
          FillRule
          HLineTo
          Line
          LineTo
          MoveTo
          Path
          PathElement
          Polygon
          Polyline
          QuadCurve
          QuadCurveTo
          Rectangle
          Shape
          StrokeLineCap
          StrokeLineJoin
          StrokeType
          SVGPath
          VLineTo],
        :text => %w[
          Font
          FontPosture
          FontSmoothingType
          FontWeight
          Text
          TextAlignment
          TextBoundsType],
        :transform => %w[
          Affine
          Rotate
          Scale
          Shear
          Translate],
        :web => ['WebView']
      },
      :stage => %w[
        DirectoryChooser
        FileChooser
        Modality
        Popup
        PopupWindow
        Screen
        Stage
        StageStyle
        Window
        WindowEvent],
      :util => ['Duration']
    }
  }
  
  JF
  java_import 'java.lang.Void'
end
