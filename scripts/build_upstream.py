"""
构建上游 real-time-fund Web 应用并复制产物到 rawfile。

用法：
    python scripts/build_upstream.py

前提：
    - git submodule update --init 已完成
    - Node.js >= 20.9.0 在 Scoop 中安装
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
UPSTREAM_DIR = PROJECT_ROOT / "upstream"
RAWFILE_WEB_DIR = PROJECT_ROOT / "entry" / "src" / "main" / "resources" / "rawfile" / "web"

# Scoop 安装的 Node.js 路径
SCOOP_NODEJS = Path(os.environ.get("USERPROFILE", "C:/Users/xyzsu")) / "scoop" / "apps" / "nodejs" / "current"
NODE_EXE = SCOOP_NODEJS / "node.exe"
NPM_CMD = SCOOP_NODEJS / "npm.cmd"


def get_env() -> dict[str, str]:
    """返回带代理和完整 PATH 的环境变量。"""
    env = os.environ.copy()
    env["http_proxy"] = "http://127.0.0.1:10808"
    env["https_proxy"] = "http://127.0.0.1:10808"
    env["HTTP_PROXY"] = "http://127.0.0.1:10808"
    env["HTTPS_PROXY"] = "http://127.0.0.1:10808"
    path_extra = str(SCOOP_NODEJS)
    if path_extra not in env.get("PATH", ""):
        env["PATH"] = path_extra + os.pathsep + env.get("PATH", "")
    return env


def run_cmd(cmd: list[str], cwd: Path, desc: str) -> None:
    print(f"[{desc}] Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=str(cwd), env=get_env(), capture_output=False)
    if result.returncode != 0:
        print(f"[ERROR] {desc} failed with code {result.returncode}", file=sys.stderr)
        sys.exit(result.returncode)
    print(f"[OK] {desc}")


def main() -> None:
    # Step 0: check prerequisites
    if not NODE_EXE.exists():
        print(f"[ERROR] Node.js not found at {NODE_EXE}", file=sys.stderr)
        sys.exit(1)
    node_ver = subprocess.run(
        [str(NODE_EXE), "--version"], capture_output=True, text=True, env=get_env()
    )
    print(f"[INFO] Node.js version: {node_ver.stdout.strip()}")

    # Step 1: submodule update
    run_cmd(["git", "submodule", "update", "--init", "--recursive"], PROJECT_ROOT,
            "git submodule update")

    out_dir = UPSTREAM_DIR / "out"
    if not UPSTREAM_DIR.exists():
        print("[ERROR] upstream/ directory not found after submodule update", file=sys.stderr)
        sys.exit(1)

    # Step 2: configure npm proxy
    npm = str(NPM_CMD)
    subprocess.run([npm, "config", "set", "proxy", "http://127.0.0.1:10808"],
                   cwd=str(UPSTREAM_DIR), env=get_env(), capture_output=True)
    subprocess.run([npm, "config", "set", "https-proxy", "http://127.0.0.1:10808"],
                   cwd=str(UPSTREAM_DIR), env=get_env(), capture_output=True)

    # Step 3: install dependencies
    run_cmd([npm, "ci", "--legacy-peer-deps"], UPSTREAM_DIR, "npm ci")

    # Step 4: build
    run_cmd([npm, "run", "build"], UPSTREAM_DIR, "npm run build")

    if not out_dir.exists():
        print("[ERROR] upstream build did not produce out/ directory", file=sys.stderr)
        sys.exit(1)

    # Step 4: copy to rawfile
    if RAWFILE_WEB_DIR.exists():
        shutil.rmtree(str(RAWFILE_WEB_DIR))
    shutil.copytree(str(out_dir), str(RAWFILE_WEB_DIR))

    file_count = sum(1 for _ in RAWFILE_WEB_DIR.rglob("*") if _.is_file())
    print(f"[DONE] Copied {file_count} files to {RAWFILE_WEB_DIR}")


if __name__ == "__main__":
    main()
