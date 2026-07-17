class Vid < Formula
  desc "Convert and organize media with FFmpeg"
  homepage "https://github.com/markmals/vid"

  if OS.mac?
    depends_on "ffmpeg"
    depends_on macos: :ventura
    url "https://github.com/markmals/vid/releases/download/v0.1.0/vid-v0.1.0-macos-universal.tar.gz"
    sha256 "5249cdc32dc1ed57bd95abd102365e61c1c54d447187e66208e5fcefaa712529"
  elsif Hardware::CPU.arm?
    version "0.1.0"
    url "https://github.com/markmals/vid/releases/download/v0.1.0/vid-v0.1.0-linux-aarch64.tar.gz"
    sha256 "5b406e00a5fa7430bc4c8ea79a915b53149e936ea626894af2922a7446a6683d"
  else
    version "0.1.0"
    url "https://github.com/markmals/vid/releases/download/v0.1.0/vid-v0.1.0-linux-x86_64.tar.gz"
    sha256 "37b168bec4607862dc1cf6d18674008aab497a1fc7b9f62e834a3ca76799c8b1"
  end

  def install
    bin.install "vid"
  end

  def caveats
    return "" if OS.mac?

    <<~EOS
      vid requires ffmpeg and ffprobe on PATH. The Linux formula intentionally
      leaves FFmpeg unmanaged so it can use your codec-enabled build.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vid --version")
    assert_match "Convert and organize media with FFmpeg", shell_output("#{bin}/vid --help")
  end
end
