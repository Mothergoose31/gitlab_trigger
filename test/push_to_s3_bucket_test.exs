defmodule PushToS3BucketTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    tmp_dir = "test/tmp"
    File.mkdir_p!(tmp_dir)


    on_exit(fn ->
      File.rm_rf!(tmp_dir)

      Application.delete_env(:gitlab_pipeline, :base_url)
      Application.delete_env(:gitlab_pipeline, :output_file)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "Print concatenated urls when the file exists", %{tmp_dir: tmp_dir} do
    file_path = Path.join(tmp_dir, "output.txt")
    File.write!(file_path, "file1.txt\nfile2.txt\nfile3.txt")

    Application.put_env(:gitlab_pipeline, :base_url, "http://example.com/")
    Application.put_env(:gitlab_pipeline, :output_file, file_path)

    captured = capture_io(fn ->
      PushToS3Bucket.run()
    end)

    expected = "http://example.com/file1.txt\nhttp://example.com/file2.txt\nhttp://example.com/file3.txt\n"
    assert captured == expected
  end
end
