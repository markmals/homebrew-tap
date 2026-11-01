class Pico < Formula
  desc "ACP agent for Sesh built on the Oh My Pi SDK"
  homepage "https://github.com/markmals/pico"
  url "https://github.com/markmals/pico.git",
      tag:      "v0.1.0",
      revision: "4735872b79fe960491ab54aede8467151eaa4eeb"
  license "MIT"
  head "https://github.com/markmals/pico.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/pico-0.1.0"
    sha256 arm64_golden_gate: "c31bd3a58426ca9b9ce4098715c24a89baf52806a4e842b574f19ab30d94f2c0"
    sha256 arm64_tahoe:       "71672e705665703e5c0d6fd3eda600e69965e84ba6fc3876efb776974f1de17d"
    sha256 arm64_sequoia:     "b9220fa7567c14ed4f361c8f35090d35b6aecb06459da238eeae1c1df4892c6f"
  end

  depends_on "bun" => :build
  depends_on arch: :arm64
  depends_on macos: :sonoma

  def install
    system "bun", "install", "--frozen-lockfile", "--production"
    system "bun", "tools/build-pico.ts", "--outfile", bin/"pico"
    prefix.install "LICENSE", "THIRD-PARTY-NOTICES.md"
  end

  def caveats
    <<~EOS
      Sesh launches pico as an ACP agent. Add it in Sesh under Settings > Machines >
      this Mac > Details... > Add an Agent... > Custom..., with the executable:
        #{HOMEBREW_PREFIX}/bin/pico

      macOS ships a text editor at /usr/bin/pico. With Homebrew first on your PATH,
      `pico` now runs Pico instead; `nano` or /usr/bin/pico still opens the editor.

      Pico keeps its own files in ~/Library/Application Support/Pico. Uninstalling
      leaves that folder; delete it to remove them.
    EOS
  end

  test do
    assert_equal "pico #{version}\n", shell_output("#{bin}/pico --version")
    assert_equal "usage: pico [--version]\n", shell_output("#{bin}/pico somefile 2>&1", 2)
    system "codesign", "--verify", bin/"pico"
  end
end
