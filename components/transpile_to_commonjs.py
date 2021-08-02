from __future__ import unicode_literals
import json
import os
import re
import sys

MODULE_HEADER_PATTERN = (
    r'^modular\.define name\: \'(([a-z\_]+\.)+[a-z\_]+)\'\,$')

MODULE_DEPENDENCIES_PATTERN = (
    r'^dependencies: \[$')

MODULE_DEPENDENCIES_PROLOGUE_PATTERN = r'^\]\,$'

MODULE_BODY_START_PATTERN = r'^body\: \(?([a-zA-Z\_\, ]*)(\) ?->)?'
MODULE_BODY_START_CONT_PATTERN = r'^       ([a-zA-Z\_\, ]*)(\) ?->)?'
MODULE_EXPORTS_START_PATTERN = r'^    \# ?([pP]ublic )?[eE]xports?\.?'


def prepare_files_data(base_dirpath, target_dirpath):
    prefix_len = len(base_dirpath) + 1
    for dirpath, _, filenames in os.walk(base_dirpath):
        for filename in filenames:
            _, file_ext = os.path.splitext(filename)
            if file_ext not in ['.coffee']:
                continue
            filepath = os.path.join(dirpath, filename)
            local_path = filepath[prefix_len:]

            target_filepath = os.path.join(target_dirpath, local_path)
            yield {
                'source_filepath': filepath,
                'target_filepath': target_filepath,
                'module_names': (['languagegarden']
                                 + local_path[:-len(file_ext)].split('/'))
            }


def find_pattern_and_line_number(lines, pattern, pattern_name,
                                 start_line_number=0,
                                 end_line_number=None):
    if end_line_number is None:
        end_line_number = len(lines)

    for i in range(start_line_number, end_line_number):
        line = lines[i]
        m = re.match(pattern, line)
        if m:
            return (m, i)

    raise LookupError('No {} found'.format(pattern_name))


def process_dependencies(raw_dependencies):
    for rd in raw_dependencies:
        if isinstance(rd, (unicode, str)):
            yield (rd.split('.'), None)
        elif isinstance(rd, (list, tuple)) and len(rd) == 2:
            module_name, module_dependencies = rd
            if not isinstance(module_dependencies, (list, tuple)):
                module_dependencies = (module_dependencies,)
            yield (module_name.split('.'), module_dependencies)
        else:
            raise ValueError('invalid dependencies')


def get_dependencies(dependency_lines):
    lines = []
    for line in dependency_lines:
        line = (line.replace('\'', '"')
                    .replace(']\n', '],\n')
                    .replace('"\n', '",\n'))
        lines.append(line)
    dependency_json = '[\n{}\n]'.format((''.join(lines)).rstrip(',\n '))
    dependency_json = re.sub(r',(\s*)]', r'\1]', dependency_json)
    try:
        raw_dependencies = json.loads(dependency_json)
    except ValueError:
        print(dependency_json)
        raise
    return list(process_dependencies(raw_dependencies))


def get_relative_path(source_names, target_names):
    same_names_num = 0
    for sn, tn in zip(source_names, target_names):
        if sn != tn:
            break
        same_names_num += 1

    rel_names = ['.']
    rel_names.extend(['..'] * (len(source_names) - same_names_num - 1))
    rel_names.extend(target_names[same_names_num:])
    return '/'.join(rel_names)


def is_require_short(require_start, require_end, dep_elements=[]):
    line_len = 0
    line_len += len(require_start)
    line_len += len(require_end)
    line_len += sum(len(c) for c in dep_elements)
    line_len += 2 * (len(dep_elements) - 1) if dep_elements else 0
    return line_len < 79


def construct_short_require_line(require_start, require_end,
                                 dep_elements=[]):
    return '{}{}{}\n'.format(
        require_start,
        ', '.join(dep_elements),
        require_end,
    )


def write_file(out_f, module_names, dependencies, param_names, body_lines,
               public_exports_lines):

    indent = ' ' * 4
    initial_indent = indent

    def write_indented(line):
        out_f.write(initial_indent + line)

    write_indented('\'use strict\'\n\n')

    for dep in dependencies:
        if isinstance(dep[0], (tuple, list)):
            relative_path = get_relative_path(module_names, dep[0])
        else:
            relative_path = dep[0]
        if dep[1] is None:
            require_line = '{} = require(\'{}\')\n'.format(
                param_names[0],
                relative_path,
            )
            write_indented(require_line)
            param_names = param_names[1:]
        else:
            dep_elements = dep[1]
            dep_param_names = param_names[:len(dep_elements)]
            if dep_param_names != dep_elements:
                ValueError('{} != {}'.format(dep_param_names, dep_elements))
            require_start = '{'
            require_end = '}} = require(\'{}\')'.format(relative_path)

            if is_require_short(require_start, require_end, dep_elements):
                require_line = construct_short_require_line(
                    require_start, require_end, dep_elements)

                write_indented(require_line)
            else:
                write_indented(require_start + '\n')
                for chunk in dep_elements:
                    write_indented(indent + chunk + '\n')
                write_indented(require_end + '\n')
            param_names = param_names[len(dep_param_names):]

    out_f.write('\n')

    for line in body_lines:
        out_f.write(line)

    write_indented('module.exports =\n')
    for line in public_exports_lines:
        out_f.write(indent + line)


