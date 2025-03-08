defmodule DeployPipeline do
  @moduledoc """
  DeployPipeline orchestrates the complete deployment workflow.

  This module combines the functionality of other modules to provide a
  streamlined workflow:
  1. Create Helm charts (from CreateHelm)
  2. Sync Helm charts to JFrog (from HelmSync)
  3. Create S3 bucket push commands (from HelmSync)
  4. Execute S3 pushes (from PushToS3Bucket)
  5. Trigger GitLab pipeline if needed (from ListDocker)

  Usage:
  ```
  # Run the entire pipeline
  mix run -e 'DeployPipeline.run()'

  # Run a specific step
  mix run -e 'DeployPipeline.run(:create_helm)'
  ```
  """

  @doc """
  Runs the complete deployment pipeline or a specific step.

  ## Options
  * `step` - Optional atom specifying which step to run:
    * `:create_helm` - Only create Helm charts
    * `:sync_helm` - Only sync Helm charts to JFrog
    * `:s3_push` - Only push artifacts to S3
    * `:trigger_pipeline` - Only trigger GitLab pipeline
    * If not specified, runs all steps in sequence
  """
  def run(step \\ :all) do
    IO.puts("Starting deployment pipeline...")

    case step do
      :create_helm ->
        create_helm_charts()

      :sync_helm ->
        sync_helm_charts()

      :s3_push ->
        push_to_s3()

      :trigger_pipeline ->
        trigger_gitlab_pipeline()

      :all ->
        create_helm_charts()
        sync_helm_charts()
        push_to_s3()
        trigger_gitlab_pipeline()

        IO.puts("Deployment pipeline completed successfully!")
    end
  end

  defp create_helm_charts do
    IO.puts("Creating Helm charts...")
    CreateHelm.create_helm_packages()
  end

  defp sync_helm_charts do
    IO.puts("Syncing Helm charts to JFrog...")

    artifact_url = Application.get_env(:gitlab_pipeline, :artifactory_base_url)
    artifact_repo = Application.get_env(:gitlab_pipeline, :helm_repo, "helm-local")

    if is_nil(artifact_url) do
      IO.puts("Error: ARTIFACTORY_BASE_URL not configured")
      System.halt(1)
    end

    HelmSync.sync_helm_charts([artifact_url, artifact_repo])
  end

  defp push_to_s3 do
    IO.puts("Pushing artifacts to S3...")

    base_url = Application.get_env(:gitlab_pipeline, :base_url)
    output_file = "devops_script/push_to_s3_bucket.txt"

    Application.put_env(:gitlab_pipeline, :base_url, base_url)
    Application.put_env(:gitlab_pipeline, :output_file, output_file)

    PushToS3Bucket.run()
  end

  defp trigger_gitlab_pipeline do
    IO.puts("Triggering GitLab pipeline...")

    input_file = Application.get_env(:gitlab_pipeline, :input_file, "docker_it.txt")

    if File.exists?(input_file) do
      ListDocker.run(input_file)
    else
      IO.puts("Skipping GitLab pipeline trigger: #{input_file} not found")
    end
  end
end
