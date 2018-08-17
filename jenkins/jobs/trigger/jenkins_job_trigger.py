#!/usr/bin/python
"""
Allows a Jenkins "trigger job" to trigger a "test job" with a specified set of
parameters, taken as command-line arguments.
"""

import logging

import argparse
from jenkinsapi.custom_exceptions import NoBuildData
from jenkinsapi.jenkins import Jenkins
from jenkinsapi.api import log as jenkins_api_log


formatter = logging.Formatter('%(asctime)s | %(message)s', '%Y-%m-%d %H:%M:%S')
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
console_handler.setFormatter(formatter)

LOG = logging.getLogger(__name__)
LOG.setLevel(logging.DEBUG)
LOG.addHandler(console_handler)
jenkins_api_log.setLevel(logging.DEBUG)
jenkins_api_log.addHandler(console_handler)


def is_tested(jenkinsci, job_name, build_num):
    """
    Checks to see whether a specified build has already been tested.
    """
    try:
        job = jenkinsci[job_name]
        build = job.get_last_build()
    except NoBuildData:
        LOG.warning('No build data found in job %s', job_name)
        return False

    last_build_id = build._data['displayName']
    LOG.info('Last build of job %s is %s', job, last_build_id)

    if last_build_id != build_num:
        LOG.info('Build %s is not tested yet', build_num)
        return False

    LOG.info('Build %s is already tested', build_num)
    return True


def main():
    """
    Trigger job for VIC nightly scenario tests
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("jenkins", help="Jenkins Url.")
    parser.add_argument("username", help="Log in username")
    parser.add_argument("password", help="User password")
    parser.add_argument("vsphere_version", help="Vsphere version.")
    parser.add_argument("vc_build", help="VC build number.")
    parser.add_argument("esx_build", help="ESXi build number.")
    parser.add_argument("build_num", help="VIC build number.")
    parser.add_argument("job_name", help="Job name to trigger.")
    args = parser.parse_args()
    jenkinsci = Jenkins(args.jenkins, username=args.username,
                        password=args.password)
    if not is_tested(jenkinsci, args.job_name, args.build_num):
        params = {'VSPHERE_VERSION': args.vsphere_version,
                  'ESX_BUILD': args.esx_build,
                  'VC_BUILD': args.vc_build,
                  'BUILD_NUM': args.build_num}
        jenkinsci.build_job(jobname=args.job_name, params=params)
        LOG.debug('Triggered job %s with parameters %s.', args.job_name,
                  params)


if __name__ == '__main__':
    main()
