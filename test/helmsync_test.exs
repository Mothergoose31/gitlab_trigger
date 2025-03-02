defmodule HelmSyncTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    tmp_dir = "test/tmp_helmsync"
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)


    chart_dir = Path.join(tmp_dir, "chart1")
    File.mkdir_p!(chart_dir)
    File.write!(Path.join(chart_dir, "mychart-1.0.0.tgz"), "dummy tgz content")

    nested_dir = Path.join([tmp_dir, "nested", "charts"])
    File.mkdir_p!(nested_dir)
    File.write!(Path.join(nested_dir, "nested-chart-2.0.0.tgz"), "nested tgz content")

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
      File.rm_rf!("devops_script")
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "generates correct sync and push scripts", %{tmp_dir: tmp_dir} do

    original_dir = File.cwd!()
    File.cd!(tmp_dir)

    # Run with test arguments
    HelmSync.sync_helm_charts(["example.com", "helm-repo"])


    jfrog_script = File.read!("devops_script/sync_helm_chart_to_Jfrog.sh")
    s3_script = File.read!("devops_script/push_to_s3_bucket.sh")

    assert jfrog_script =~ "curl -sw  --noproxy --insecure --silent"
    assert jfrog_script =~ "https://example.com/artifactory/helm-repo/"
    assert jfrog_script =~ "mychart-1.0.0.tgz"
    assert jfrog_script =~ "nested-chart-2.0.0.tgz"

    assert s3_script =~ "echo https://example.com/artifactory/helm-repo/"
    assert s3_script =~ "mychart-1.0.0.tgz"
    assert s3_script =~ "nested-chart-2.0.0.tgz"

    File.cd!(original_dir)
  end
end
