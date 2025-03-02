defmodule HelmSync do
  @moduledoc """
  HelmSync module for syncing Helm charts to JFrog and preparing S3 pushes.
  """

  def sync_helm_charts(args \\ System.argv()) do
    case args do
      [artifact_url, artifact_repo | _] ->

        artifact_url = ensure_trailing_slash(artifact_url)
        artifact_repo = ensure_trailing_slash(artifact_repo)


        path = File.cwd!()


        File.mkdir_p!("devops_script")


        {:ok, sync_helm_chart_to_jfrog_f} = File.open("devops_script/sync_helm_chart_to_Jfrog.sh", [:write])
        {:ok, push_to_s3_bucket_f} = File.open("devops_script/push_to_s3_bucket.sh", [:write])


        process_files(path, path, artifact_url, artifact_repo, sync_helm_chart_to_jfrog_f, push_to_s3_bucket_f)


        File.close(sync_helm_chart_to_jfrog_f)
        File.close(push_to_s3_bucket_f)

      _ ->
        IO.puts("Usage: mix run helmsync.exs <artifact_url> <artifact_repo>")
        System.halt(1)
    end
  end

  defp process_files(base_path, current_path, artifact_url, artifact_repo, jfrog_file, s3_file) do

    File.ls!(current_path)
    |> Enum.each(fn item ->
      full_path = Path.join(current_path, item)

      if File.dir?(full_path) do

        process_files(base_path, full_path, artifact_url, artifact_repo, jfrog_file, s3_file)
      else

        if String.ends_with?(item, ".tgz") do

          relative_dir = Path.relative_to(current_path, base_path) |> String.downcase()
          relative_dir = if relative_dir == "", do: "", else: "#{relative_dir}/"


          curl_cmd = "curl -sw  --noproxy --insecure --silent -H \"X-JFrog-Art-Api:${ARTIFACT_TOKEN}\" " <>
                    "-X PUT 'https://#{artifact_url}artifactory/#{artifact_repo}#{relative_dir}#{item}' " <>
                    "-T '#{Path.relative_to(full_path, base_path)}'\n"
          IO.write(jfrog_file, curl_cmd)


          echo_cmd = "echo https://#{artifact_url}artifactory/#{artifact_repo}#{relative_dir}#{item} " <>
                    ">> devops_script/push_to_s3_bucket.txt\n"
          IO.write(s3_file, echo_cmd)
        end
      end
    end)
  end

  defp ensure_trailing_slash(url) do
    if String.ends_with?(url, "/"), do: url, else: url <> "/"
  end

  def run do
    sync_helm_charts()
  end
end
