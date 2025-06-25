import Config

# Configure the main application
config :swiex,
  swipl_path: System.get_env("SWIPL_PATH", "swipl"),
  mqi_timeout: 5000,
  enable_hot_reload: true,
  # MQI Configuration - connect to existing server instead of starting our own
  start_mqi_server: false,
  mqi_port: 12347,
  mqi_password: "test"

# Configure logger
config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n"

# Development configuration
if config_env() == :dev do
  config :logger, level: :debug
  
  # Enable hot-code reloading for Prolog files
  config :swiex, enable_hot_reload: true
end

# Test configuration
if config_env() == :test do
  config :logger, level: :warn
  
  # Disable hot-reload in tests
  config :swiex, enable_hot_reload: false
end

# Production configuration
if config_env() == :prod do
  config :logger, level: :info
  
  # Disable hot-reload in production
  config :swiex, enable_hot_reload: false
end 