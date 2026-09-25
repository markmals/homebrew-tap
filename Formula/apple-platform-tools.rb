class ApplePlatformTools < Formula
  desc "Agent-first CLIs for Apple SDK lookup and Mach-O inspection"
  homepage "https://github.com/markmals/apple-platform-tools"
  url "https://github.com/markmals/apple-platform-tools.git",
      revision: "b78b83d6580dbab2d75f5a3e5b53f4a5f30b17ed"
  version "0.1.0"
  head "https://github.com/markmals/apple-platform-tools.git", branch: "main"

  depends_on xcode: ["26.0", :build]
  depends_on macos: :sequoia

  def install
    # uitool and its injection dylib are dev-machine only upstream; never ship them.
    tools = %w[sdk-api sdk-search headerdump redump]
    # `swift build` builds only the last of several --product flags.
    tools.each do |tool|
      system "swift", "build", "--disable-sandbox", "--configuration", "release", "--product", tool
    end

    # Swift 6.3 and older look for resource bundles next to the invoked path, not the
    # resolved binary, so bin/ gets exec scripts rather than symlinks into libexec/.
    libexec.install tools.map { |tool| ".build/release/#{tool}" }, Dir[".build/release/*.bundle"]
    bin.write_exec_script tools.map { |tool| libexec/tool }
  end

  test do
    # sdk-search traps if it can't find its corpus bundle.
    corpus = JSON.parse(shell_output("#{bin}/sdk-search list"))
    refute_empty corpus["categories"]

    info = JSON.parse(shell_output("#{bin}/redump info #{libexec}/redump"))
    assert_equal [Hardware::CPU.arch.to_s], info["archs"]
    assert_equal "execute", info["fileType"]

    system bin/"headerdump", "-c", "-j", "NSObject", "/usr/lib/libobjc.A.dylib", "-o", testpath
    refute_empty testpath.glob("NSObject~*.h")

    assert_match "Query macOS SDK API existence", shell_output("#{bin}/sdk-api --help")
  end
end
