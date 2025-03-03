import Config

# Configuration sourced from environment variables with fallbacks
config :gitlab_pipeline,
  token: System.get_env("GITLAB_TOKEN"),
  ref: System.get_env("GITLAB_REF"),
  release: System.get_env("GITLAB_RELEASE"),
  artifactory_base_url: System.get_env("ARTIFACTORY_BASE_URL"),
  input_file: System.get_env("INPUT_FILE"),
  gitlab_project_id: String.to_integer(System.get_env("GITLAB_PROJECT_ID", "123")),
  gitlab_base_url: System.get_env("GITLAB_BASE_URL")

env_config = Path.join(__DIR__, "#{config_env()}.exs")
if File.exists?(env_config) do
  import_config "#{config_env()}.exs"
end
