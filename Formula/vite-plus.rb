class VitePlus < Formula
  desc "Unified Toolchain for the Web"
  homepage "https://viteplus.dev"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/-/vite-plus-cli-darwin-arm64-1.3.0.tgz"
    sha256 "9605459791d46f4f316af9a5e484c0be80ea1b769579f3dbbdf6dba52d3d6bd8"
  else
    url "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-x64/-/vite-plus-cli-darwin-x64-1.3.0.tgz"
    sha256 "9f64307ad3f66f257c4e61d0462c4be9a54e8f9679ed0556b538667209fecd26"
  end

  def install
    # vp loads its JS CLI from node_modules in the directory above its binary;
    # without it, JS-backed commands download the CLI into the user's data dir.
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
  # pnpm otherwise puts its store in the rack, outside the keg, where uninstall leaves it.
  post_install_steps do
    run "vp", args: ["install", "--silent"], base: :bin, chdir: "{{libexec}}", network_access: true,
              env: { "CI" => "true", "pnpm_config_store_dir" => "{{libexec}}/.pnpm-store" }
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
    assert_match "Usage: vp run", shell_output("#{bin}/vpr --help")
  end
end
