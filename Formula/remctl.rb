class Remctl < Formula
  desc "Power-user CLI for Apple Reminders"
  homepage "https://github.com/markmals/remctl"
  url "https://github.com/markmals/remctl/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "076ba09eb5220245034f3b22c7e0e631516fdfba62b086b3a41b23e0677870c2"
  license "MIT"
  head "https://github.com/markmals/remctl.git", branch: "main"

  # Populated by `brew pr-pull` from the CI-built bottles (this seed is replaced).
  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/remctl-0.3.0"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "21b79ac2489dcbfe9875309e4e7e07d5409b187ebe3b23c8ef9ada00be01bd94"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "f9703a09293285dbd125bfb3c82e280cfab99024770a136ee22ecf4fff264246"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:     "5141b825a9e1a11629c119079765727034b9765cc6a81a2e49d2d20c5bb88fd7"
  end

  depends_on xcode: ["16.0", :build]
  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/remctl"
    bin.install_symlink "remctl" => "rctl"
    bin.install_symlink "remctl" => "reminders"
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

      remctl also answers to `rctl` and `reminders`. keith/reminders-cli installs
      its own `reminders`, so only one of the two can be linked at a time.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/remctl --version")
    assert_match "Power-user CLI for Apple Reminders", shell_output("#{bin}/remctl --help")
    assert_match "USAGE: rctl", shell_output("#{bin}/rctl --help")
  end
end
