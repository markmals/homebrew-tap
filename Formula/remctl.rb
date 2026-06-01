class Remctl < Formula
  desc "Power-user CLI for Apple Reminders"
  homepage "https://github.com/markmals/remctl"
  url "https://github.com/markmals/remctl/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "b3edbfb1988e300bb0c6e694778fc88dcc7aeefbec4f6c1873978aab6b4e346e"
  license "MIT"
  head "https://github.com/markmals/remctl.git", branch: "main"

  # Populated by `brew pr-pull` from the CI-built bottles (this seed is replaced).
  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/remctl-0.1.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "0054ccdbba79b649475f78198cd860b68bc6a348e773b70c34c09bb0b7e51d84"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "63a7252b41dfb0eee0a7cd10276308d4f234f226f05ccd70a128a76adf7a52c1"
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
