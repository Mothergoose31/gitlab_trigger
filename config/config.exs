import Config


# to be updated at a later time
config :gitlab_pipeline,
  token: "your_default_token",
  ref: "main",
  release: "v1.0.0",
  artifactory_base_url: "https://example.com/artifacts",
  input_file: "path/to/artifact_list.txt",
  gitlab_project_id: 123,
  gitlab_base_url: "https://gitlab.com"


env_config = Path.join(__DIR__, "#{config_env()}.exs")
if File.exists?(env_config) do
  import_config "#{config_env()}.exs"
end
