"""构建验证脚本 — 第二轮易用性增强（横屏 + 防逃逸）"""
import subprocess
import os
import sys
from pathlib import Path

PROJECT = Path(r"C:\Users\xyzsu\DevecostudioProjects\RealTimeFund")
NODE = r"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe"
HVIGORW = r"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js"
JAVA_HOME = r"C:\Program Files\Huawei\DevEco Studio\jbr"

def main():
    env = os.environ.copy()
    env["NODE_HOME"] = str(Path(NODE).parent)
    env["JAVA_HOME"] = JAVA_HOME
    env["PATH"] = str(Path(JAVA_HOME) / "bin") + os.pathsep + env["PATH"]

    # Step 1: 停止旧 daemon
    subprocess.run(
        [NODE, HVIGORW, "--stop-daemon"],
        cwd=str(PROJECT), capture_output=True, timeout=10
    )

    # Step 2: 构建
    print("🔨 开始构建...")
    p = subprocess.run(
        [NODE, HVIGORW, "assembleHap", "-p", "product=default"],
        cwd=str(PROJECT), env=env, capture_output=True, text=True,
        timeout=300
    )

    output = (p.stdout + p.stderr)
    if "BUILD SUCCESSFUL" in output or p.returncode == 0:
        print("✅ 构建成功！")
        # 打印最后 20 行
        lines = output.strip().split('\n')
        for line in lines[-20:]:
            print(line)
    else:
        print(f"❌ 构建失败 (exit={p.returncode})")
        # 打印错误相关行
        for line in output.split('\n'):
            if 'error' in line.lower() or 'fail' in line.lower() or 'ERROR' in line:
                print(line)

    sys.exit(p.returncode)

if __name__ == '__main__':
    main()
