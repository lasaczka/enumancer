# frozen_string_literal: true

require 'rspec'
require_relative '../lib/enum'

RSpec.describe Enumancer::Enum do
  # Create a fresh enum class for each test
  let(:enum_class) do
    Class.new(Enumancer::Enum) do
      entry :draft, 0
      entry :published, 1
      entry :archived, 2
    end
  end

  describe '.entry' do
    it 'registers a new enum entry' do
      expect(enum_class[:draft]).to be_a(Enumancer::Enum)
      expect(enum_class[:draft].value).to eq(0)
    end

    it 'creates a singleton method for the entry' do
      expect(enum_class).to respond_to(:draft)
      expect(enum_class.draft.value).to eq(0)
    end

    it 'raises ArgumentError for duplicate names' do
      expect {
        enum_class.entry(:draft, 999)
      }.to raise_error(ArgumentError, /Duplicate name/)
    end

    it 'raises ArgumentError for duplicate values' do
      expect {
        enum_class.entry(:new_status, 0)
      }.to raise_error(ArgumentError, /Duplicate value/)
    end
  end

  describe '.type' do
    context 'with type constraint' do
      let(:typed_enum) do
        Class.new(Enumancer::Enum) do
          type Integer
          entry :low, 1
          entry :high, 100
        end
      end

      it 'accepts values of correct type' do
        expect(typed_enum.low.value).to eq(1)
      end

      it 'raises TypeError for wrong type' do
        expect {
          typed_enum.entry(:wrong, 'string')
        }.to raise_error(TypeError, /Invalid value type/)
      end
    end

    it 'raises ArgumentError if type is not a Class' do
      expect {
        Class.new(Enumancer::Enum) do
          type "not a class"
        end
      }.to raise_error(ArgumentError, /Expected a Class/)
    end
  end

  describe '.strict?' do
    it 'returns false by default' do
      expect(enum_class.strict?).to be false
    end

    context 'when strict mode is enabled' do
      let(:strict_enum) do
        Class.new(Enumancer::Enum) do
          type String, strict: true
          entry :active, 'active'
        end
      end

      it 'returns true' do
        expect(strict_enum.strict?).to be true
      end
    end
  end

  describe '.[]' do
    it 'retrieves entry by symbol name' do
      entry = enum_class[:draft]
      expect(entry.value).to eq(0)
    end

    it 'retrieves entry by string name' do
      entry = enum_class['draft']
      expect(entry.value).to eq(0)
    end

    it 'returns nil for unknown name' do
      expect(enum_class[:unknown]).to be_nil
    end
  end

  describe '.fetch' do
    it 'retrieves entry by name' do
      expect(enum_class.fetch(:draft).value).to eq(0)
    end

    it 'raises KeyError for unknown name' do
      expect {
        enum_class.fetch(:unknown)
      }.to raise_error(KeyError)
    end
  end

  describe '.name_for' do
    it 'returns the name for a registered value' do
      expect(enum_class.name_for(0)).to eq(:draft)
    end

    it 'returns nil for unregistered value' do
      expect(enum_class.name_for(999)).to be_nil
    end
  end

  describe '.all' do
    it 'returns all enum instances' do
      all = enum_class.all
      expect(all.size).to eq(3)
      expect(all.map(&:value)).to contain_exactly(0, 1, 2)
    end
  end

  describe '.keys' do
    it 'returns all registered names' do
      expect(enum_class.keys).to contain_exactly(:draft, :published, :archived)
    end
  end

  describe '.values' do
    it 'returns all raw values' do
      expect(enum_class.values).to contain_exactly(0, 1, 2)
    end
  end

  describe '.remove' do
    it 'removes an entry by name' do
      removed = enum_class.remove(:draft)
      expect(removed.value).to eq(0)
      expect(enum_class[:draft]).to be_nil
    end

    it 'removes the singleton method' do
      enum_class.remove(:draft)
      expect(enum_class).not_to respond_to(:draft)
    end

    it 'removes value from values registry' do
      enum_class.remove(:draft)
      expect(enum_class.name_for(0)).to be_nil
    end

    it 'returns nil when removing non-existent entry' do
      expect(enum_class.remove(:nonexistent)).to be_nil
    end
  end

  describe '#to_s' do
    it 'returns string representation of the name' do
      expect(enum_class.draft.to_s).to eq('draft')
    end

    context 'in non-strict mode with unregistered value' do
      it 'returns "unknown" for unregistered values' do
        instance = enum_class.new(999)
        expect(instance.to_s).to eq('unknown')
      end
    end
  end

  describe '#to_sym' do
    it 'returns symbolic name' do
      expect(enum_class.draft.to_sym).to eq(:draft)
    end

    context 'in strict mode' do
      let(:strict_enum) do
        Class.new(Enumancer::Enum) do
          type Integer, strict: true
          entry :one, 1
        end
      end

      it 'raises KeyError for unregistered value' do
        instance = strict_enum.new(999)
        expect {
          instance.to_sym
        }.to raise_error(KeyError, /Unregistered enum value/)
      end
    end

    context 'in non-strict mode' do
      it 'returns :unknown for unregistered value' do
        instance = enum_class.new(999)
        expect(instance.to_sym).to eq(:unknown)
      end
    end
  end

  describe '#inspect' do
    it 'returns debug-friendly representation' do
      inspect_str = enum_class.draft.inspect
      expect(inspect_str).to include(':draft')
      expect(inspect_str).to include(':0')
      expect(inspect_str).to start_with('#<')
      expect(inspect_str).to end_with('>')
    end
  end

  describe '#==' do
    it 'returns true for same class and value' do
      expect(enum_class.draft).to eq(enum_class[:draft])
    end

    it 'returns false for different values' do
      expect(enum_class.draft).not_to eq(enum_class.published)
    end

    it 'returns false for different classes' do
      other_enum = Class.new(Enumancer::Enum) { entry :draft, 0 }
      expect(enum_class.draft).not_to eq(other_enum.draft)
    end
  end

  describe '#eql?' do
    it 'behaves like ==' do
      expect(enum_class.draft.eql?(enum_class[:draft])).to be true
      expect(enum_class.draft.eql?(enum_class.published)).to be false
    end
  end

  describe '#hash' do
    it 'returns hash based on value' do
      expect(enum_class.draft.hash).to eq(0.hash)
    end

    it 'allows enums to be used as hash keys' do
      hash = { enum_class.draft => 'Draft Status' }
      expect(hash[enum_class[:draft]]).to eq('Draft Status')
    end
  end

  describe '#to_json' do
    it 'serializes to JSON with name and value' do
      json = enum_class.draft.to_json
      data = JSON.parse(json, symbolize_names: true)
      expect(data[:name]).to eq('draft')
      expect(data[:value]).to eq(0)
    end

    it 'handles JSON generation options' do
      json = enum_class.draft.to_json(space: ' ')
      expect(json).to be_a(String)
    end
  end

  describe '.from_json' do
    it 'deserializes from JSON by name' do
      json = '{"name":"draft","value":0}'
      entry = enum_class.from_json(json)
      expect(entry).to eq(enum_class.draft)
    end

    it 'works with symbol keys' do
      json = '{"name":"published"}'
      entry = enum_class.from_json(json)
      expect(entry).to eq(enum_class.published)
    end

    it 'returns nil for unknown name in non-strict mode' do
      json = '{"name":"unknown"}'
      expect(enum_class.from_json(json)).to be_nil
    end

    context 'in strict mode' do
      let(:strict_enum) do
        Class.new(Enumancer::Enum) do
          type String, strict: true
          entry :active, 'active'
        end
      end

      it 'raises KeyError for unknown name' do
        json = '{"name":"unknown"}'
        expect {
          strict_enum.from_json(json)
        }.to raise_error(KeyError, /Unregistered enum name/)
      end
    end

    it 'raises KeyError for missing name key' do
      json = '{"value":0}'
      expect {
        enum_class.from_json(json)
      }.to raise_error(KeyError, /Missing 'name' key/)
    end
  end

  describe 'inheritance' do
    it 'allows multiple enum subclasses' do
      enum1 = Class.new(Enumancer::Enum) { entry :a, 1 }
      enum2 = Class.new(Enumancer::Enum) { entry :a, 2 }

      expect(enum1.a.value).to eq(1)
      expect(enum2.a.value).to eq(2)
      expect(enum1.a).not_to eq(enum2.a)
    end
  end

  describe 'edge cases' do
    it 'handles nil as a value' do
      enum = Class.new(Enumancer::Enum) do
        entry :null_value, nil
      end
      expect(enum.null_value.value).to be_nil
    end

    it 'handles symbols as values' do
      enum = Class.new(Enumancer::Enum) do
        entry :sym, :symbol_value
      end
      expect(enum.sym.value).to eq(:symbol_value)
    end

    it 'handles arrays as values' do
      enum = Class.new(Enumancer::Enum) do
        entry :arr, [1, 2, 3]
      end
      expect(enum.arr.value).to eq([1, 2, 3])
    end

    it 'handles hashes as values' do
      enum = Class.new(Enumancer::Enum) do
        entry :config, { key: 'value' }
      end
      expect(enum.config.value).to eq({ key: 'value' })
    end
  end

  describe 'real-world usage' do
    let(:http_status) do
      Class.new(Enumancer::Enum) do
        type Integer, strict: true
        entry :ok, 200
        entry :created, 201
        entry :bad_request, 400
        entry :not_found, 404
        entry :server_error, 500
      end
    end

    it 'can be used for HTTP status codes' do
      expect(http_status.ok.value).to eq(200)
      expect(http_status.not_found.to_sym).to eq(:not_found)
    end

    it 'can be serialized and deserialized' do
      original = http_status.ok
      json = original.to_json
      restored = http_status.from_json(json)
      expect(restored).to eq(original)
    end

    it 'can be used in collections' do
      statuses = [http_status.ok, http_status.created]
      expect(statuses).to include(http_status.ok)
    end
  end
end