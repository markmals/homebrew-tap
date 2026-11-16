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
    # SwiftPM cannot start its own sandbox inside Homebrew's.
    system "node", "tools/build-helper.ts", "--disable-sandbox"
    system "node", "tools/build-loader.ts"

    # Probe only: run the Swift suites on this OS; a failure is reported, not fatal.
    %w[sdks/swift extensions/appkit extensions/catalyst helper].each do |package|
      system "xcrun", "swift", "test", "--disable-sandbox", "--package-path", package
    rescue ErrorDuringExecution => e
      opoo "PROBE swift test #{package} failed: #{e.message}"
    end

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

    # Probe only: what the CLI says on this OS.
    ohai "sw_vers", shell_output("sw_vers")
    ohai "recon context", shell_output("#{bin}/recon context 2>&1")
    ohai "recon app list", shell_output("#{bin}/recon app list 2>&1")
  end
end
