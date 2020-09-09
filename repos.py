#!/bin/python

#
# This file will print out a yum repos file that can be copied into your
# downstream Dockerfile to help test local builds.
#
# Usage: ./repos.py > rhel.repo
#
# Then in your Dockerfile copy it in with the following:
#
#     COPY rhel.repo /etc/yum.repos.d/rhel.repo
#
import yaml
import sys
import os.path


def main():
    major = "4"
    minor = "3"
    enabled_repos = ["rhel-server-rpms",
                     "rhel-server-optional-rpms",
                     "rhel-server-ose-rpms",
                     "rhel-server-extras-rpms",
                     "rhel-7-server-ansible-2.9-rpms"]

    if not os.path.exists('group.yml'):
        print("Please supply the group.yml from ocp-build-data")
        sys.exit(1)

    with open('group.yml', 'r') as stream:
        repos = yaml.load(stream, Loader=yaml.FullLoader)
        for repo in repos['repos']:
            if repo in enabled_repos:
                print("[" + repo + "]")
                print("name=" + repo)
                if 'x86_64' in repos['repos'][repo]['conf']['baseurl']:
                    baseurl = repos['repos'][repo]['conf']['baseurl']['x86_64']
                    print("baseurl=" + baseurl)
                elif 'unsigned' in repos['repos'][repo]['conf']['baseurl']:
                    baseurl = repos['repos'][repo]['conf']['baseurl']['unsigned']['x86_64']
                    baseurl = baseurl.replace("{MAJOR}", major).replace("{MINOR}", minor)
                    print("baseurl=" + baseurl)
                print("enabled=1")
                print("gpgcheck=0")


if __name__ == "__main__":
    main()
