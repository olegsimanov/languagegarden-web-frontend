#!/usr/bin/env python
from __future__ import print_function
import os.path
import sys
from StringIO import StringIO

import yaml
from jinja2 import Environment, FileSystemLoader


ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))


def merge(data, ext_data):
    if isinstance(data, dict) and isinstance(ext_data, dict):
        for k, v in ext_data.items():
            if k not in data:
                data[k] = v
            else:
                data[k] = merge(data[k], v)
        return data
    else:
        return ext_data


def get_pillar_data(instance_type):
    template_loader = FileSystemLoader(
        os.path.join(ROOT_DIR, 'deployment', 'pillar'))
    env = Environment(loader=template_loader)
    template = env.get_template('target/{}.sls'.format(instance_type))
    pillar_yaml = template.render()
    unmerged_data = yaml.safe_load(StringIO(pillar_yaml))
    data = {}
    for item in unmerged_data:
        merge(data, item)
    return data


def get_debian_requirements(instance_type):
    data = get_pillar_data(instance_type)
    req_dict = data.get('system', {}).get('packages', {})
    return req_dict.keys()


def get_brew_requirements(instance_type):
    data = get_pillar_data(instance_type)
    req_dict = data.get('system', {}).get('brew_packages', {})
    return req_dict.keys()


def get_pip_requirements(instance_type):
    data = get_pillar_data(instance_type)
    req_dict = data.get('venv', {}).get('python', {}).get('packages', {})
    return req_dict.keys()


def get_npm_global_requirements(instance_type):
    data = get_pillar_data(instance_type)
    req_dict = data.get('venv', {}).get('node', {}).get('packages', {})
    return req_dict.keys()


def get_file_content(instance_type, filepath):
    template_loader = FileSystemLoader(
        os.path.join(ROOT_DIR, 'deployment', 'salt'))
    env = Environment(loader=template_loader)
    template = env.get_template(filepath)

    return template.render(pillar=get_pillar_data(instance_type))


def get_settings_filename(instance_type):
    pillar_data = get_pillar_data(instance_type)
    return pillar_data['django']['settings_filename']


def print_data(data):
    if isinstance(data, list):
        for r in data:
            print(r)
    else:
        print(data)


def print_brewfile(brew_requirements):
    for req in brew_requirements:
        print('brew "{req}"'.format(req=req))


def main(args):
    if len(args) < 3:
        print('ERROR: mising parameters', file=sys.stderr)
        print('Usage:{} [instance-type] [what]'.format(args[0]),
              file=sys.stderr)
        sys.exit(1)
    instance_type = args[1]
    what = args[2]
    if what == 'debian-requirements':
        print_data(get_debian_requirements(instance_type))
    elif what == 'brewfile-requirements':
        print_brewfile(get_brew_requirements(instance_type))
    elif what == 'pip-requirements':
        print_data(get_pip_requirements(instance_type))
    elif what == 'npm-global-requirements':
        print_data(get_npm_global_requirements(instance_type))
    elif what == 'settings-file':
        print_data(get_file_content(instance_type, 'django/settings.py'))
    elif what == 'manage-file':
        print_data(get_file_content(instance_type, 'django/manage.py'))
    elif what == 'webpack-config-file':
        print_data(get_file_content(instance_type, 'webpack/config.js'))
    elif what == 'settings-filename':
        print_data(get_settings_filename(instance_type))
    else:
        print('extract what?', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main(sys.argv)
