var config = {};

config.pep_port = 1026;

// Set this var to undefined if you don't want the server to listen on HTTPS
// config.https = {
//    enabled: false,
//    cert_file: 'cert/cert.crt',
//    key_file: 'cert/key.key',
//    port: 443
//};

// Our IdM IP
config.account_host = 'idm';

// Our Keystone Settings. In this case Keystone and Horizon are at the same host
config.keystone_host = 'idm';
config.keystone_port = 5000;

// The host of the app to protect
config.app_host = 'orion';
config.app_port = '10026';

// The username and password we've used for registering the app (just for testing)
config.username = 'pepproxy@test.com';
config.password = 'test';

// in seconds
config.chache_time = 300;

// if enabled PEP checks permissions with AuthZForce GE.
// only compatible with oauth2 tokens engine
config.azf = {
    enabled: true,
    host: 'authzforce',
    port: 8080,
    path:
};

// options: oauth2/keystone
config.tokens_engine = 'oauth2';

config.magic_key = 'daf26216c5434a0a80f392ed9165b3b4';

module.exports = config;
