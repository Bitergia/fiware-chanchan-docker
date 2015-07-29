# Copyright (C) 2014 Universidad Politecnica de Madrid
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import ConfigParser
import json
import os
import string
import code
import readline
import rlcompleter

from conf import settings

from keystoneclient.v3 import client

from fabric.api import task
from fabric.tasks import Task
from fabric.state import env
from fabric.api import execute

@task
def test_data(keystone_path=settings.KEYSTONE_ROOT):
    """Populate the database with some users, organizations and applications
    for convenience"""

    # Log as idm
    config = ConfigParser.ConfigParser()
    config.read(keystone_path + 'etc/keystone.conf')
    admin_port = config.get('DEFAULT', 'admin_port')
    endpoint = 'http://{ip}:{port}/v3'.format(ip='127.0.0.1',
                                              port=admin_port)
    keystone = client.Client(
        username=settings.IDM_USER_CREDENTIALS['username'],
        password=settings.IDM_USER_CREDENTIALS['password'],
        project_name=settings.IDM_USER_CREDENTIALS['project'],
        auth_url=endpoint)

    # Create some default apps to test
    for app_name in settings.FIWARE_DEFAULT_APPS:
        app = keystone.oauth2.consumers.create(
            app_name,
            description='Default app in FIWARE',
            grant_type='authorization_code',
            client_type='confidential')
        # Create default roles
        for role_name in settings.FIWARE_DEFAULT_APPS[app_name]:
            keystone.fiware_roles.roles.create(
                name=role_name,
                is_internal=False,
                application=app.id)

    owner_role = keystone.roles.find(name='owner')

    # Create 4 users
    users = []
    for i in range(10):
        username = 'user'
        users.append(_register_user(keystone, username + str(i)))

    # Register pepProxy user

    pep_user = _register_user(keystone, 'pepproxy')

    # Create Org A and Org B

    org_a = keystone.projects.create(
        name='Organization A',
        description='Test Organization A',
        domain=settings.KEYSTONE_DEFAULT_DOMAIN,
        enabled=True,
        img='/static/dashboard/img/logos/small/group.png',
        city='',
        email='',
        website='')
    keystone.roles.grant(user=pep_user.id,
                         role=owner_role.id,
                         project=org_a.id)

    org_b = keystone.projects.create(
        name='Organization B',
        description='Test Organization B',
        domain=settings.KEYSTONE_DEFAULT_DOMAIN,
        enabled=True,
        img='/static/dashboard/img/logos/small/group.png',
        city='',
        email='',
        website='')
    keystone.roles.grant(user=pep_user.id,
                         role=owner_role.id,
                         project=org_b.id)

    # Create chanchan APP and give provider role to the pepProxy
    # TODO: modify the url + callback when the app is ready
    chanchan_app = keystone.oauth2.consumers.create(
        name='Chanchan',
        redirect_uris=['http://localhost/login'],
        description='Chanchan Test Application',
        scopes=['all_info'],
        client_type='confidential',
        grant_type='authorization_code',
        url='http://localhost',
        img='/static/dashboard/img/logos/small/app.png')
    provider_role = next(r for r
                         in keystone.fiware_roles.roles.list()
                         if r.name == 'provider')
    keystone.fiware_roles.roles.add_to_user(
        role=provider_role.id,
        user=pep_user.id,
        application=chanchan_app.id,
        organization=pep_user.default_project_id)

    # Create a role 'Orion' for the application
    role_orion = keystone.fiware_roles.roles.create(
        name='Orion Operations',
        is_internal=False,
        application=chanchan_app.id)

    # Give it the permission to get and assign only the owned roles
 
    internal_permission_owned = next(
        p for p in keystone.fiware_roles.permissions.list()
        if p.name == settings.INTERNAL_PERMISSIONS[4])
    keystone.fiware_roles.permissions.add_to_role(
        role=role_orion,
        permission=internal_permission_owned)

    # Make user 0 owner of the organization A and give Orion role
    user0 = users[0]
    
    keystone.roles.grant(user=user0.id,
                         role=owner_role.id,
                         project=org_a.id)

    keystone.fiware_roles.roles.add_to_user(
        role=role_orion.id,
        user=user0.id,
        application=chanchan_app.id,
        organization=user0.default_project_id)

    # Make user 1 owner of the organization B and give Orion role
    user1 = users[1]

    keystone.roles.grant(user=user1.id,
                         role=owner_role.id,
                         project=org_b.id)

    keystone.fiware_roles.roles.add_to_user(
        role=role_orion.id,
        user=user1.id,
        application=chanchan_app.id,
        organization=user1.default_project_id)

    # Adding permissions for Orion

    perm0 = keystone.fiware_roles.permissions.create(
                name='updateContext', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/updateContext',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm0)

    perm1 = keystone.fiware_roles.permissions.create(
                name='queryContext', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/queryContext',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm1)

    perm2 = keystone.fiware_roles.permissions.create(
                name='subscribeContext', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/subscribeContext',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm2)

    perm3 = keystone.fiware_roles.permissions.create(
                name='updateContextSubscription', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/updateContextSubscription',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm3)

    perm4 = keystone.fiware_roles.permissions.create(
                name='unsubscribeContext', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/unsubscribeContext',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm4)

    perm5 = keystone.fiware_roles.permissions.create(
                name='registry/registerContext', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/registry/registerContext',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm5)

    perm6 = keystone.fiware_roles.permissions.create(
                name='registry/discoverContextAvailability', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/registry/discoverContextAvailability',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm6)

    perm7 = keystone.fiware_roles.permissions.create(
                name='/registry/subscribeContextAvailability', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1//registry/subscribeContextAvailability',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm7)

    perm8 = keystone.fiware_roles.permissions.create(
                name='registry/updateContextAvailabilitySubscription', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/registry/updateContextAvailabilitySubscription',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm8)

    perm9 = keystone.fiware_roles.permissions.create(
                name='registry/unsubscribeContextAvailability', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/registry/unsubscribeContextAvailability',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm9)

    perm10 = keystone.fiware_roles.permissions.create(
                name='registry/contextAvailabilitySubscriptions', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/registry/contextAvailabilitySubscriptions',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm10)

    perm11 = keystone.fiware_roles.permissions.create(
                name='contextTypes', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/contextTypes',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm11)

    perm12 = keystone.fiware_roles.permissions.create(
                name='contextSubscriptions', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/contextSubscriptions',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm12)

    perm13 = keystone.fiware_roles.permissions.create(
                name='contextEntities', 
                application=chanchan_app, 
                action= 'POST', 
                resource= 'v1/contextEntities',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm13)

    perm14 = keystone.fiware_roles.permissions.create(
                name='contextEntities(GET)', 
                application=chanchan_app, 
                action= 'GET', 
                resource= 'v1/contextEntities',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm14)

    perm15 = keystone.fiware_roles.permissions.create(
                name='contextSubscriptions', 
                application=chanchan_app, 
                action= 'GET', 
                resource= 'v1/contextSubscriptions',
                is_internal=False)

    keystone.fiware_roles.permissions.add_to_role(
                    role_orion, perm15)