class ApplePlatformTools < Formula
  desc "Agent-first CLIs for Apple SDK lookup and Mach-O inspection"
  homepage "https://github.com/markmals/apple-platform-tools"
  url "https://github.com/markmals/apple-platform-tools.git",
      tag:      "v0.1.0",
      revision: "b78b83d6580dbab2d75f5a3e5b53f4a5f30b17ed"
  head "https://github.com/markmals/apple-platform-tools.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/apple-platform-tools-0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "bbf9394253d37e9b9f21fad094b824293ed3cfe51b98be25b0cb66230759b7b8"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "a3527c20fdb55b2c78c45b293f76d1a1112d7da827c31b2f6b85bcc11f3071de"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:     "92eef078dc2b78a6be998148d57cb844326675fa5edf2592a1fa1359f32df851"
  end

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
