require "json"

RSpec.describe "Nested validation" do
  it "fails if required property is missing" do
    config = <<-JSON
    {
      "devotus": {
        "version": "7.9"
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "devotus": {
          "required": ["name"],
          "properties": {
            "name": {
              "type": "string"
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Required property `devotus.name` is missing"])
  end

  xit "fails if additional properties are disabled in schema but still provided" do
    config = <<-JSON
    {
      "devotus": {
        "version": "7.9"
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "devotus": {
          "additionalProperties": false,
          "properties": {
            "name": {
              "type": "string"
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `devotus.version` is not supported"])
  end

  xit "fails if with multiple errors" do
    config = <<-JSON
    {
      "devotus": {
        "name": true
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "devotus": {
          "required": ["version"],
          "properties": {
            "name": {
              "type": "string"
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Required property `devotus.version` is missing", "Property `devotus.name` must be of type `string` (provided value `true` of type `boolean`)"])
  end

  xit "can also validate 3 levels of nesting" do
    config = <<-JSON
    {
      "level1": {
        "level2": {
          "level3": {
            "name": "ucfg"
          }
        }
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "level1": {
          "properties": {
            "level2": {
              "properties": {
                "level3": {
                  "required": ["name"],
                  "properties": {
                    "name": {
                      "type": "boolean"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `level1.level2.level3.name` must be of type `boolean` (provided value `ucfg` of type `string`)"])
  end

  xit "can also validate 4 levels of nesting and pass" do
    config = <<-JSON
    {
      "level1": {
        "level2": {
          "level3": {
            "level4": {
              "name": "ucfg"
            }
          }
        }
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "level1": {
          "properties": {
            "level2": {
              "properties": {
                "level3": {
                  "properties": {
                    "level4": {
                      "required": ["name"],
                      "properties": {
                        "name": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(true)
    expect(result.errors).to eq([])
  end
end
