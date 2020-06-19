import sys
import subprocess


def o(*cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    proc.wait()
    return proc.stdout.read().decode("utf-8").strip(), proc.returncode


def main():
    if len(sys.argv) != 2:
        print("Usage: %s <proj-name>" % sys.argv[0])
        return

    proj = sys.argv[1]
    (output, status) = o(
        "psql",
        "-t",
        "-c",
        """
            SELECT table_name
            FROM information_schema.tables
            WHERE
                table_name LIKE '%s_%%'
                AND table_schema = 'public'
            ORDER BY table_name;
        """
        % (proj,),
        "amitu_heroku",
    )

    if status:
        print("failed: ", output)
        return

    open("diesel.toml", "w+").write(
        "[print_schema]\nfilter = { only_tables = [%s] }\n"
        % ", ".join('"%s"' % (t,) for t in output.split())
    )


if __name__ == "__main__":
    main()
