class Recon < Formula
  desc "Inspect applications without activating them"
  homepage "https://github.com/markmals/recon"
  url "https://github.com/markmals/recon.git",
      tag:      "v0.1.0",
      revision: "a9fa64e2df4bb022f2a1520c22daf81694b0e248"
  license "MIT"
  head "https://github.com/markmals/recon.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/recon-0.1.0"
  end

  depends_on "node" => :build
  depends_on "rust" => :build
  depends_on xcode: ["26.0", :build]
  depends_on arch: :arm64
  depends_on macos: :sequoia

  def install
    system "cargo", "install", *std_cargo_args(root: libexec, path: "crates/recon")
    system "codesign", "--force", "--sign", "-", "--identifier", "me.malstrom.recon",
           libexec/"bin/recon"
    system "node", "tools/build-helper.ts"
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
                 shell_output("codesign -d #{libexec/"bin/recon"} 2>&1")
  end
end