def add_external_lib(dep_data, lines, pattern, dependency, param_name=None):
    content = ''.join(lines)
    m = re.search(pattern, content)
    if m:
        param_name = param_name or m.groups()[0]

        dep_data['dependencies'] = ([(dependency, None)]
                                    + dep_data['dependencies'])
        dep_data['param_names'] = [param_name] + dep_data['param_names']

    return dep_data


def transpile_file(file_data):
    with open(file_data['source_filepath'], 'rt') as in_f:

        lines = in_f.readlines()

        m, module_hdr_linenum = find_pattern_and_line_number(
            lines,
            MODULE_HEADER_PATTERN,
            'module header',
        )

        module_names = m.groups()[0].split('.')

        module_dep_linenum = None
        module_dep_prologue_linenum = None
        try:
            _, module_dep_linenum = find_pattern_and_line_number(
                lines,
                MODULE_DEPENDENCIES_PATTERN,
                'dependencies',
                start_line_number=module_hdr_linenum + 1,
            )
            _, module_dep_prologue_linenum = find_pattern_and_line_number(
                lines,
                MODULE_DEPENDENCIES_PROLOGUE_PATTERN,
                'dependencies prologue',
                start_line_number=module_dep_linenum + 1,
            )
        except LookupError:
            pass

        module_hdr_end_linenum = (module_dep_prologue_linenum
                                  or module_hdr_linenum)

        if module_dep_linenum and module_dep_prologue_linenum:
            dependencies = get_dependencies(
                lines[module_dep_linenum + 1:module_dep_prologue_linenum]
            )
        else:
            dependencies = []

        m, _ = find_pattern_and_line_number(
            lines,
            MODULE_BODY_START_PATTERN,
            'body start',
            start_line_number=module_hdr_end_linenum + 1,
            end_line_number=module_hdr_end_linenum + 2,
        )

        param_names = filter(
            None,
            [s.strip() for s in m.groups()[0].split(',')]
        )
        body_closed = bool(m.groups()[1])

        body_linenum = module_hdr_end_linenum + 2

        while not body_closed:
            try:
                m, _ = find_pattern_and_line_number(
                    lines,
                    MODULE_BODY_START_CONT_PATTERN,
                    'body start continued',
                    start_line_number=body_linenum,
                    end_line_number=body_linenum + 1,
                )
                param_names += filter(
                    None,
                    [s.strip() for s in m.groups()[0].split(',')]
                )
                body_closed = bool(m.groups()[1])
                body_linenum += 1
            except LookupError:
                break

        _, public_exports_linenum = find_pattern_and_line_number(
            lines,
            MODULE_EXPORTS_START_PATTERN,
            'module exports',
            start_line_number=body_linenum,
        )

        dep_data = {
            'dependencies': dependencies,
            'param_names': param_names,
            'module_name': '.'.join(module_names),
        }

        add_external_lib(dep_data, lines, r'[^\.\@](\$)', 'jquery')
        add_external_lib(dep_data, lines, r'(jQuery)', 'jquery')
        add_external_lib(dep_data, lines, r'(Backbone)', 'backbone')
        add_external_lib(dep_data, lines, r'(\_)', 'underscore')
        add_external_lib(dep_data, lines, r'(Raphael)', 'raphael', '__raphael')
        add_external_lib(dep_data, lines, r'(Hammer)', 'hammer')

        dependencies = dep_data['dependencies']
        param_names = dep_data['param_names']

        # print('.'.join(module_names))
        # print(param_names)
        # print(dependencies)

        num_of_dep = sum(1 if d[1] is None else len(d[1])
                         for d in dependencies)
        num_of_params = len(param_names)

        if num_of_params != num_of_dep:
            raise ValueError('dependency mismatch {} != {}'.format(
                num_of_params, num_of_dep))

        dirname = os.path.dirname(file_data['target_filepath'])
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        with open(file_data['target_filepath'], 'wt') as out_f:
            write_file(out_f, module_names, dependencies, param_names,
                       lines[body_linenum:public_exports_linenum],
                       lines[public_exports_linenum + 1:])


def main(args):
    files_data = prepare_files_data(
        '../languagegarden/static/cs',
        'app/scripts/languagegarden',
    )
    for file_data in files_data:
        try:
            transpile_file(file_data)
        except Exception as e:
            print('{} in {}'.format(e, file_data['source_filepath']))


if __name__ == '__main__':
    main(sys.argv)
