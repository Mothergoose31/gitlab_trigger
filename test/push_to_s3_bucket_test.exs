defmodule PushToS3BucketTest do
  import ExUnit.CaptureIO
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  defmodule FileMock do
    def exists?(_path), do: true
    def stream!(_path), do: Stream.map(["file1.txt", "file2.txt"], & &1)
    def open!(_path, _modes), do: :mock_file
    def write(_file, content), do: send(self(), {:mock_file, :write, content})
    def close(_file), do: :ok
  end

  test "run/0 generates the correct S3 commands" do
    Application.put_env(:your_app, :file_module, FileMock)

    expect(FileMock, :exists?, fn _path -> true end)
    expect(FileMock, :stream!, fn _path -> Stream.map(["file1.txt", "file2.txt"], & &1) end)
    expect(FileMock, :open!, fn _path, _modes -> :mock_file end)
    expect(FileMock, :write, fn _file, content -> assert content =~ "echo http://base_url/file1.txt" end)
    expect(FileMock, :close, fn _file -> :ok end)

    System.argv() |> Enum.at(0) |> PushToS3Bucket.run()

    assert_received {:mock_file, :write, _}
  end

  test "run/0 handles missing output.txt file" do
    Application.put_env(:your_app, :file_module, FileMock)

    expect(FileMock, :exists?, fn _path -> false end)

    assert capture_io(fn ->
      PushToS3Bucket.run()
    end) =~ "File devops_script/output.txt does not exist"
  end
end
