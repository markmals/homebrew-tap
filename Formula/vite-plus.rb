class VitePlus < Formula
  desc "Unified Toolchain for the Web"
  homepage "https://viteplus.dev"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/-/vite-plus-cli-darwin-arm64-0.1.13.tgz"
    sha256 "a7a815042bd2d5c65230bbb3c18550f6a1f22219aebee93e7d1fef2eeef3042f"
  else
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-x64/-/vite-plus-cli-darwin-x64-0.1.13.tgz"
    sha256 "953f43d09ba8651db0d9035392fdb3f96e051349779f991dedfa73a83cd8a873"
  end

  def install
    # Install binary into libexec/bin/ so it sits inside a version directory
    # that mirrors the structure the install script creates (~/.vite-plus/<ver>/)
    (libexec/"bin").install Dir["**/vp"].first => "vp"

    # Create wrapper package.json so `vp install` can pull down the JS CLI
    # (needed for commands like migrate/create that delegate to JS)
    (libexec/"package.json").write <<~JSON
      {
        "name": "vp-global",
        "version": "#{version}",
        "private": true,
        "dependencies": {
          "vite-plus": "#{version}"
        }
      }
    JSON

    # vpx is a multicall alias — the vp binary changes behavior based on argv[0]
    (libexec/"bin").install_symlink "vp" => "vpx"

    bin.install_symlink libexec/"bin/vp"
    bin.install_symlink libexec/"bin/vpx"
  end

  def post_install
    # Bootstrap JS dependencies using vp itself (no external node required).
    # This runs outside the sandbox so vp can download Node if needed.
    # CI=true suppresses interactive prompts (e.g., Node manager setup).
    cd libexec do
      ENV["CI"] = "true"
      system bin/"vp", "install", "--silent"
    end
  end

  def caveats
    <<~EOS
      Vite+ installed.

      Run `vp create` to start a project.

      If you want Vite+ to manage Node versions:
          vp env setup

      Try:
          vp --version
          vp help
          vp create
          vpx cowsay Vite+ FTW!
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vp --version")
    assert_match "Usage: vpx", shell_output("#{bin}/vpx --help")
  end
end
