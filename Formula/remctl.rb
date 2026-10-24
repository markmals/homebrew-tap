class Remctl < Formula
  desc "Power-user CLI for Apple Reminders"
  homepage "https://github.com/markmals/remctl"
  url "https://github.com/markmals/remctl/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "1756f612323dcb90ee842d0e0877f5045a264e9e19cc98cc19d8d61424f24d87"
  license "MIT"
  head "https://github.com/markmals/remctl.git", branch: "main"

  # Populated by `brew pr-pull` from the CI-built bottles (this seed is replaced).
  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/remctl-0.2.1"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "da156b8a70762a4a461e910d27e051d6b48f2c7e548c9161ffa68e9daeff7ed0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "38fdd6acd1b4c68e5340d80282577ea90b8c3c11bee0e685812153cfbba2780c"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:     "7d1725f09ccb3fee8f20f3b61be4d18dac01217a705cef3259384afb320e3924"
  end

  depends_on xcode: ["16.0", :build]
  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/remctl"
  end

  def caveats
    <<~EOS
      remctl reads your local Reminders database directly and writes through
      Apple's EventKit / ReminderKit APIs, so macOS privacy permissions are
      required before it can do anything useful:

        * Full Disk Access — grant it to the terminal you run remctl from
          (System Settings > Privacy & Security > Full Disk Access). remctl
          reads the Reminders store under ~/Library/Group Containers, which
          is TCC-protected.
        * Reminders access — approved on first write, or run: remctl onboard

      Check your setup at any time:
          remctl doctor

      Permissions are per-app: a green `remctl doctor` in one terminal does not
      grant access to a different terminal, app, or agent runner.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/remctl --version")
    assert_match "Power-user CLI for Apple Reminders", shell_output("#{bin}/remctl --help")
  end
end
