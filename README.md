# ucfg

Load YAML config, merge overrides, expand environment variables, and validate
the result before your application boots.

`ucfg` is a Ruby take on
[elastic/go-ucfg](https://github.com/elastic/go-ucfg).

## Typical Use

Most apps need some version of this:

- `config.yml` for defaults
- `config/development.yml` or `config/production.yml` for overrides
- environment variables for secrets and deploy-time values
- a schema for required keys and expected types

Load and validate config at boot:

```ruby
config = Ucfg.load(
  "config/app.yml",
  "config/#{ENV.fetch('APP_ENV', 'development')}.yml",
  schema: "config/schema.yml",
  env: true,
)

App.start(config)
```

Invalid config fails before `App.start`, with errors tied to config properties.

## Installation

`ucfg` requires Ruby 3.1 or newer.

Add `ucfg` to your Gemfile:

```ruby
gem "ucfg"
```

Then run:

```sh
bundle install
```

## A Complete Example

Start with a base config:

```yaml
# config/app.yml
service:
  name: billing-api
  host: 0.0.0.0
  port: 3000

database:
  url: ${DATABASE_URL}
  pool: ${DATABASE_POOL:5}

features:
  invoices: true
```

Add an environment override:

```yaml
# config/production.yml
service:
  port: ${PORT:8080}

database:
  pool: 20
```

Describe what valid config looks like:

```yaml
# config/schema.yml
type: object
required:
  - service
  - database
properties:
  service:
    type: object
    required:
      - name
      - host
      - port
    properties:
      name:
        type: string
        minLength: 1
      host:
        type: string
      port:
        type: integer
        minimum: 1
        maximum: 65535
  database:
    type: object
    required:
      - url
      - pool
    properties:
      url:
        type: string
        minLength: 1
      pool:
        type: integer
        minimum: 1
  features:
    type: object
    additionalProperties:
      type: boolean
```

Load and validate it:

```ruby
config = Ucfg.load(
  "config/app.yml",
  "config/production.yml",
  schema: "config/schema.yml",
  env: true,
)

config.fetch("service").fetch("port")
# => 8080
```

Semantics:

- later files override earlier files
- nested objects are merged
- arrays and scalar values are replaced
- `${NAME}` reads from the environment
- `${NAME:default}` uses a default when the environment variable is missing or empty
- `$$` escapes to a literal `$`
- `env_parsers: { "NAME" => :csv }` parses a whole environment value as a
  comma-separated list
- schema errors are reported before the loaded config is returned

## Loading API

Use `Ucfg.load` when invalid config should stop boot:

```ruby
config = Ucfg.load(
  "config/app.yml",
  "config/production.yml",
  schema: "config/schema.yml",
  env: true,
)
```

`Ucfg.load!` is an alias for `Ucfg.load`.

Use `Ucfg.load_result` when you want to handle errors yourself:

```ruby
result = Ucfg.load_result(
  "config/app.yml",
  "config/production.yml",
  schema: "config/schema.yml",
  env: true,
)

if result.valid?
  App.start(result.config)
else
  warn result.errors.join("\n")
  exit 1
end
```

`result.errors` returns human-readable strings. `result.error_details` returns
structured error objects:

```ruby
result.error_details.first.to_h
# => {
#      :message => "Property `service.port` must be of type `integer` ...",
#      :path => ["service", "port"],
#      :keyword => "type",
#      :type => :validation,
#    }
```

Error `type` is `:validation` for config validation errors, `:schema` for
invalid schema shapes, and `:load` for file loading or parsing errors.

`schema:` accepts:

- `nil` for no validation
- a schema `Hash`
- a string or path-like object pointing to a schema file

Raw YAML schema strings are not accepted as `schema:` values. Use
`Ucfg.load_yaml` first if you already have the schema source in memory.

`env_parsers:` can be used with `Ucfg.load`, `Ucfg.load_result`,
`Ucfg.load_file`, and `Ucfg.load_yaml`.

## Lower-Level APIs

You can load and validate YAML strings directly:

```ruby
schema = {
  "type" => "object",
  "required" => ["service"],
  "properties" => {
    "service" => {
      "type" => "object",
      "required" => ["name"],
      "properties" => {
        "name" => { "type" => "string" },
      },
    },
  },
}

result = Ucfg.validate_yaml(<<~YAML, schema)
  service:
    name: billing-api
YAML

result.valid?
# => true
```

Or compose the lower-level pieces manually:

```ruby
base = Ucfg.load_file("config/app.yml", env: true)
override = Ucfg.load_file("config/production.yml", env: true)
config = Ucfg::ConfigMerger.merge(base, override)

schema = Ucfg.load_file("config/schema.yml")
result = Ucfg.validate(config, schema)

unless result.valid?
  abort result.errors.join("\n")
end
```

## Environment Expansion

Environment expansion is opt-in:

```yaml
host: ${HOST:localhost}
port: ${PORT:3000}
debug: ${DEBUG:false}
hosts: ${HOSTS:localhost}
```

When a whole YAML value is an environment expression, `ucfg` preserves useful
types:

```ruby
ENV["PORT"] = "3000"
ENV["DEBUG"] = "false"
ENV["HOSTS"] = "api-1,api-2"

Ucfg.load_yaml("port: ${PORT}\ndebug: ${DEBUG}\nhosts: ${HOSTS}\n", env: true)
# => {
#      "port" => 3000,
#      "debug" => false,
#      "hosts" => "api-1,api-2",
#    }
```

Comma-separated values are strings by default. Use `env_parsers` when a specific
environment variable should be parsed as a list:

```ruby
ENV["HOSTS"] = "api-1,api-2"

Ucfg.load_yaml(
  "hosts: ${HOSTS}\n",
  env: true,
  env_parsers: { "HOSTS" => :csv },
)
# => { "hosts" => ["api-1", "api-2"] }
```

Embedded environment expressions are rendered as strings:

```yaml
url: postgres://${DATABASE_HOST:localhost}:5432/app
```

Write `$$` for a literal `$`, including when a value should keep a `${...}`
sequence instead of expanding it:

```yaml
price: $$5
literal: $${NOT_EXPANDED}
```

```ruby
# => { "price" => "$5", "literal" => "${NOT_EXPANDED}" }
```

A `$` that is not part of `$$` or `${` is left alone, so `a$b` needs no
escaping.

## ERB Templates

ERB rendering is also opt-in:

```ruby
config = Ucfg.load_file("config/app.yml", erb: true)
```

Use ERB only for trusted configuration files. ERB executes Ruby code while the
config is being loaded.

Environment expansion and ERB rendering are intentionally separate modes. Prefer
`${NAME}` expansion for secrets and deployment values, and reserve ERB for cases
that truly need Ruby logic.

## Supported Schema Keywords

`ucfg` implements a practical subset of JSON Schema for configuration files:

- `type`
- `required`
- `properties`
- `additionalProperties`
- `patternProperties`
- `items`
- `enum`
- `const`
- `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`
- legacy `min` and `max`
- `minLength`, `maxLength`, `pattern`
- `minItems`, `maxItems`, `uniqueItems`
- `anyOf`, `oneOf`, `allOf`

## Unsupported Schema Keywords

`ucfg` is not a full JSON Schema implementation. These commonly used JSON Schema
features are not currently supported:

- `$schema`, `$id`, `$ref`, `$defs`, and `definitions`
- `default`, `title`, `description`, `examples`, `deprecated`, and `readOnly`
- `format`
- `multipleOf`
- `not`
- `if`, `then`, and `else`
- `dependentRequired`, `dependentSchemas`, and legacy `dependencies`
- `propertyNames`
- `minProperties` and `maxProperties`
- tuple-style `items`, `prefixItems`, `contains`, `minContains`, and `maxContains`
- `unevaluatedProperties` and `unevaluatedItems`
- `patternRequired`
- `contentEncoding`, `contentMediaType`, and `contentSchema`

Unsupported keywords are ignored unless `ucfg` has explicit schema-shape checks
for that keyword. Keep schemas small and focused on the supported validation
rules above.

## YAML Rules

`ucfg` accepts a restricted YAML shape:

- one YAML document per file
- no anchors or aliases
- no merge keys
- no explicit tags
- no block scalars
- no flow-style objects or arrays

Dotted keys are expanded into nested objects:

```yaml
service.name: billing-api
service.port: 3000
```

is equivalent to:

```yaml
service:
  name: billing-api
  port: 3000
```

Every segment of a dotted key must be non-empty, so `.name`, `service..name`,
and `service.` are all rejected.

## Roadmap

Before a stable v1, add a small CLI for checking config in CI, for example:

```sh
ucfg check config/app.yml --schema config/schema.yml
```

## Development

After checking out the repository, install dependencies, then run the test suite
and style checks:

```sh
bin/setup
bundle exec rake
```

To experiment locally:

```sh
bin/console
```

Bug reports and pull requests are welcome at
https://github.com/orhantoy/ucfg.
