class Recon < Formula
  desc "Inspect applications without activating them"
  homepage "https://github.com/markmals/recon"
  url "https://github.com/markmals/recon.git",
      tag:      "v0.2.0",
      revision: "34d63ac7adf418731736dc18a1617bf9fe76c2e6"
  license "MIT"
  head "https://github.com/markmals/recon.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/recon-0.2.0"
    sha256 cellar: :any, arm64_golden_gate: "df2d2cff111f8a14e4e559d6b426853fe742e70da0c6f3ce17b885953c3f28c6"
  end

  depends_on "node" => :build
  depends_on "rust" => :build
  depends_on arch: :arm64
  # Recon builds only with Apple's Swift build swiftlang-6.4.2.1.9, from Xcode 27.2 or the
  # Command Line Tools that ship with it, and its build fails naming any other compiler it
  # finds. That compiler runs on macOS 26.6 and later, but no macOS 26 CI image has it, so
  # tests.yml builds the macOS 26 bottle on xcode-27.
  depends_on macos: :tahoe

  def install
    system "cargo", "install", *std_cargo_args(root: libexec, path: "crates/recon")
    system "codesign", "--force", "--sign", "-", "--identifier", "me.malstrom.recon",
           libexec/"bin/recon"
    # SwiftPM cannot start its own sandbox inside Homebrew's.
    system "node", "tools/build-helper.ts", "--disable-sandbox"
    system "node", "tools/build-loader.ts"

    (libexec/"bin").install "target/recon-loader",
                            "target/recon-helper.dylib",
                            "target/recon-helper.build-id"
    bin.write_exec_script libexec/"bin/recon"
  end

  def caveats
    <<~EOS
      Recon's Homebrew builds are ad-hoc signed. Accessibility and Screen Recording
      grants can need to be approved again after an upgrade or reinstall changes
      the executable. Inspect the current installation without prompting by running:
        recon context
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/recon --version")
    schema = JSON.parse(shell_output("#{bin}/recon schema"))
    assert_equal version.to_s, schema["recon"]

    %w[recon recon-loader recon-helper.dylib recon-helper.build-id].each do |artifact|
      assert_path_exists libexec/"bin"/artifact
    end
    assert_match(/\A[0-9a-f]{64}\n\z/, (libexec/"bin/recon-helper.build-id").read)
    assert_match "Identifier=me.malstrom.recon",
                 shell_output("codesign -dv #{libexec/"bin/recon"} 2>&1")
  end
end
