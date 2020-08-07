# frozen_string_literal: true

require 'json'

RSpec.describe 'Base validation' do
  it 'fails if required property is missing' do
    config = <<-JSON
    {
      "version": "7.9"
    }
    JSON

    schema = <<-JSON
    {
      "required": ["name"],
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(['Required property `name` is missing'])
  end

  it 'fails if additional properties are disabled in schema but still provided' do
    config = <<-JSON
    {
      "version": "7.9"
    }
    JSON

    schema = <<-JSON
    {
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(['Property `version` is not supported'])
  end

  it 'fails if string property is provided as other type' do
    config = <<-JSON
    {
      "name": true
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(['Property `name` must be of type `string` (provided value `true` of type `boolean`)'])
  end

  it 'fails if with multiple errors' do
    config = <<-JSON
    {
      "name": true
    }
    JSON

    schema = <<-JSON
    {
      "required": ["version"],
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(['Required property `version` is missing', 'Property `name` must be of type `string` (provided value `true` of type `boolean`)'])
  end

  it 'passes if config follows schema' do
    config = <<-JSON
    {
      "name": "ucfg"
    }
    JSON

    schema = <<-JSON
    {
      "required": ["name"],
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(true)
    expect(result.errors).to eq([])
  end
end
