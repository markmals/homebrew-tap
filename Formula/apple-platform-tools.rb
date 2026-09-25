class ApplePlatformTools < Formula
  desc "Agent-first CLIs for Apple SDK, Mach-O, and live UI inspection"
  homepage "https://github.com/markmals/apple-platform-tools"
  url "https://github.com/markmals/apple-platform-tools.git",
      tag:      "v0.1.0",
      revision: "b78b83d6580dbab2d75f5a3e5b53f4a5f30b17ed"
  head "https://github.com/markmals/apple-platform-tools.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/apple-platform-tools-0.1.0"
    rebuild 1
    sha256 cellar: :any, arm64_golden_gate: "830a14b03dd048fee68876534adac2325f65dd10cd32ac7268d566d0376d2f0e"
    sha256 cellar: :any, arm64_tahoe:       "1ae3d9e6ffe2c841a39c6efedb686bfd69f6f2027d730082c5b41bcd7044134c"
    sha256 cellar: :any, arm64_sequoia:     "a85c79d3d4749e17b1881b4c655f268beec0d3f1f6ed4cb4f0d21b6e744ff73d"
  end

  depends_on xcode: ["26.0", :build]
  depends_on macos: :sequoia

  def install
    tools = %w[sdk-api sdk-search headerdump redump uitool]
    # `swift build` emits only the last of several --product flags, so build one at a time.
    (tools + ["UIToolBoot"]).each do |product|
      system "swift", "build", "--disable-sandbox", "--configuration", "release", "--product", product
    end

    # Swift 6.3 and older resolve resource bundles next to the invoked path, not the
    # resolved binary, so bin/ holds exec scripts into libexec/ rather than symlinks.
    libexec.install tools.map { |tool| ".build/release/#{tool}" }, Dir[".build/release/*.bundle"]
    # uitool injects this dylib and resolves it next to its own binary (so, libexec/).
    libexec.install ".build/release/libUIToolBoot.dylib"

    # `uitool attach` takes a get-task-allow target's task port, which needs the debugger
    # entitlement — the cooperative posture (your own dev-signed apps, no machine defang).
    system "codesign", "--force", "--sign", "-",
           "--entitlements", buildpath/"scripts/uitool-debugger.entitlements", libexec/"uitool"

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

    doctor = JSON.parse(shell_output("#{bin}/uitool doctor"))
    # Cooperative injection is impossible unless the arm64 boot dylib sits next to the binary.
    assert_equal true, doctor.dig("cooperative", "usable")
  end
end
