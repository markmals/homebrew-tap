class Mcp < Formula
  desc "Agent-first CLI for Model Context Protocol servers"
  homepage "https://github.com/markmals/mcp"
  url "https://github.com/markmals/mcp.git",
      tag:      "v0.0.1",
      revision: "287b90d35eaede88d588c67ff36c71f10b2e584e"
  head "https://github.com/markmals/mcp.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/mcp")
  end

  def caveats
    <<~EOS
      mcp reads MCP servers from a project's .mcp.json and from
      $XDG_CONFIG_HOME/.mcp.json (~/.config/.mcp.json). Start with:
        mcp --help

      The MCP Python SDK and f/mcptools also install an `mcp`; the first one
      on PATH wins, and Homebrew links only one formula's `mcp` at a time.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mcp --version")

    (testpath/".mcp.json").write <<~JSON
      { "mcpServers": { "demo": { "command": "demo-server", "args": ["--port", "${PORT:-8080}"] } } }
    JSON
    servers = JSON.parse(shell_output("#{bin}/mcp servers list"))
    assert_equal "demo", servers["items"].first["name"]
    assert_equal "project", servers["items"].first["source"]
    assert servers["items"].first["usable"]
  end
end
