# frozen_string_literal: true

# Sets an environment variable for the duration of the block and restores the
# previous state afterwards. Assigning nil to ENV deletes the entry, so this
# handles both setting and unsetting a variable.
module EnvHelper
  def with_env(key, value)
    original = ENV.fetch(key, nil)
    ENV[key] = value

    yield
  ensure
    ENV[key] = original
  end
end
