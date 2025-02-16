defmodule PushToS3Bucket do
  def run do
    base_url = System.argv() |> Enum.at(0)

    if File.exists?("devops_script/output.txt") do
      artifact_urls =
        File.stream!("devops_script/output.txt")
        |> Stream.map(&String.trim/1)
        |> Enum.map(&(base_url <> &1))

      push_to_s3_bucket_file = File.open!("devops_script/push_to_s3_bucket.sh", [:write])

      artifact_urls
      |> Enum.each(fn url ->
        s3_command = """
        echo #{url} >> devops_script/push_to_s3_bucket.txt
        """
        IO.write(push_to_s3_bucket_file, s3_command <> "\n")
      end)

      File.close(push_to_s3_bucket_file)
    else
      IO.puts("File devops_script/output.txt does not exist")
    end
  end
end
