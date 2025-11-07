# frozen_string_literal: true

# Enumancer::Enum provides a declarative, type-safe registry for named values.
# Each entry is unique by both name and value. Values can be of any type,
# but you may optionally declare a type constraint using `type`.
# If type is defined, values are strictly checked.
#
# Enum entries are registered via `.entry(name, value)` and accessed via `.name` or `[]`.
# Each entry becomes a singleton method of the class and returns an instance of the enum.
#
# You may enable strict mode via `type Klass, strict: true`, which disables fallbacks
# and raises errors when accessing unknown names or values.
#
# @example Define an enum
#   class MyEnum < Enumancer::Enum
#     type Integer, strict: true
#     entry :low, 1
#     entry :high, 2
#   end
#
# @example Access values
#   MyEnum[:low].value         # => 1
#   MyEnum.high.to_sym         # => :low
#   MyEnum.low == MyEnum[:low] # => true
#
# @example Serialize to JSON
#   MyEnum.low.to_json         # => '{"name":"low","value":1}'
#
# @example Deserialize from JSON
#   MyEnum.from_json('{"name":"low"}') # => MyEnum.low

require 'json'

module Enumancer
  class Enum
    attr_reader :value

    def initialize(value)
      @value = value
    end

    # Returns the symbolic name of the value as a string
    #
    # @return [String]
    def to_s
      to_sym.to_s
    end

    # Returns the symbolic name of the value as a symbol
    #
    # @return [Symbol]
    def to_sym
      name = self.class.name_for(value)
      raise KeyError, "Unregistered enum value: #{value.inspect}" if name.nil? && self.class.strict?
      name || :unknown
    end

    # Returns a debug-friendly string representation
    #
    # @return [String]
    def inspect
      "#<#{self.class.name} #{to_sym.inspect}:#{value.inspect}>"
    end

    # Equality based on class and value
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && other.value == value
    end

    alias eql? ==
    def hash = value.hash

    # Serializes the enum to JSON
    #
    # @return [String]
    def to_json(*args)
      { name: to_sym, value: value }.to_json(*args)
    end

    class << self
      # Called when subclassing Enum
      #
      # @param subclass [Class]
      # @return [void]
      def inherited(subclass)
        subclass.instance_variable_set(:@registry, {})
        subclass.instance_variable_set(:@values, {})
        subclass.instance_variable_set(:@strict_mode, false)
      end

      # Declares the expected type of all enum values
      #
      # @param klass [Class] the type constraint for values
      # @param strict [Boolean] whether to enable strict mode
      # @return [void]
      def type(klass, strict: false)
        unless klass.is_a?(Class)
          raise ArgumentError, "Expected a Class, got #{klass.inspect}"
        end
        @value_type = klass
        @strict_mode = strict
      end

      # Returns whether strict mode is enabled
      #
      # @return [Boolean]
      def strict?
        @strict_mode == true
      end

      # Registers a new enum entry with a unique name and value
      #
      # @param name [Symbol, String] symbolic name of the entry
      # @param value [Object] value of the entry
      # @raise [ArgumentError] if name or value is already registered
      # @raise [TypeError] if value does not match declared type
      # @return [void]
      def entry(name, value)
        name = name.to_sym

        if defined?(@value_type) && !value.is_a?(@value_type)
          raise TypeError, "Invalid value type for #{name}: expected #{@value_type}, got #{value.class}"
        end

        if @values.key?(value)
          existing = @values[value]
          raise ArgumentError, "Duplicate value #{value.inspect} for #{name}; already assigned to #{existing}"
        end

        if @registry.key?(name)
          raise ArgumentError, "Duplicate name #{name}; already registered with value #{@registry[name].value.inspect}"
        end

        instance = new(value)
        @registry[name] = instance
        @values[value] = name

        define_singleton_method(name) { instance }
      end

      # Retrieves an enum instance by name
      #
      # @param name [Symbol, String]
      # @return [Enumancer::Enum, nil]
      def [](name)
        @registry[name.to_sym]
      end

      # Retrieves an enum instance by name, raising if not found
      #
      # @param name [Symbol, String]
      # @return [Enumancer::Enum]
      # @raise [KeyError]
      def fetch(name)
        @registry.fetch(name.to_sym)
      end

      # Resolves the symbolic name for a given value
      #
      # @param value [Object]
      # @return [Symbol, nil]
      def name_for(value)
        @values[value]
      end

      # Returns all registered enum instances
      #
      # @return [Array<Enumancer::Enum>]
      def all
        @registry.values
      end

      # Returns all registered names
      #
      # @return [Array<Symbol>]
      def keys
        @registry.keys
      end

      # Returns all raw values
      #
      # @return [Array<Object>]
      def values
        @registry.values.map(&:value)
      end

      # Removes an enum entry by name
      #
      # @param name [Symbol, String]
      # @return [Enumancer::Enum, nil] the removed entry or nil
      def remove(name)
        name = name.to_sym
        entry = @registry.delete(name)
        if entry
          @values.delete(entry.value)
          singleton_class.undef_method(name) if respond_to?(name)
        end
        entry
      end

      # Deserializes an enum from JSON
      #
      # @param json [String]
      # @return [Enumancer::Enum, nil]
      # @raise [KeyError] if strict and name is unknown
      def from_json(json)
        data = JSON.parse(json, symbolize_names: true)
        name = data[:name]
        raise KeyError, "Missing 'name' key in JSON" if name.nil?

        entry = self[name]
        if strict? && entry.nil?
          raise KeyError, "Unregistered enum name: #{name.inspect}"
        end
        entry
      end
    end
  end
end
