defmodule GitlabPipelineTest do
  use ExUnit.Case
  alias GitlabTrigger

  describe "read_artifact_urls/2" do
    test "reads file and prepends base URL to each artifact" do
      base_url = "https://example.com/artifacts"


      fixture_file = "test_artifacts.txt"
      File.write!(fixture_file, "artifact1.txt\n artifact2.txt\nartifact3.txt")

      on_exit(fn ->
        File.rm(fixture_file)
      end)

      {:ok, urls} = GitlabTrigger.read_artifact_urls(fixture_file, base_url)

      expected = [
        Path.join(base_url, "artifact1.txt"),
        Path.join(base_url, "artifact2.txt"),
        Path.join(base_url, "artifact3.txt")
      ]

      assert urls == expected
    end

    test "returns error when file does not exist" do
      non_existent_file = "non_existent_file.txt"
      {:error, reason} = GitlabTrigger.read_artifact_urls(non_existent_file, "https://example.com/")
      assert reason == :enoent
    end
  end

  describe "construct_gitlab_trigger_curl/1" do
    test "constructs a valid curl command" do
      opts = %{
        token: "mysecret",
        ref: "main",
        release: "v1.0.0",
        artifact_urls: [
          "https://example.com/artifacts/artifact1.txt",
          "https://example.com/artifacts/artifact2.txt"
        ],
        gitlab_project_id: 123,
        gitlab_base_url: "https://gitlab.com"
      }

      curl_command = GitlabTrigger.construct_gitlab_trigger_curl(opts)


      assert curl_command =~ "curl -X POST"
      assert curl_command =~ "-F token=mysecret"
      assert curl_command =~ "-F \"ref=main\""
      assert curl_command =~ "-F \"variables[RELEASE]=v1.0.0\""
      assert curl_command =~ "-F \"variables[ARTIFACT_LIST]=https://example.com/artifacts/artifact1.txt,https://example.com/artifacts/artifact2.txt\""
      assert curl_command =~ "/api/projects/123/trigger/pipeline"
      assert curl_command =~ "https://gitlab.com"
    end
  end

  describe "execute/1" do
    test "executes pipeline trigger process successfully" do

      input_file = "test_artifact_list.txt"
      File.write!(input_file, "artifactA.txt\nartifactB.txt")

      on_exit(fn ->
        File.rm(input_file)
      end)

      opts = [
        token: "secret",
        ref: "develop",
        release: "v2.0.0",
        artifactory_base_url: "https://example.org",
        input_file: input_file,
        gitlab_project_id: "456",
        gitlab_base_url: "https://gitlab.example.org"
      ]

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          result = GitlabPipeline.execute(opts)
          assert result == :ok
        end)
      assert output =~ "curl -X POST"
      assert output =~ "-F token=secret"
      assert output =~ "-F \"ref=develop\""
      assert output =~ "/api/projects/456/trigger/pipeline"
    end

    test "returns configuration error when missing required configuration" do
      opts = [

        ref: "develop",
        release: "v2.0.0",
        artifactory_base_url: "https://example.org",
        input_file: "non_existent_file.txt",
        gitlab_project_id: "456",
        gitlab_base_url: "https://gitlab.example.org"
      ]

      {:error, error_message} = GitlabTrigger.execute(opts)
      assert error_message =~ "Missing configuration: token"
    end
  end
end
