class Pico < Formula
  desc "ACP agent for Sesh built on the Oh My Pi SDK"
  homepage "https://github.com/markmals/pico"
  url "https://github.com/markmals/pico.git",
      revision: "21d4faa54e6d795a9b3ccc772641605e536b7d3e"
  version "0.0.0"
  license "MIT"
  head "https://github.com/markmals/pico.git", branch: "main"

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
