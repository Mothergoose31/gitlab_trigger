import Config

config :gitlab_trigger,
  input_file: "devops_script/output.txt"

import_config "#{config_env()}.exs"
