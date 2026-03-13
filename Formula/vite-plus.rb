class VitePlus < Formula
  desc "Unified Toolchain for the Web"
  homepage "https://viteplus.dev"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/-/vite-plus-cli-darwin-arm64-0.1.11.tgz"
    sha256 "d47399881e58304e73d7bcd3efb8a0c67d89bce7785c5e5c405aecb69b72fd28"
  else
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-x64/-/vite-plus-cli-darwin-x64-0.1.11.tgz"
    sha256 "aa29bf65e8b8cfb803280fa8ce03067e1ee11725b5b2a931463f83abcb541cf2"
  end

  def install
    bin.install Dir["**/vp"].first => "vp"
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
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vp --version")
  end
end
