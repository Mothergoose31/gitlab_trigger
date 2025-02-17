defmodule PushToS3Bucket do
  @moduledoc """
  PushToS3Bucket module for pushing artifacts to S3 bucket.

  This module is used to push artifacts to S3 bucket.
  it takes in the base url which is the url you want to push to,
  and the output file which is the file that contains the artifacts to push to S3 bucket.

  at some point will be done in conjuction with xargs something
  like
  mix run push_to_s3_bucket.exs -- --base_url --output_file |
  xargs -I {} ... ect
  """

  @spec run() :: :ok
  def run do
    base_url = Application.get_env(:gitlab_pipeline, :base_url, System.argv() |> Enum.at(0))
    output_file = Application.get_env(:gitlab_pipeline, :output_file, System.argv() |> Enum.at(1))

    if File.exists?(output_file) do
      artifact_urls =
        File.stream!(output_file)
        |> Stream.map(&String.trim/1)
        |> Enum.map(&(base_url <> &1))

      artifact_urls
      |> Enum.each(&IO.puts/1)
    else
      IO.puts("File #{output_file} does not exist")
    end
  end
end
