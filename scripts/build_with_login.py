import subprocess, os, shutil
from pathlib import Path

PROJECT = Path(r"C:\Users\xyzsu\DevecostudioProjects\RealTimeFund")
UPSTREAM = PROJECT / "upstream"
RAWFILE_WEB = PROJECT / "entry/src/main/resources/rawfile/web"
ENV_LOCAL = UPSTREAM / ".env.local"
NPM = r"C:\Users\xyzsu\scoop\apps\nodejs\current\npm.cmd"

# Step 1: 写入 .env.local（Supabase 配置）
ENV_LOCAL.write_text("""\
NEXT_PUBLIC_SUPABASE_URL=https://mouvsqlmgymsaxikvqsh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_c5f58knbVz8UgOh6L88MUQ_p9j8c1Q-
""", encoding="utf-8")
print(f"[1/4] .env.local 已创建: {ENV_LOCAL}")

# Step 2: npm install（补装缺失，不删已有）
env = os.environ.copy()
env["NEXT_FORCE_WEBPACK"] = "1"
result = subprocess.run(
    [NPM, "install", "--legacy-peer-deps"],
    cwd=str(UPSTREAM), env=env, capture_output=True, text=True
)
print(f"[2/4] npm install exit={result.returncode}")
if result.returncode != 0:
    print("STDERR:", result.stderr[-500:])

# Step 3: npm run build
result = subprocess.run(
    [NPM, "run", "build"],
    cwd=str(UPSTREAM), env=env, capture_output=True, text=True
)
print(f"[3/4] npm run build exit={result.returncode}")
if result.returncode != 0:
    print("STDERR:", result.stderr[-1000:])
    raise SystemExit(result.returncode)

# Step 4: 复制产物到 rawfile
if RAWFILE_WEB.exists():
    shutil.rmtree(RAWFILE_WEB)
shutil.copytree(UPSTREAM / "out", RAWFILE_WEB)
print(f"[4/4] 产物已复制到: {RAWFILE_WEB}")
print("Done!")
