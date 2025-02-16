defmodule GitlabPipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :gitlab_pipeline,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      devops_script: &push_to_s3_bucket/1
    ]
  end

  defp push_to_s3_bucket(_args) do
    Mix.Task.run("app.start")
    PushToS3Bucket.run()
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end


  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mox, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
