class Remctl < Formula
  desc "Power-user CLI for Apple Reminders"
  homepage "https://github.com/markmals/remctl"
  url "https://github.com/markmals/remctl/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0d54f7f181826ca0b7760a409d9ef177ebd04400a6cdf7cd851d1ea06e28073f"
  license "MIT"
  head "https://github.com/markmals/remctl.git", branch: "main"

  # Populated by `brew pr-pull` from the CI-built bottles (this seed is replaced).
  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/remctl-0.1.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "74fba099a44e26fb825896418ae2d0e306c6ad382e93d046108f067b2feaebf8"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "e562e7d0b87d7047909e47f93066f95da9420df4ff177b425073d8e3b0710f78"
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
    assert_match "0.1.0", shell_output("#{bin}/remctl --version")
    assert_match "Power-user CLI for Apple Reminders", shell_output("#{bin}/remctl --help")
  end
end
