import sys
import subprocess


def o(*cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    proc.wait()
    return proc.stdout.read().decode("utf-8").strip(), proc.returncode


def main():
    if len(sys.argv) != 3:
        print("Usage: %s <proj-name> <db>" % sys.argv[0])
        return

    proj = sys.argv[1] + "_"
    db = sys.argv[2]

    (output, status) = o("sqlite3", db, ".tables")

    if status:
        print("failed: ", output)
        return

    print(output)

    open("diesel.toml", "w+").write(
        "[print_schema]\nfilter = { only_tables = [%s] }\n"
        % ", ".join('"%s"' % (t,) for t in output.split() if t.startswith(proj))
    )


if __name__ == "__main__":
    main()
