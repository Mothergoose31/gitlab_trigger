defmodule CreateHelm do
  @moduledoc """
  CreateHelm module for creating helm chart.
  """

  def create_helm_packages(path \\ File.cwd!()) do

    path
    |> File.ls!()
    |> Enum.each(fn item ->
      full_path = Path.join(path, item)

      if File.dir?(full_path) do
        create_helm_packages(full_path)
      else
        if String.contains?(item, "Chart") do
          System.cmd("helm", ["package", "."], cd: full_path)
        end
      end
    end)
  end

  def run do
    create_helm_packages()
    Process.sleep(10_000)
  end
end
CreateHelm.run()
