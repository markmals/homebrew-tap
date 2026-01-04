class Workbench < Formula
  desc "Personal CLI to bootstrap, evolve, and archive/restore projects"
  homepage "https://github.com/markmals/workbench"
  url "https://github.com/markmals/workbench/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/markmals/workbench/internal/cli.Version=#{version}
      -X github.com/markmals/workbench/internal/cli.Commit=#{tap.user}
      -X github.com/markmals/workbench/internal/cli.BuildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/wb"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wb version")
  end
end
