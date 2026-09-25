class VitePlus < Formula
  desc "Unified Toolchain for the Web"
  homepage "https://viteplus.dev"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/-/vite-plus-cli-darwin-arm64-1.0.0-rc.0.tgz"
    sha256 "1b98b5e93c7bad999ea670b15baa1efd047acfbd3950b2273bd934a650975140"
  else
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-x64/-/vite-plus-cli-darwin-x64-1.0.0-rc.0.tgz"
    sha256 "7e790a049f70e2b6c375853900c9a0efe24ee48de574488a0e88c22d80fa15cb"
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

    # vpx and vpr are multicall aliases — the vp binary changes behavior based on argv[0]
    (libexec/"bin").install_symlink "vp" => "vpx"
    (libexec/"bin").install_symlink "vp" => "vpr"

    bin.install_symlink libexec/"bin/vp"
    bin.install_symlink libexec/"bin/vpx"
    bin.install_symlink libexec/"bin/vpr"
  end

  # Bootstrap JS dependencies using vp itself (no external node required).
  # CI=true suppresses interactive prompts (e.g., Node manager setup).
  post_install_steps do
    run "vp", args: ["install", "--silent"], base: :bin, env: { "CI" => "true" }, chdir: "{{libexec}}",
              network_access: true
  end

  def caveats
    <<~EOS
      Vite+ installed.

      Run `vp create` to start a project.

      If you use a Node version manager (mise, nvm, fnm, etc.),
      it may shadow the Node version that Vite+ manages. Run:

          vp env setup

      to add Vite+'s managed Node to your shell PATH.

      Try:
          vp --version
          vp help
          vp create
          vpx cowsay Vite+ FTW!
          vpr build
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vp --version")
    assert_match "Usage: vpx", shell_output("#{bin}/vpx --help")
    assert_match "Usage: vpr", shell_output("#{bin}/vpr --help")
  end
end
