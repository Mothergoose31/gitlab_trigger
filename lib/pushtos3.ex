defmodule PushToS3Bucket do
  def run do
    base_url = Application.get_env(:gitlab_pipeline, :base_url, System.argv() |> Enum.at(0))
    output_file = Application.get_env(:gitlab_pipeline, :output_file, "devops_script/output.txt")

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
