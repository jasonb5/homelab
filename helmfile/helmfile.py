import argparse
import re
import subprocess
import yaml

parser = argparse.ArgumentParser()

parser.add_argument("--update-repo", action="store_true")

def update_helmfile(update_repo, **_):
    if update_repo:
        subprocess.run(["helm", "repo", "update"], capture_output=True)

    with open('helmfile.yaml') as fd:
        data = yaml.load(fd, Loader=yaml.SafeLoader)

    for config in data['releases']:
        chart = config['chart']
        version = config['version']

        print(f"Checking {chart} for update from {version}")

        output = subprocess.run(["helm", "search", "repo", chart, "--version", f">{version}"], capture_output=True)

        try:
            new_version = re.sub(r"\s+", " ", output.stdout.decode("utf-8").split("\n")[1]).split(" ")[1]
        except Exception:
            print(f"Skipping {chart}")
        else:
            config['version'] = new_version

            print(f"Updated version to {new_version}")

    with open('helmfile.yaml', 'w') as fd:
        yaml.dump(data, fd)

if __name__ == '__main__':
    kwargs = vars(parser.parse_args())

    update_helmfile(**kwargs)
