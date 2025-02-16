defmodule GitlabTrigger do
  @moduledoc """
  Module for triggering GitLab pipelines with artifact URLs.
  """

  @type config :: %{
    token: String.t(),
    ref: String.t(),
    release: String.t(),
    artifactory_base_url: String.t(),
    input_file: String.t(),
    gitlab_project_id: integer(),
    gitlab_base_url: String.t()
  }

  @type curl_opts :: %{
    token: String.t(),
    ref: String.t(),
    release: String.t(),
    artifact_urls: list(String.t()),
    gitlab_project_id: integer(),
    gitlab_base_url: String.t()
  }

  @doc """
  Reads artifact URLs from a file and prepends the base URL.
  Returns {:ok, urls} on success or {:error, reason} on failure.
  """
  @spec read_artifact_urls(String.t(), String.t()) :: {:ok, list(String.t())} | {:error, term()}
  def read_artifact_urls(input_file, base_url) do
    try do
      urls =
        input_file
        |> File.stream!()
        |> Stream.map(&String.trim/1)
        |> Stream.map(&(Path.join(base_url, &1)))
        |> Enum.to_list()

      {:ok, urls}
    rescue
      e in File.Error -> {:error, e.reason}
    end
  end

  @doc """
  Constructs the curl command for triggering GitLab pipeline.
  """
  @spec construct_gitlab_trigger_curl(curl_opts()) :: String.t()
  def construct_gitlab_trigger_curl(opts) do
    %{
      token: token,
      ref: ref,
      release: release,
      artifact_urls: artifact_urls,
      gitlab_project_id: gitlab_project_id,
      gitlab_base_url: gitlab_base_url
    } = opts

    artifacts_list = Enum.join(artifact_urls, ",")

    """
    curl -X POST \\
    -F token=#{token} \\
    -F "ref=#{ref}" \\
    -F "variables[RELEASE]=#{release}" \\
    -F "variables[ARTIFACT_LIST]=#{artifacts_list}" \\
    #{gitlab_base_url}/api/projects/#{gitlab_project_id}/trigger/pipeline
    """
  end

  @doc """
  Main function to execute the pipeline trigger process.
  """
  @spec execute(Keyword.t()) :: :ok | {:error, term()}
  def execute(opts \\ []) do
    with {:ok, config} <- load_config(opts),
         {:ok, artifact_urls} <- read_artifact_urls(config.input_file, config.artifactory_base_url) do
      
      curl_command = construct_gitlab_trigger_curl(%{
        token: config.token,
        ref: config.ref,
        release: config.release,
        artifact_urls: artifact_urls,
        gitlab_project_id: config.gitlab_project_id,
        gitlab_base_url: config.gitlab_base_url
      })

      IO.puts(curl_command)
      :ok
    end
  end

  @spec load_config(Keyword.t()) :: {:ok, config()} | {:error, String.t()}
  defp load_config(opts) do
    try do
      config = %{
        token: get_config(:token, opts),
        ref: get_config(:ref, opts),
        release: get_config(:release, opts),
        artifactory_base_url: get_config(:artifactory_base_url, opts),
        input_file: get_config(:input_file, opts),
        gitlab_project_id: get_config(:gitlab_project_id, opts) |> String.to_integer(),
        gitlab_base_url: get_config(:gitlab_base_url, opts)
      }
      {:ok, config}
    rescue
      e in ArgumentError -> {:error, "Configuration error: #{Exception.message(e)}"}
    end
  end

  defp get_config(key, opts) do
    opts[key] || 
      System.get_env(key |> to_string |> String.upcase()) ||
      Application.get_env(:gitlab_trigger, key) ||
      raise ArgumentError, "Missing configuration: #{key}"
  end
end