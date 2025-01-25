import Config

config :resdayn, Resdayn.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "resdayn_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
