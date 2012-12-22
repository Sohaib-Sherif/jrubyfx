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
require 'java'
require 'jrubyfxml'

module JRubyFX
  module DSL
    include JRubyFX

    module ClassUtils
      def register_type(name, type)
        JRubyFX::DSL::NAME_TO_CLASSES[name.to_s] = type
      end
    end

    def self.included(mod)
      mod.extend(JRubyFX::DSL::ClassUtils)
    end

    # FIXME: This should be broken up with nice override for each type of 
    # fx object so we can manually create static overrides.
    NAME_TO_CLASSES = {
      # observable structs
      'observable_array_list' => proc { |*args| FXCollections.observable_array_list(*args) },
    }.merge(JFX_CLASS_HIERARCHY.flat_tree_inject(Hash) do |res, name, values|
        # Merge in auto-generated list of classes from all the imported classes
        unless values.is_a? Hash
          values.map do |i|
            # this regexp does snake_casing
            # Anybody got a better way to get the java class instead of evaling its name?
            res.merge!({i.snake_case.gsub(/(h|v)_(line|box)/, '\1\2') => eval(i)})
          end
          res
        else
          # we are not at a leaf node anymore, just pass on their work
          values
        end
      end)

    def method_missing(name, *args, &block)
      clazz = NAME_TO_CLASSES[name.to_s]
      super unless clazz

      build(clazz, *args, &block)
    end

    alias :node_method_missing :method_missing
  end
end
