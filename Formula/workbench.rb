class Workbench < Formula
  desc "Personal CLI to bootstrap, evolve, and archive/restore projects"
  homepage "https://github.com/markmals/workbench"
  url "https://github.com/markmals/workbench/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "da15d5c79319019a311c92140bf688fdc5b3ce4861d9d5ae8cd1fbf8be52df43"
  license "MIT"
  head "https://github.com/markmals/workbench.git", branch: "main"

  bottle do
    root_url "https://github.com/markmals/homebrew-tap/releases/download/workbench-0.1.0"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "5e3c1ae4a0f103bc4ac8364757bf7100f5c8a9f1c2b4bc4a34b55ca878203290"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "d233f114bf2e37ccc9a9d87b4381bd98959da1ce9a816f0cc6b2c15c35fb1fe8"
  end

  depends_on "go" => :build
  depends_on "gh"
  depends_on "mise"

  def install
    ldflags = %W[
      -s -w
      -X github.com/markmals/workbench/internal/cli.Version=#{version}
      -X github.com/markmals/workbench/internal/cli.Commit=#{tap.user}
      -X github.com/markmals/workbench/internal/cli.BuildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"wb"), "./cmd/wb"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wb version")
  end
end
