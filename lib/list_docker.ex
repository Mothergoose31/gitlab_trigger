defmodule ListDocker do
  @moduledoc """
  ListDocker module for generating a GitLab pipeline trigger curl command
  based on Docker images listed in a file.
  """

  @doc """
  Processes a docker image list file and generates a GitLab pipeline trigger command.

  Configuration is read from environment variables, then falls back to defaults:
  * `GITLAB_TOKEN` - GitLab API token
  * `GITLAB_REF` - Git reference/branch to trigger
  * `GITLAB_RELEASE` - Release name for the RELEASE variable
  * `GITLAB_PROJECT_ID` - GitLab project ID
  * `GITLAB_URL` - GitLab instance URL
  * `DOCKER_FILTER` - Filter term for Docker images

  All configuration can be overridden with options passed to the function.
  """
  def run(input_file \\ "docker_it.txt", options \\ []) do
    # Read configuration from environment variables with defaults
    default_options = [
      token: System.get_env("GITLAB_TOKEN"),
      ref: System.get_env("GITLAB_REF"),
      release: System.get_env("GITLAB_RELEASE"),
      project_id: System.get_env("GITLAB_PROJECT_ID"),
      gitlab_url: System.get_env("GITLAB_URL"),
      filter: System.get_env("DOCKER_FILTER"),
      print: true
    ]

    # Override defaults with any options passed to the function
    options = Keyword.merge(default_options, options)

    docker_urls =
      File.read!(input_file)
      |> String.replace("[", "")
      |> String.replace("]", "")
      |> String.replace("name:", "\n")
      |> String.replace(",", "")
      |> String.replace("sha256:", "\n")
      |> String.split(" tag")
      |> Enum.join("")
      |> String.split("\n")
      |> Enum.filter(fn image ->
        String.contains?(image, options[:filter])
      end)
      |> Enum.map(&String.replace(&1, " ", ""))

    docker_final_url_list = Enum.join(docker_urls, ",")

    curl_cmd_string = """
    curl -X POST \\
         -F token=#{options[:token]} \\
         -F "ref=#{options[:ref]}" \\
         -F "variables[RELEASE]=#{options[:release]}" \\
         -F "variables[ARTIFACT_LIST]=#{docker_final_url_list}" \\
         #{options[:gitlab_url]}/api/v4/projects/#{options[:project_id]}/trigger/pipeline
    """

    if options[:print], do: IO.puts(curl_cmd_string)


    curl_cmd_string
  end

  def main(args \\ []) do
    {options, remaining_args, _} = OptionParser.parse(args,
      strict: [
        input: :string,
        token: :string,
        ref: :string,
        release: :string,
        project_id: :string,
        gitlab_url: :string,
        filter: :string
      ]
    )

    input_file = options[:input] || List.first(remaining_args) || "docker_it.txt"


    options = Keyword.delete(options, :input)

    run(input_file, options)
  end
end
