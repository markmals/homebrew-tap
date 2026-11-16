class Recon < Formula
  desc "Inspect applications without activating them"
  homepage "https://github.com/markmals/recon"
  url "https://github.com/markmals/recon.git",
      tag:      "v0.2.0",
      revision: "34d63ac7adf418731736dc18a1617bf9fe76c2e6"
  license "MIT"
  head "https://github.com/markmals/recon.git", branch: "main"

  depends_on "node" => :build
  depends_on "rust" => :build
  depends_on arch: :arm64
  # DRY RUN, do not merge: probes whether Recon's macOS 27 tree builds and runs on macOS 26.
  depends_on macos: :tahoe

  def install
    # Retarget the macOS 27 tree at macOS 26 and at the Apple Swift this runner ships.
    swift_build = Utils.safe_popen_read("/usr/bin/xcrun", "swiftc", "--version")[/swiftlang-[\d.]+/]
    odie "no Apple Swift build found" if swift_build.nil?
    inreplace "swift-toolchain.toml", /^build = ".*"$/, "build = \"#{swift_build}\""
    inreplace %w[helper/Package.swift sdks/swift/Package.swift extensions/appkit/Package.swift
                 extensions/catalyst/Package.swift],
              'platforms: [.macOS("27.0")]', 'platforms: [.macOS("26.0")]'
    inreplace "tools/build-loader.ts", '"-Werror",',
              "\"-Werror\",\n            \"-mmacosx-version-min=26.0\","
    inreplace "crates/recon-native-access-macos/src/access.rs",
              "version.split('.').next() == Some(\"27\")",
              "matches!(version.split('.').next(), Some(\"26\" | \"27\"))"

    system "cargo", "install", *std_cargo_args(root: libexec, path: "crates/recon")
    system "codesign", "--force", "--sign", "-", "--identifier", "me.malstrom.recon",
           libexec/"bin/recon"
    # Probes only: each one reports its outcome and never stops the install.
    ohai "PROBE environment", Open3.capture2e("sw_vers").first,
         Open3.capture2e("xcrun", "swiftc", "--version").first
    probe_command libexec/"bin/recon", "context", full: true
    probe_command libexec/"bin/recon", "app", "list", full: true
    probe_command libexec/"bin/recon", "ui", "windows", "com.apple.finder", full: true
    probe_command "xcrun", "swift", "build", "--package-path", "helper", "-c", "release",
                  "--arch", "arm64", "--disable-sandbox"
    probe_command "xcrun", "swift", "build", "--package-path", "helper", "-c", "release",
                  "--arch", "arm64e", "--disable-sandbox"
    %w[sdks/swift extensions/appkit extensions/catalyst helper].each do |package|
      probe_command "xcrun", "swift", "test", "--disable-sandbox", "--package-path", package
    end
    probe_command "cargo", "test", "--workspace", "--release"
    odie "PROBE finished; nothing is installed"
  end

  def probe_command(*args, full: false)
    command = args.map(&:to_s)
    output, status = Open3.capture2e(*command)
    ohai "PROBE #{command.join(" ")} (exit #{status.exitstatus})"
    lines = output.lines
    if full
      puts lines.first(80).join
    else
      summary = /error:|Test run|Executed|test result|✘|Build (complete|failed)|Unable to resolve/
      puts lines.grep(summary).first(60).join
      puts lines.last(10).join
    end
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

    # Probe only: what the CLI says on this OS.
    ohai "sw_vers", shell_output("sw_vers")
    ohai "recon context", shell_output("#{bin}/recon context 2>&1")
    ohai "recon app list", shell_output("#{bin}/recon app list 2>&1")
  end
end
