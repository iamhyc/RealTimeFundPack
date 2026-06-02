"""真机验证脚本 — 构建 + 部署 + 启动 + 日志"""
import subprocess
import os
import sys
from pathlib import Path

PROJECT = Path(r"C:\Users\xyzsu\DevecostudioProjects\RealTimeFund")
NODE = r"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe"
HVIGORW = r"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js"
JAVA_HOME = r"C:\Program Files\Huawei\DevEco Studio\jbr"
HAP = PROJECT / "entry/build/default/outputs/default/entry-default-signed.hap"
BUNDLE = "xyz.sudofree.myapplication"

def run(cmd, **kw):
    """运行命令，打印输出，返回 CompletedProcess"""
    print(f"  → {' '.join(str(c) for c in cmd[:5])}...")
    return subprocess.run(cmd, **kw)

def step_build():
    """Step 1: 构建 HAP"""
    env = os.environ.copy()
    env["NODE_HOME"] = str(Path(NODE).parent)
    env["JAVA_HOME"] = JAVA_HOME
    env["PATH"] = str(Path(JAVA_HOME) / "bin") + os.pathsep + env["PATH"]

    # 停旧 daemon
    subprocess.run([NODE, HVIGORW, "--stop-daemon"], cwd=str(PROJECT),
                   capture_output=True, timeout=10)

    p = subprocess.run(
        [NODE, HVIGORW, "assembleHap", "-p", "product=default"],
        cwd=str(PROJECT), env=env, capture_output=True, text=True, timeout=300
    )
    output = p.stdout + p.stderr
    if "BUILD SUCCESSFUL" in output or p.returncode == 0:
        print("✅ 构建成功")
        return True
    else:
        print(f"❌ 构建失败 (exit={p.returncode})")
        for line in output.split('\n'):
            low = line.lower()
            if any(k in low for k in ['error', 'fail', 'unresolved']):
                print(f"  {line.strip()}")
        return False

def step_deploy():
    """Step 2: 安装到真机"""
    if not HAP.exists():
        print(f"❌ HAP 不存在: {HAP}")
        return False
    p = subprocess.run(
        ["hdc", "app", "install", "-r", str(HAP)],
        capture_output=True, text=True, timeout=60
    )
    print(p.stdout.strip() or p.stderr.strip())
    if p.returncode == 0 or "success" in (p.stdout + p.stderr).lower():
        print("✅ 安装成功")
        return True
    else:
        print(f"❌ 安装失败 (exit={p.returncode})")
        return False

def step_start():
    """Step 3: 启动 App"""
    p = subprocess.run(
        ["hdc", "shell", "aa", "start", "-a", "EntryAbility", "-b", BUNDLE],
        capture_output=True, text=True, timeout=30
    )
    print(p.stdout.strip() or p.stderr.strip())
    if p.returncode == 0:
        print("✅ 启动成功")
        return True
    else:
        print(f"❌ 启动失败 (exit={p.returncode})")
        return False

def step_logs():
    """Step 4: 抓取 WebView 相关日志（最近 50 行）"""
    print("\n📋 最近 WebView 日志：")
    p = subprocess.run(
        ["hdc", "shell", "hilog", "-x", "-T", "Web", "-L", "error"],
        capture_output=True, text=True, timeout=15
    )
    lines = [l for l in (p.stdout + p.stderr).split('\n') if l.strip()]
    for line in lines[-50:]:
        print(f"  {line}")
    if not lines:
        print("  (无日志)")

def main():
    print("=" * 50)
    print("真机验证：横屏 + 防逃逸")
    print("=" * 50)

    print("\n🔨 [1/4] 构建...")
    if not step_build():
        sys.exit(1)

    print("\n📦 [2/4] 安装...")
    if not step_deploy():
        sys.exit(1)

    print("\n🚀 [3/4] 启动...")
    if not step_start():
        sys.exit(1)

    print("\n📋 [4/4] 日志...")
    step_logs()

    print("\n" + "=" * 50)
    print("✅ 真机验证流程完成。请手动检查：")
    print("  1. 旋转设备 → 确认横屏正常显示")
    print("  2. 点击外部链接 → 确认在系统浏览器打开（不逃逸）")
    print("=" * 50)

if __name__ == '__main__':
    main()
