IDM_ROOT = './'
KEYSTONE_ROOT = IDM_ROOT + 'keystone/'
HORIZON_ROOT = IDM_ROOT + 'horizon/'
KEYSTONE_ADMIN_PORT = '35357'
KEYSTONE_DEFAULT_DOMAIN = 'default'
IDM_USER_CREDENTIALS = {
    'username': 'idm',
    'password': 'idm',
    'project': 'idm',
}
# For test_data
FIWARE_DEFAULT_APPS = {
    'Cloud' : ['Member'],
    'Mashup': [],
    'Store':[],
}
INTERNAL_PERMISSIONS = [
    'Manage the application',
    'Manage roles',
    'Get and assign all public application roles',
    'Manage Authorizations',
    'Get and assign only public owned roles',
    'Get and assign all internal application roles',
]
